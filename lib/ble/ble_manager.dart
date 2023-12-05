import 'dart:async';
import 'package:bluetooth_low_energy_platform_interface/bluetooth_low_energy_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:projet_robot/ble/ble_peripheral.dart';

/// Classe BLEManager qui gère la communication Bluetooth Low Energy (BLE)
class BLEManager {
  late final ValueNotifier<BluetoothLowEnergyState> state; // Notifie les changements d'état du Bluetooth Low Energy
  late final ValueNotifier<bool> discovering; // Notifie l'état de la découverte des périphériques BLE
  late final StreamSubscription stateChangedSubscription; // Abonnement aux changements d'état du Bluetooth Low Energy
  late final StreamSubscription discoveredSubscription; // Abonnement à la découverte de périphériques BLE
  
  // Liste des noms des périphériques BLE découverts
  List<String> periphericals = []; 
  
  // Nom de l'appareil à rechercher
  late String advertisementName; 

  static CentralManager get centralManager => CentralManager.instance;
  static PeripheralManager get peripheralManager => PeripheralManager.instance;

// Fonction de rappel, lorsqu'un périphérique est trouvé
  void Function(BLEPeripheral)? onPeripheralFound; 

  /// Initialise le gestionnaire central et le gestionnaire périphérique BLE
  static Future<void> initialize() async {
    // Configuration des gestionnaires BLE
    await centralManager.setUp();
    await peripheralManager.setUp(); 
  }	

  /// Constructeur de la classe BLEManager
  BLEManager() {
    // Initialisation du notifieur d'état avec l'état actuel du Bluetooth Low Energy
    state = ValueNotifier(centralManager.state); 
    // Initialisation du notifieur de découverte à false
    discovering = ValueNotifier(false); 
    
    // Abonnement aux changements d'état du Bluetooth Low Energy
    stateChangedSubscription = centralManager.stateChanged.listen(
      (eventArgs) {
        // Mise à jour de l'état du Bluetooth Low Energy lorsqu'il change
        state.value = eventArgs.state; 
      },
    );
    
    // Abonnement à la découverte de périphériques BLE
    discoveredSubscription = centralManager.discovered.listen(
      (eventArgs) {
        if (eventArgs.advertisement.name != null && !periphericals.contains(eventArgs.advertisement.name)) {
          print('Discovered: ${eventArgs.advertisement.name} -> ${eventArgs.peripheral.uuid}');
          // Ajout du nom du périphérique à la liste des périphériques découverts
          periphericals.add(eventArgs.advertisement.name!); 
          
          if (eventArgs.advertisement.name == advertisementName) {
            // Création d'un objet BLEPeripheral avec le gestionnaire central et le périphérique découvert
            BLEPeripheral periph = BLEPeripheral(centralManager, eventArgs.peripheral); 

            // Appel de la fonction de rappel avec le périphérique BLE trouvé
            onPeripheralFound?.call(periph); 
          }

        }
      },
    );
  }

  /// Démarre la découverte des périphériques BLE
  Future<void> startDiscovery(String advertisementName) async {
    this.advertisementName = advertisementName; // Définition du nom de l'appareil à rechercher
    await centralManager.startDiscovery(); // Démarrage de la découverte des périphériques BLE
    discovering.value = true; // Mise à jour de l'état de la découverte à true
  }


  /// Arrête la découverte des périphériques BLE
  Future<void> stopDiscovery() async {
    await centralManager.stopDiscovery(); // Arrêt de la découverte des périphériques BLE
    discovering.value = false; // Mise à jour de l'état de la découverte à false
  }
} 

