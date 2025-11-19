import 'package:flutter/material.dart';
import '../services/ble_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final BleService _bluetoothService = BleService();

  // Contrôleurs pour les entrées utilisateur
  final _distanceController = TextEditingController();
  final _directionController = TextEditingController();
  final _degreeController = TextEditingController();
  final _challengeController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    _directionController.dispose();
    _degreeController.dispose();
    _challengeController.dispose();
    // Déconnexion automatique en quittant l'écran ?
    // Pour l'instant on garde la connexion active, mais on pourrait ajouter un bouton déconnexion.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceName =
        _bluetoothService.connectedDevice?.platformName ?? 'Appareil Inconnu';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrôle du Robot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () async {
              await _bluetoothService.disconnect();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Connecté à $deviceName',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildCommandButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandButtons() {
    return Column(
      children: [
        TextField(
          controller: _distanceController,
          decoration: const InputDecoration(labelText: 'Distance'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: () =>
              _bluetoothService.sendCommand('0', _distanceController.text),
          child: const Text('Avancer'),
        ),
        ElevatedButton(
          onPressed: () =>
              _bluetoothService.sendCommand('1', _distanceController.text),
          child: const Text('Reculer'),
        ),
        TextField(
          controller: _directionController,
          decoration:
              const InputDecoration(labelText: 'Direction (droite/gauche)'),
        ),
        TextField(
          controller: _degreeController,
          decoration: const InputDecoration(labelText: 'Nombre de degrés'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: () => _bluetoothService.sendCommand('Tourner',
              '${_directionController.text} ${_degreeController.text}'),
          child: const Text('Tourner'),
        ),
        ElevatedButton(
          onPressed: () => _bluetoothService.sendCommand('Arrêter'),
          child: const Text('Arrêter'),
        ),
        TextField(
          controller: _challengeController,
          decoration: const InputDecoration(labelText: 'Numéro du défi (1-5)'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: () => _bluetoothService.sendCommand(
              'Exécuter le défi', _challengeController.text),
          child: const Text('Exécuter le défi'),
        ),
      ],
    );
  }
}
