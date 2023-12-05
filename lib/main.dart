import 'dart:async';
import 'package:flutter/material.dart';
import 'pages/functions_page_widget.dart';
import 'ble/ble_manager.dart';

void main() {
  runZonedGuarded(onStartUp, onCrashed);
}
void onStartUp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BLEManager.initialize();
  runApp(const HomePageWidget());
}

void onCrashed(Object error, StackTrace stackTrace) {
  debugPrint(error.toString());
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exemple de connexion BLE',
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode:  ThemeMode.light,
      home: const FunctionsWidget(),
    );
  }
}
