import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/constants.dart';

class BleService {
  static final BleService _instance = BleService._internal();

  factory BleService() {
    return _instance;
  }

  BleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;

  // Stream for scan results
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // Stream for connection state
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    await device.connect(
        timeout: const Duration(seconds: 10), license: License.free);
    _connectedDevice = device;

    device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        _commandCharacteristic = null;
      }
    });

    await _discoverServices(device);
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _commandCharacteristic = null;
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == AppConstants.BOT_SERVICE_UUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() ==
              AppConstants.BOT_CHARACTERISTIC_UUID) {
            _commandCharacteristic = characteristic;
            print("Characteristic found: ${characteristic.uuid}");
          }
        }
      }
    }
  }

  Future<void> sendCommand(String command, [dynamic parameter]) async {
    if (_commandCharacteristic == null) {
      print("Command characteristic not found");
      return;
    }

    String fullCommand = command;
    if (parameter != null) {
      fullCommand += ':$parameter';
    }
    List<int> bytes = utf8.encode(fullCommand);
    await _commandCharacteristic!.write(bytes, withoutResponse: true);
  }
}
