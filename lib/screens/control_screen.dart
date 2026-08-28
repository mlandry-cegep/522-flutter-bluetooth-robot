import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../utils/constants.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final BleService _bluetoothService = BleService();

  @override
  void dispose() {
    // Déconnexion automatique en quittant l'écran ?
    // Pour l'instant on garde la connexion active, mais on pourrait ajouter un bouton déconnexion.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceName =
        _bluetoothService.connectedDevice?.platformName ?? 'Appareil Inconnu';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Contrôle du Robot',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(deviceName),
                const SizedBox(height: 16),
                _buildCameraPreview(),
                const SizedBox(height: 24),
                Expanded(child: _buildCommandGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String deviceName) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceName,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              StreamBuilder<String>(
                stream: _bluetoothService.statusStream,
                initialData: "En attente...",
                builder: (context, snapshot) {
                  return Text(
                    'Status: ${snapshot.data}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14),
                  );
                },
              ),
            ],
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Theme.of(context).colorScheme.primary,
                    blurRadius: 6,
                    spreadRadius: 1)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: StreamBuilder<Uint8List>(
          stream: _bluetoothService.cameraPreviewStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_off, color: Colors.white24, size: 48),
                    const SizedBox(height: 8),
                    Text("Pas de signal vidéo",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCommandGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildActionButton(
          "Tester\nDéplacements",
          Icons.gamepad,
          Theme.of(context).colorScheme.primary,
          AppConstants.CMD_TEST_MOVE,
        ),
        _buildActionButton(
          "Activer\nCaméra",
          Icons.videocam,
          Theme.of(context).colorScheme.secondary,
          AppConstants.CMD_ENABLE_CAMERA,
        ),
        _buildActionButton(
          "Activer\nIA",
          Icons.psychology,
          Theme.of(context).colorScheme.tertiary,
          AppConstants.CMD_ENABLE_AI,
        ),
        _buildActionButton(
          "Mode\nAutonome",
          Icons.rocket_launch,
          Theme.of(context).colorScheme.error,
          AppConstants.CMD_ENABLE_AUTONOMOUS,
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, String command) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _bluetoothService.sendCommand(command),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
