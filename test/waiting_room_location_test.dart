import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/queue_provider.dart';

/// Faux provider : renvoie une liste fixe, sans SQLite ni Supabase.
class FakeQueueProvider extends QueueProvider {
  FakeQueueProvider(this._fakeClients);

  final List<Map<String, dynamic>> _fakeClients;

  @override
  List<Map<String, dynamic>> get clients => _fakeClients;
}

Future<void> pumpScreen(
  WidgetTester tester,
  List<Map<String, dynamic>> clients,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<QueueProvider>.value(
      value: FakeQueueProvider(clients),
      child: const MaterialApp(home: WaitingRoomScreen()),
    ),
  );
}

void main() {
  testWidgets('Displays location when available', (tester) async {
    await pumpScreen(tester, [
      {
        'id': '1',
        'name': 'Sam',
        'lat': 51.5074,
        'lng': -0.1278,
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 1,
      },
    ]);

    expect(find.text('Sam'), findsOneWidget);
    expect(find.textContaining('51.5074'), findsOneWidget);
    expect(find.textContaining('-0.1278'), findsOneWidget);
  });

  testWidgets('Displays "Location not captured" when lat is null', (
    tester,
  ) async {
    await pumpScreen(tester, [
      {
        'id': '2',
        'name': 'Alex',
        'lat': null,
        'lng': null,
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
    ]);

    expect(find.text('Alex'), findsOneWidget);
    expect(find.textContaining('Location not captured'), findsOneWidget);
  });

  testWidgets('Shows orange cloud when not synced and green when synced', (
    tester,
  ) async {
    await pumpScreen(tester, [
      {
        'id': '3',
        'name': 'Offline',
        'lat': null,
        'lng': null,
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      {
        'id': '4',
        'name': 'Online',
        'lat': null,
        'lng': null,
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 1,
      },
    ]);

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
  });
}
