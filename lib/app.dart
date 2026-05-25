import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:bottle/state/app_state.dart';
import 'package:bottle/services/ble_scanner.dart';
import 'package:bottle/ui/pages/home_page.dart';

final bleScanner = BleScanner();

class BottleApp extends StatefulWidget {
  const BottleApp({super.key});

  @override
  State<BottleApp> createState() => _BottleAppState();
}

class _BottleAppState extends State<BottleApp> {
  @override
  void initState() {
    super.initState();
    _startIfAdapterReady();
    FlutterBluePlus.adapterState.listen((state) {
      bluetoothAdapterState.value = state;
      if (state == BluetoothAdapterState.on) {
        bleScanner.startScanning();
      } else {
        bleScanner.stopScanning();
      }
    });
  }

  void _startIfAdapterReady() async {
    if (await FlutterBluePlus.isSupported) {
      bleScanner.startScanning();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LARQ Bottles',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
