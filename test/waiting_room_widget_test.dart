import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
  testWidgets('should add a new client to the list on button tap', (
    WidgetTester tester,
  ) async {
    // ARRANGE
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => QueueProvider(),
        child: const WaitingRoomApp(),
      ),
    );

    // ACT
    await tester.enterText(find.byType(TextField), 'Alice');

    await tester.tap(find.byType(ElevatedButton));

    await tester.pump();

    // ASSERT
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });

  testWidgets(
    'should remove a client from the list when the delete button is tapped',
    (WidgetTester tester) async {
      // ARRANGE
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => QueueProvider(),
          child: const WaitingRoomApp(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Bob');

      await tester.tap(find.byType(ElevatedButton));

      await tester.pump();

      // ACT
      await tester.tap(find.byIcon(Icons.delete));

      await tester.pump();

      // ASSERT
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Clients in Queue: 0'), findsOneWidget);
    },
  );
}
