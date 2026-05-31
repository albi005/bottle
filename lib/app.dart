import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'package:bottle/di/injection.dart';
import 'package:bottle/state/app_state.dart';
import 'package:bottle/services/ble_scanner.dart';
import 'package:bottle/ui/pages/home_page.dart';

class BottleApp extends StatefulWidget {
  const BottleApp({super.key});

  @override
  State<BottleApp> createState() => _BottleAppState();
}

class _BottleAppState extends State<BottleApp> {
  late final BleScanner _bleScanner;

  @override
  void initState() {
    super.initState();
    _bleScanner = getIt<BleScanner>();
    _startIfAdapterReady();
    FlutterBluePlus.adapterState.listen((state) {
      bluetoothAdapterState.value = state;
      if (state == BluetoothAdapterState.on) {
        _bleScanner.startScanning();
      } else {
        _bleScanner.stopScanning();
      }
    });
  }

  void _startIfAdapterReady() async {
    if (await FlutterBluePlus.isSupported) {
      _bleScanner.startScanning();
    }
  }

  static const _fallbackSeed = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'LARQ Bottles',
          theme: ThemeData(
            colorScheme:
                lightDynamic ?? ColorScheme.fromSeed(seedColor: _fallbackSeed),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme:
                darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: _fallbackSeed,
                  brightness: Brightness.dark,
                ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          home: const HomePage(),
        );
      },
    );
  }
}
