// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'dart:convert';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';

///Liste des actions possibles pour le robot.
enum RobotActionType {
  Forward,
  Back,
  TurnLeft,
  TurnRight,
  Stop,
  MoveSequenceOne,
  MoveSequenceTwo,
  AvoidObstacleOne,
  AvoidObstacleTwo,
}

///Liste des types de télémétrie disponibles.
enum TelemetryType {
  Distance,
  LastActions,
  LastError,
}

/// Classe BLERobot qui gère la communication Bluetooth Low Energy (BLE) avec le robot.
class BLERobot {
  late BluetoothDevice? connectedDevice;
  late BluetoothCharacteristic? commandCharacteristic;
  final List<BluetoothDevice> devicesList = [];

  final String _name;

  // Changer ces valeurs pour les vôtres.
  static const String BOT_SERVICE = '15ff0fcd-6481-4565-9fe0-388628769cce';
  static const String BOT_CARACTERISTIQUE =
      '34a28b10-1486-4c61-9fa1-878296fd0262';

  /// Fonction de rappel, lorsque le robot est prêt à recevoir des commandes.
  void Function()? onRobotReady;

  bool get isConnected =>
      connectedDevice != null && connectedDevice!.isConnected;

  /// Constructeur de la classe BLERobot
  BLERobot(this._name) {
    devicesList.clear();
    connectedDevice = null;
    commandCharacteristic = null;
  }

  /// Découvre les services disponibles sur le robot.
  void startScan() {
    devicesList.clear();
    connectedDevice = null;
    commandCharacteristic = null;

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.advName != '' && !devicesList.contains(r.device)) {
          devicesList.add(r.device);

          // Si le nom du périphérique correspond à celui recherché, on arrête la recherche et on se connecte.
          if (r.device.advName == _name) {
            FlutterBluePlus.stopScan();
            _connectToDevice(r.device);
          }
        }
      }
    });
  }

  /// Démarre la découverte de périphériques BLE, afin de trouver le robot.
  void _connectToDevice(BluetoothDevice device) async {
    print("connexion à : ${device.advName} ( ${device.remoteId})");
    await device.connect(timeout: const Duration(seconds: 90));
    connectedDevice = device;
    _discoverServices();
  }

  void _discoverServices() async {
    if (connectedDevice == null) return;

    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString() == BOT_SERVICE) {
        print("service trouvé: ${service.uuid}");
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == BOT_CARACTERISTIQUE) {
            print("Characteristique trouvée: ${characteristic.uuid}");
            commandCharacteristic = characteristic;
            if (onRobotReady != null) {
              onRobotReady!();
            }
            print("Robot connecté et prêt à recevoir des commandes.");
            return;
          }
        }
      }
    }
  }

  /// Envoie une commande au robot.
  Future<void> sendCommand(RobotActionType action, [String value = '']) async {
    if (commandCharacteristic == null) return;

    String fullCommand = action.name;
    if (value != '') {
      fullCommand += ':$value';
    }
    List<int> bytes = utf8.encode(fullCommand);
    await commandCharacteristic!.write(bytes, withoutResponse: true);
  }
}
