import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/queue_provider.dart';

/// Faux service de géolocalisation (remplace le mock généré).
class FakeGeolocationService extends GeolocationService {
  Position? positionToReturn;

  @override
  Future<Position?> getCurrentPosition() async => positionToReturn;
}

Position fakePosition() => Position(
  latitude: 37.7749,
  longitude: -122.4194,
  timestamp: DateTime.now(),
  accuracy: 5.0,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late FakeGeolocationService fakeGeo;
  late LocalQueueService localDb;
  late QueueProvider provider;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    fakeGeo = FakeGeolocationService();
    localDb = LocalQueueService(inMemory: true);
    // Pas de Supabase : la synchro distante est ignorée
    provider = QueueProvider(geoService: fakeGeo, localDb: localDb);
  });

  tearDown(() async {
    provider.dispose();
    await localDb.close(); // base propre pour le test suivant
  });

  test('addClient saves client with geolocation', () async {
    fakeGeo.positionToReturn = fakePosition();

    await provider.addClient('Test User');

    final client = provider.clients.last;
    expect(client['name'], 'Test User');
    expect(client['lat'], 37.7749);
    expect(client['lng'], -122.4194);
    expect(client['is_synced'], 0); // pas de Supabase => non synchronisé
  });

  test('addClient stores null location when position is unavailable', () async {
    fakeGeo.positionToReturn = null;

    await provider.addClient('No GPS');

    final client = provider.clients.last;
    expect(client['lat'], isNull);
    expect(client['lng'], isNull);
  });

  test('addClient persists the client in the local database', () async {
    fakeGeo.positionToReturn = fakePosition();

    await provider.addClient('Persisted');

    final stored = await localDb.getClients();
    expect(stored.length, 1);
    expect(stored.first['name'], 'Persisted');
  });

  test('initialize loads clients from the local database', () async {
    await localDb.insertClientLocally({
      'id': 'abc',
      'name': 'Already here',
      'lat': 1.0,
      'lng': 2.0,
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 1,
    });

    await provider.initialize();

    expect(provider.clients.length, 1);
    expect(provider.clients.first['name'], 'Already here');
  });

  test('deleteClient removes the client', () async {
    await provider.addClient('To delete');
    final id = provider.clients.first['id'] as String;

    await provider.deleteClient(id);

    expect(provider.clients, isEmpty);
  });

  test(
    'serveNext hides the first client but keeps it in the database',
    () async {
      await provider.addClient('First');

      await provider.serveNext();

      expect(provider.clients, isEmpty); // masqué à l'écran
      final unsynced = await localDb.getUnsyncedClients();
      expect(unsynced.length, 1); // toujours en base
    },
  );
}
