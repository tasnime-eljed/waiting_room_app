import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/client.dart';

void main() {
  group('Client model', () {
    test('fromMap crée un Client avec les bonnes valeurs', () {
      final map = {
        'id': 'abc-123',
        'name': 'Alice',
        'created_at': '2026-10-13T10:00:00+00:00',
      };

      final client = Client.fromMap(map);

      expect(client.id, 'abc-123');
      expect(client.name, 'Alice');
      expect(client.createdAt, DateTime.parse('2026-10-13T10:00:00+00:00'));
    });

    test('toMap renvoie les bonnes clés et valeurs', () {
      final client = Client(
        id: 'abc-123',
        name: 'Alice',
        createdAt: DateTime.utc(2026, 10, 13, 10),
      );

      final map = client.toMap();

      expect(map['id'], 'abc-123');
      expect(map['name'], 'Alice');
      expect(map['created_at'], '2026-10-13T10:00:00.000Z');
    });

    test('toString contient le nom du client', () {
      final client = Client(
        id: '1',
        name: 'Bob',
        createdAt: DateTime.utc(2026, 10, 13),
      );

      expect(client.toString(), contains('Bob'));
    });
  });
}