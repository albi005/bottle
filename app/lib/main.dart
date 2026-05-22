import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/larq_ble_service.dart';
import 'screens/home_screen.dart';

Future<void> _requestBlePermissions() async {
  if (!Platform.isAndroid) return;
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();
  print('[APP] bluetoothScan=${await Permission.bluetoothScan.status} '
      'bluetoothConnect=${await Permission.bluetoothConnect.status} '
      'location=${await Permission.locationWhenInUse.status}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestBlePermissions();
  final bleService = LarqBleService();
  runApp(LarqBridgeApp(bleService: bleService));
}

class LarqBridgeApp extends StatelessWidget {
  final LarqBleService bleService;

  const LarqBridgeApp({super.key, required this.bleService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LARQ Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(bleService: bleService),
    );
  }
}
