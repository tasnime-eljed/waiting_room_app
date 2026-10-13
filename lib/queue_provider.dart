import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/models/client.dart';

class QueueProvider extends ChangeNotifier {
  final List<Client> _clients = [];
  List<Client> get clients => _clients;

  final SupabaseClient _supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;

  QueueProvider() {
    _setupRealtimeSubscription();
    _fetchInitialClients();
  }

  // 1) Charger la liste existante
  Future<void> _fetchInitialClients() async {
    try {
      final data = await _supabase
          .from('clients')
          .select()
          .order('created_at', ascending: true);

      _clients
        ..clear()
        ..addAll(data.map((row) => Client.fromMap(row)));
      notifyListeners();
    } catch (e) {
      print('Error fetching clients: $e');
    }
  }

  // 2) Écouter les changements en temps réel
  void _setupRealtimeSubscription() {
    _channel = _supabase
        .channel('public:clients')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            final newClient = Client.fromMap(payload.newRecord);
            // éviter un doublon si le client est déjà dans la liste
            if (_clients.any((c) => c.id == newClient.id)) return;
            _clients.add(newClient);
            _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            final deletedId = payload.oldRecord['id'];
            _clients.removeWhere((c) => c.id == deletedId);
            notifyListeners();
          },
        )
        .subscribe(); // une seule fois, à la fin
  }

  // 3) Actions
  Future<void> addClient(String name) async {
    if (name.trim().isEmpty) {
      print('Cannot add empty client name');
      return;
    }
    try {
      await _supabase.from('clients').insert({'name': name.trim()});
      print('Client added: $name');
    } catch (e) {
      print('Failed to add client: $e');
    }
  }

  Future<void> removeClient(String id) async {
    try {
      await _supabase.from('clients').delete().eq('id', id);
      print('Client removed: $id');
    } catch (e) {
      print('Failed to remove client: $e');
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) {
      print('Queue is empty!');
      return;
    }
    final firstClient = _clients.first;
    await removeClient(firstClient.id);
    print('Next client: ${firstClient.name}');
  }

  @override
  void dispose() {
    _supabase.removeChannel(_channel);
    super.dispose();
  }
}
