import 'package:flutter_test/flutter_test.dart';

import 'package:waiting_room_app/queue_provider.dart';

void main() {
  test('should add a client to the waiting list', () {
    // ARRANGE
    final provider = QueueProvider();

    // ACT
    provider.addClient('John Doe');

    // ASSERT
    expect(provider.clients.length, 1);
    expect(provider.clients.first, 'John Doe');
  });

  test('should remove a client from the waiting list', () {
    // ARRANGE
    final provider = QueueProvider();
    provider.addClient('John Doe');
    provider.addClient('Jane Doe');

    // ACT
    provider.removeClient('John Doe');

    // ASSERT
    expect(provider.clients.length, 1);
    expect(provider.clients.first, 'Jane Doe');
  });

  test('should remove the first client when nextClient() is called', () {
  final provider = QueueProvider();

  provider.addClient('Client A');
  provider.addClient('Client B');

  provider.nextClient();

  expect(provider.clients.length, 1);
  expect(provider.clients.first, 'Client B');
});
}
