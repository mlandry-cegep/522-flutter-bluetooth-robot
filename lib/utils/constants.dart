/// Constantes de l'application pour la configuration Bluetooth.
class AppConstants {
  /// UUID du service Bluetooth du robot.
  /// Doit correspondre à la valeur configurée sur votre robot.
  static const String BOT_SERVICE_UUID = '15ff0fcd-6481-4565-9fe0-388628769cce';

  /// UUID de la caractéristique Bluetooth pour envoyer des commandes.
  /// Doit correspondre à la valeur configurée sur votre robot.
  static const String BOT_CHARACTERISTIC_UUID =
      '34a28b10-1486-4c61-9fa1-878296fd0262';
}
