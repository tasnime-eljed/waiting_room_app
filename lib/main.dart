import 'package:flutter/material.dart';
import 'package:waiting_room_app/waiting_room_card.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waiting Room',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('waiting Room'),
        ),
        body: const Center(
          child: WaitingRoomCard(name: 'tasnime eljed'),
        ),
      ),
    );
  }
}