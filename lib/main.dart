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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: ThemeMode.dark,
      home: const DeviceListScreen(),
    );
  }
}
