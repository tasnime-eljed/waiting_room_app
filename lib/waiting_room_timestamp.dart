import 'dart:async';
import 'package:flutter/material.dart';

class WaitingRoomTimestamp extends StatefulWidget {
  const WaitingRoomTimestamp({super.key});

  @override
  State<WaitingRoomTimestamp> createState() =>
      _WaitingRoomTimestampState();
}

class _WaitingRoomTimestampState extends State<WaitingRoomTimestamp> {
  late DateTime _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _currentTime = DateTime.now();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        setState(() {
          _currentTime = DateTime.now();
        });
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        '${_currentTime.hour.toString().padLeft(2, '0')}:'
        '${_currentTime.minute.toString().padLeft(2, '0')}:'
        '${_currentTime.second.toString().padLeft(2, '0')}';

    return Text(
      'Current Time: $formattedTime',
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black54,
      ),
    );
  }
}