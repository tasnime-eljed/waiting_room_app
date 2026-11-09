import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'geolocation_service.dart';
import 'local_queue_service.dart';

class QueueProvider extends ChangeNotifier {
  final SupabaseClient? _supabase;
  final LocalQueueService _localDb;
  final GeolocationService _geoService;

  QueueProvider({
    SupabaseClient? supabase,
    GeolocationService? geoService,
    LocalQueueService? localDb,
  }) : _supabase = supabase,
       _geoService = geoService ?? GeolocationService(),
       _localDb = localDb ?? LocalQueueService();

  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => _clients;

  RealtimeChannel? _channel;
  bool _syncing = false;

  Future<void> initialize() async {
    // 1. Affichage immédiat depuis la base locale
    _clients = await _localDb.getClients();
    notifyListeners();

    // 2. Envoi des clients non synchronisés
    await _syncLocalToRemote();

    // 3. Temps réel
    _setupRealtimeSubscription();
  }

  Future<void> _syncLocalToRemote() async {
    final supabase = _supabase;
    if (supabase == null || _syncing) return;
    _syncing = true;

    try {
      final unsynced = await _localDb.getUnsyncedClients();
      for (final client in unsynced) {
        try {
          // Ces colonnes n'existent pas dans Supabase
          final remote = Map<String, dynamic>.from(client)
            ..remove('is_synced')
            ..remove('is_hidden');
          await supabase.from('clients').upsert(remote);
          await _localDb.markClientAsSynced(client['id'] as String);
        } catch (e) {
          debugPrint('Sync failed for ${client['id']}: $e');
        }
      }
    } finally {
      _syncing = false;
    }

    _clients = await _localDb.getClients();
    notifyListeners();
  }

  Future<void> addClient(String name) async {
    final position = await _geoService.getCurrentPosition();

    final newClient = {
      'id': const Uuid().v4(),
      'name': name,
      'lat': position?.latitude,
      'lng': position?.longitude,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'is_synced': 0,
    };

    await _localDb.insertClientLocally(newClient);
    _clients = await _localDb.getClients();
    notifyListeners();

    unawaited(_syncLocalToRemote());
  }

  /// ⏭️ Passe au suivant : masque le premier client de l'écran.
  /// Il reste dans SQLite et dans Supabase.
  Future<void> serveNext() async {
    if (_clients.isEmpty) return;
    final id = _clients.first['id'] as String;

    await _localDb.hideClient(id);
    _clients = await _localDb.getClients();
    notifyListeners();
  }

  /// 🗑️ Supprime le client de la base locale ET de Supabase.
  Future<void> deleteClient(String id) async {
    await _localDb.deleteClient(id);
    _clients = await _localDb.getClients();
    notifyListeners();

    try {
      await _supabase?.from('clients').delete().eq('id', id);
    } catch (e) {
      debugPrint('Remote delete failed: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final supabase = _supabase;
    if (supabase == null) return;

    _channel = supabase
        .channel('public:clients')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'clients',
          callback: (payload) async {
            final record = payload.newRecord;
            // insertIfAbsent : ne réactive pas un client masqué
            await _localDb.insertIfAbsent({
              'id': record['id'],
              'name': record['name'],
              'lat': record['lat'],
              'lng': record['lng'],
              'created_at': record['created_at'],
              'is_synced': 1,
            });
            _clients = await _localDb.getClients();
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'clients',
          callback: (payload) async {
            final id = payload.oldRecord['id'];
            if (id == null) return;
            await _localDb.deleteClient(id as String);
            _clients = await _localDb.getClients();
            notifyListeners();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
