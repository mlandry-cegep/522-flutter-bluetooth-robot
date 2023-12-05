import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:bluetooth_low_energy_platform_interface/bluetooth_low_energy_platform_interface.dart';
import 'package:flutter/material.dart';


/// Classe BLEManager qui gère la communication Bluetooth Low Energy (BLE)
class BLEPeripheral {
  late CentralManager centralManager;
  late Peripheral peripheral;
  late bool _connected;
  late bool _ready;
  late final ValueNotifier<bool> state;
  late final DiscoveredEventArgs eventArgs;
  late final ValueNotifier<List<GattService>> services;
  late final ValueNotifier<List<GattCharacteristic>> characteristics;
  late final ValueNotifier<GattService?> service;
  late final ValueNotifier<GattCharacteristic?> characteristic;
  late final ValueNotifier<GattCharacteristicWriteType> writeType;
  late final ValueNotifier<int> maximumWriteLength;
  late final ValueNotifier<int> rssi;
  late final StreamSubscription stateChangedSubscription;
  late final StreamSubscription valueChangedSubscription;
  late final StreamSubscription rssiChangedSubscription;
  late final Timer rssiTimer;

  bool get isConnected => _connected;
  bool get isReady => _ready;

// Fonction de rappel, lorsqu'un périphérique est trouvé
  void Function()? onPeripheralReady; 

  /// Constructeur de la classe BLEPeripheral
  BLEPeripheral(CentralManager manager, Peripheral periph) {
    centralManager = manager;
    peripheral = periph;
    _connected = false;
    _ready = false;
    state = ValueNotifier(false);
    services = ValueNotifier([]);
    characteristics = ValueNotifier([]);
    service = ValueNotifier(null);
    characteristic = ValueNotifier(null);
    writeType = ValueNotifier(GattCharacteristicWriteType.withResponse);
    maximumWriteLength = ValueNotifier(0);
    rssi = ValueNotifier(-100);

    // Abonnement aux changements d'état du périphérique BLE
    stateChangedSubscription = centralManager.peripheralStateChanged.listen(
      (eventArgs) {
        if (eventArgs.peripheral != this.eventArgs.peripheral) {
          return;
        }
        final state = eventArgs.state;
        this.state.value = state;
        if (!state) {
          services.value = [];
          characteristics.value = [];
          service.value = null;
          characteristic.value = null;
          disconnect();
        }
      },
    );

    // Abonnement aux changements de valeur de la caractéristique
    valueChangedSubscription = centralManager.characteristicValueChanged.listen(
      (eventArgs) {
        final characteristic = this.characteristic.value;
        if (eventArgs.characteristic != characteristic) {
          return;
        }
      },
    );
    rssiTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        final state = this.state.value;
        if (state) {
          rssi.value = await centralManager.readRSSI(eventArgs.peripheral);
        } else {
          rssi.value = -100;
        }
      },
    );
  }

  /// Démarre la connexion au périphérique BLE
  Future<void> connect() async {
    await centralManager.connect(peripheral);
    services.value =
        await centralManager.discoverGATT(peripheral);    
    
    maximumWriteLength.value =
        await centralManager.getMaximumWriteLength(
      peripheral,
      type: writeType.value,
    );
    rssi.value = await centralManager.readRSSI(peripheral);
    _connected = true;
  }

  /// Valide si le service est contenu dans la liste des services du périphérique.
  bool isContainService(String srvUuid) {
    for (var srv in services.value) {
      if(srv.uuid.toString() == srvUuid) {
        return true;
      }
    }
    return false;
  }



  /// Défini le service et la caractéristique à utiliser.
  Future<void> setActiveCharacteristic(String srvUuid, String charUuid) async {
    print('  -> Recherche du service $srvUuid et de la caractéristique $charUuid');
    for (var srv in services.value) {
      if(srv.uuid.toString() == srvUuid) {
        service.value = srv;
        print('  -> Service trouvé: ${service.value?.uuid.toString()}');
        characteristic.value = null;
        if (service.value == null) {
          break;
        }
        characteristics.value = srv.characteristics;

        // Si on a trouvé le service, on cherche la caractéristique demandée
        for (var car in characteristics.value) {
          if (car.uuid.toString() == charUuid) {
            print('  -> Caractéristique trouvée: ${car.uuid.toString()}');
            characteristic.value = car;
            _ready = true;
            onPeripheralReady?.call();
            break;
          }
        }
        break;
      }
    } 
  }

  /// Déconnecte le périphérique BLE
  Future<void> disconnect() async {
    await centralManager.disconnect(peripheral);
    maximumWriteLength.value = 0;
    rssi.value = 0;
    _connected = false;
    _ready = false;
  }

  void dispose() {
    if(_connected) {
      disconnect();
    }

    rssiTimer.cancel();
    stateChangedSubscription.cancel();
    valueChangedSubscription.cancel();
    state.dispose();
    services.dispose();
    characteristics.dispose();
    service.dispose();
    characteristic.dispose();
    writeType.dispose();
    maximumWriteLength.dispose();
    rssi.dispose();
  }

  /// Envoie une demande de notification au périphérique.
  Future<void> notify(String text) async {
    final characteristic = this.characteristic.value;
    if (characteristic == null) throw ArgumentError.notNull('characteristic');

    final canNotify = characteristic.properties.contains(GattCharacteristicProperty.notify,);
    if (!canNotify) throw ArgumentError(canNotify, 'canNotify');
  
    await centralManager.notifyCharacteristic(characteristic, state: true,);
  }

  /// Envoie une demande de lecture au périphérique.
  Future<String> read(String text) async {
    final characteristic = this.characteristic.value;
    if (characteristic == null) throw ArgumentError.notNull('characteristic');

    final canRead = characteristic.properties.contains(GattCharacteristicProperty.read,);
    if (!canRead) throw ArgumentError(canRead, 'canRead');
    
    final value = await centralManager.readCharacteristic(characteristic);
    final result = utf8.decode(value);
    return result;
  }

  /// Envoie une demande d'écriture au périphérique.
  Future<void> write(String text) async {
    final characteristic = this.characteristic.value;
    if (characteristic == null) throw ArgumentError.notNull('characteristic');

    final canWrite = characteristic.properties.contains(GattCharacteristicProperty.write,);
    if (!canWrite) throw ArgumentError(canWrite, 'canWrite');
  
    final elements = utf8.encode(text);
    final value = Uint8List.fromList(elements);
    final type = writeType.value;
    await centralManager.writeCharacteristic(
      characteristic,
      value: value,
      type: type,
    );
  }
}