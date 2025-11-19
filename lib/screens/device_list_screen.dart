import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import 'control_screen.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final BleService _bluetoothService = BleService();
  List<BluetoothDevice> _devicesList = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _devicesList.clear();
    });
    _bluetoothService.startScan();
    _bluetoothService.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.advName.isNotEmpty && !_devicesList.contains(r.device)) {
          setState(() {
            _devicesList.add(r.device);
          });
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothService.connect(device);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ControlScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appareils Bluetooth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _bluetoothService.stopScan();
              _startScan();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _startScan();
        },
        child: ListView.builder(
          itemCount: _devicesList.length,
          itemBuilder: (context, index) {
            BluetoothDevice device = _devicesList[index];
            return ListTile(
              title: Text(device.advName),
              subtitle: Text(device.remoteId.toString()),
              onTap: () => _connectToDevice(device),
            );
          },
        ),
      ),
    );
  }
}
