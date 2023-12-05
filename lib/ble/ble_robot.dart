import 'ble_manager.dart';
import 'ble_peripheral.dart';

///Liste des actions possibles pour le robot.
enum RobotActionType
{
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
enum TelemetryType
{
    Distance,
    LastActions,
    LastError,
}


/// Classe BLERobot qui gère la communication Bluetooth Low Energy (BLE) avec le robot.
class BLERobot {
  late BLEPeripheral _peripheral;
  late BLEManager _manager;
  final String _name;

  // Changer ces valeurs pour les vôtres.
  final String _commandsSrvUUID = '15ff0fcd-6481-4565-9fe0-388628769cce';
  final String _commandsCharUUID = '34a28b10-1486-4c61-9fa1-878296fd0262';

  
  /// Fonction de rappel, lorsque le robot est prêt à recevoir des commandes.
  void Function()? onRobotReady; 

  bool get isConnected => _peripheral.isConnected && _peripheral.isReady;

  /// Constructeur de la classe BLERobot
  BLERobot(this._name) {
    _manager = BLEManager();

    // Fonction de rappel, lorsqu'un périphérique est trouvé
    _manager.onPeripheralFound = (peripheral) async {
      print('Périphérique trouvé: $peripheral, state: ${peripheral.state.value}');
      _peripheral = peripheral;
      _peripheral.onPeripheralReady = () async {
        print('Robot connecté.');
        onRobotReady?.call();
      };
      await _manager.stopDiscovery();
      await _peripheral.connect();

      // On assigne le service et la caractéristique à utiliser.
      await _peripheral.setActiveCharacteristic(_commandsSrvUUID, _commandsCharUUID);

      // On écoute les changements de valeur de la caractéristique.
      _peripheral.characteristic.addListener(() {
        print('Characteristic changed: ${_peripheral.characteristic.value}');
      });  
    };
  }

  /// Démarre la découverte de périphériques BLE, afin de trouver le robot.
  Future<void> tryConnect() async {
    await _manager.startDiscovery(_name);
  }


  /// Envoie une commande au robot.
  Future<void> sendCommand(RobotActionType action, String value) async {    
    if(!isConnected) {
      print('Périphérique non connecté.');
      return;
    }
    if (value == "") {
      value = "0";
    }
    String cmd = '${action.index.toString()}:$value';
    await _peripheral.write(cmd);
  }

  /// Envoie une demande de lecture de télémétrie au robot.
  Future<String> readTelemetry(TelemetryType type) async {    
    if(!isConnected) {
      print('Périphérique non connecté.');
      return '';
    }
    return _peripheral.read(type.index.toString());
  }
}
