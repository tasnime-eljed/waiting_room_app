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
  })  : _supabase = supabase,
        _geoService = geoService ?? GeolocationService(),
        _localDb = localDb ?? LocalQueueService();

  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => _clients;

  RealtimeChannel? _channel;

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
    if (_supabase == null) return;

    final unsynced = await _localDb.getUnsyncedClients();
    for (final client in unsynced) {
      try {
        final remote = Map<String, dynamic>.from(client)..remove('is_synced');
        await _supabase.from('clients').upsert(remote);
        await _localDb.markClientAsSynced(client['id'] as String);
      } catch (e) {
        debugPrint('Sync failed for ${client['id']}: $e');
      }
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
    _clients = [..._clients, newClient]
      ..sort((a, b) =>
          (a['created_at'] as String).compareTo(b['created_at'] as String));
    notifyListeners();

    unawaited(_syncLocalToRemote());
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
            // Enregistre le client reçu d'un autre appareil, déjà synchronisé
            await _localDb.insertClientLocally({
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
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}