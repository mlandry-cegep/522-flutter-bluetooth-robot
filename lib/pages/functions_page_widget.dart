import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:projet_robot/ble/ble_robot.dart';
import 'dart:async';

class FunctionsWidget extends StatefulWidget {
  const FunctionsWidget({Key? key}) : super(key: key);

  @override
  _FunctionsWidgetState createState() => _FunctionsWidgetState();
}

class _FunctionsWidgetState extends State<FunctionsWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late BLERobot _robot;
  bool _connected = false;

 @override
  void initState() {
    super.initState();
    _robot = BLERobot('Rpi-NomDuRobot');
    _robot.onRobotReady = () {
      // Appel de la fonction de rappel (réaffichage), lorsque le robot est prêt
      setState(() {
        _connected = true;
      });
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> startDiscovery() async {
    await _robot.tryConnect();
    print("Scan Bluetooth en cours...");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          automaticallyImplyLeading: false,
          leading: Align(
            alignment: const AlignmentDirectional(0.00, 0.00),
            child: FaIcon(
              FontAwesomeIcons.robot,
              color: Theme.of(context).colorScheme.background,
              size: 32,
            ),
          ),
          title: Text(
            'Projet d\'intégration',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.background,
            )
          ),
          actions: [],
          centerTitle: false,
          elevation: 2,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.blueGrey),
                      foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    onPressed:  () async { await startDiscovery(); },
                    child: const Text('Scan Bluetooth'),
                  )
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                  child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                            ),
                            onPressed: () { 
                              // Vérification de la connexion avant de lancer la fonction
                              if (_connected) {
                                print("Fonction: Avancer 50cm");
                                _robot.sendCommand(RobotActionType.Forward, '50');
                              }
                              else {
                                print("Fonction: Avancer 50cm (non connecté)");
                              }
                            },
                            child: const Text('Avancer 50cm'),
                          ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 40),
                  child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                            ),
                            onPressed: () async { 
                              // Vérification de la connexion avant de lancer la fonction
                              if(_connected) {
                                print("Fonction: Arrêt d'urgence");
                                _robot.sendCommand(RobotActionType.Stop, '0');
                              }
                              else {
                                print("Fonction: Arrêt d'urgence (non connecté)");
                              }
                            },
                            child: const Text('Arrêt d\'urgence'),
                          ),
                ),
                const Divider(
                  thickness: 2,
                  indent: 60,
                  endIndent: 60,
                  color: Color(0xCC3A3A3A),
                ),                
              ],
            ),
          ),
        ),
      );
  }
}
