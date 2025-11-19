import 'package:flutter/material.dart';
import 'screens/device_list_screen.dart';

void main() {
  runApp(const BLECommanderApp());
}

class BLECommanderApp extends StatelessWidget {
  const BLECommanderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Commander',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DeviceListScreen(),
    );
  }
}
