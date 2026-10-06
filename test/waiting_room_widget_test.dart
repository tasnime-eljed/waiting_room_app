import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/main.dart';

void main() {
  testWidgets('should add a new client to the list on button tap', (
    WidgetTester tester,
  ) async {
    // ARRANGE
    await tester.pumpWidget(const WaitingRoomApp());//demarrre l'application pour le test et attend que le widget soit construit

    // ACT
    await tester.enterText(find.byType(TextField), 'Alice');// Simule la saisie de texte dans le champ de texte ,Trouve le widget de type TextField.
    await tester.tap(find.byType(ElevatedButton));// Simule un appui sur le bouton "Add"
    await tester.pump(); // Rebuild the widget after state change

    // ASSERT
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
  });

  testWidgets(
    'should remove a client from the list when the delete button is tapped',
    (WidgetTester tester) async {
      // ARRANGE
      await tester.pumpWidget(const WaitingRoomApp());
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
