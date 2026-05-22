import 'package:flutter/material.dart';
import 'services/larq_ble_service.dart';
import 'screens/scan_screen.dart';

void main() {
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
      home: ScanScreen(bleService: bleService),
    );
  }
}
