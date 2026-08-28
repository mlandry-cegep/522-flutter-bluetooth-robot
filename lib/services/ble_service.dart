import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
  BluetoothCharacteristic? _statusCharacteristic;
  BluetoothCharacteristic? _cameraCharacteristic;

  // Stream for scan results
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // Stream for connection state
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;

  // Stream for status updates
  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  // Stream for camera preview
  final _cameraPreviewController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get cameraPreviewStream => _cameraPreviewController.stream;

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
        _statusCharacteristic = null;
        _cameraCharacteristic = null;
        _statusController.add("Déconnecté");
      }
    });

    await _discoverServices(device);
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _commandCharacteristic = null;
      _statusCharacteristic = null;
      _cameraCharacteristic = null;
      _statusController.add("Déconnecté");
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
          } else if (characteristic.uuid.toString() ==
              AppConstants.BOT_CARACTERISTIQUE_STATUS) {
            _statusCharacteristic = characteristic;
            await _statusCharacteristic!.setNotifyValue(true);
            _statusCharacteristic!.lastValueStream.listen(_onStatusChanged);
          } else if (characteristic.uuid.toString() ==
              AppConstants.BOT_CARACTERISTIQUE_CAMERA_PREVIEW) {
            _cameraCharacteristic = characteristic;
            await _cameraCharacteristic!.setNotifyValue(true);
            _cameraCharacteristic!.lastValueStream
                .listen(_onCameraPreviewChanged);
          }
        }
      }
    }
  }

  void _onStatusChanged(List<int> value) {
    String status = utf8.decode(value);
    _statusController.add(status);
  }

  void _onCameraPreviewChanged(List<int> value) {
    _cameraPreviewController.add(Uint8List.fromList(value));
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
