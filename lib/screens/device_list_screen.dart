import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../utils/constants.dart';
import 'control_screen.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final BleService _bluetoothService = BleService();
  final List<BluetoothDevice> _devicesList = [];
  String _statusMessage = "Recherche du robot...";
  bool _isConnecting = false;
  bool _robotFound = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _devicesList.clear();
      _statusMessage = "Recherche du robot...";
      _robotFound = false;
    });
    _bluetoothService.startScan();
    _bluetoothService.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName.isNotEmpty &&
            !_devicesList.contains(r.device)) {
          setState(() {
            _devicesList.add(r.device);
          });

          // Auto-connect logic
          if (r.device.platformName == AppConstants.BOT_DEVICE_NAME &&
              !_isConnecting &&
              !_robotFound) {
            _robotFound = true;
            _bluetoothService.stopScan();
            _connectToDevice(r.device);
          }
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = "Connexion à ${device.platformName}...";
    });

    try {
      await _bluetoothService.connect(device);
      if (mounted) {
        setState(() {
          _statusMessage = "Connecté !";
        });
        // Small delay to show "Connected" message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ControlScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _statusMessage = "Erreur de connexion. Réessayez.";
        });
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
        title: const Text('Connexion Robot'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            _buildStatusIndicator(),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 48),
            if (!_isConnecting && !_robotFound)
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.refresh),
                label: const Text("Relancer la recherche"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            const Spacer(),
            const Divider(),
            Text(
              "Autres appareils détectés",
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: _devicesList.isEmpty
                  ? Center(
                      child: Text("Aucun appareil détecté",
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)))
                  : ListView.builder(
                      itemCount: _devicesList.length,
                      itemBuilder: (context, index) {
                        BluetoothDevice device = _devicesList[index];
                        return ListTile(
                          dense: true,
                          title: Text(device.platformName,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(device.remoteId.toString(),
                              style: const TextStyle(fontSize: 12)),
                          onTap: _isConnecting
                              ? null
                              : () => _connectToDevice(device),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_isConnecting) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(strokeWidth: 6),
      );
    } else if (_robotFound) {
      return Icon(Icons.check_circle_outline,
          size: 100, color: Theme.of(context).colorScheme.primary);
    } else {
      return SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(
          strokeWidth: 6,
          valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary),
        ),
      );
    }
  }
}
