import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:signals/signals.dart';

import 'package:bottle/models/sensor_data.dart';
import 'package:bottle/models/bottle_device.dart';
import 'package:bottle/services/bottle_connection.dart';
import 'package:bottle/services/bottle_service.dart';
import 'package:bottle/services/sensor_service.dart';
import 'package:bottle/services/log_service.dart';
import 'package:bottle/services/health_sync_service.dart';
import 'package:bottle/services/refresh_loop.dart';
import 'package:bottle/db/log_repository.dart';

class BottleController {
  final String name;
  final String remoteId;

  final connectionPhase = signal<ConnectionPhase>(ConnectionPhase.notFound);
  final connectionError = signal<String?>(null);
  final rssi = signal<int?>(null);
  final scanResult = signal<ScanResult?>(null);

  final uiState = signal<SensorValue<CapUiStateData>>(const SensorNotQueried());
  final tofDistance = signal<SensorValue<int>>(const SensorNotQueried());
  final sipCounter = signal<SensorValue<int>>(const SensorNotQueried());
  final hallEffect = signal<SensorValue<HallEffectData>>(const SensorNotQueried());
  final bottlePresent = signal<SensorValue<bool>>(const SensorNotQueried());
  final ambientLight = signal<SensorValue<double>>(const SensorNotQueried());
  final accelerometer = signal<SensorValue<AccelData>>(const SensorNotQueried());
  final batteryLevel = signal<SensorValue<int>>(const SensorNotQueried());
  final deviceInfo = signal<SensorValue<DeviceInfo>>(const SensorNotQueried());

  final logSyncPhase = signal<LogSyncPhase>(LogSyncPhase.idle);
  final logSyncProgress = signal<(String, int)>(('', 0));
  final logTypesSynced = setSignal<String>({});
  final logSyncError = signal<String?>(null);

  final healthSyncError = signal<String?>(null);
  final healthPermissionsGranted = signal<bool?>(null);
  final healthAvailable = signal<bool?>(null);

  final refreshPhase = signal<RefreshPhase>(RefreshPhase.idle);
  final lastRefreshTime = signal<DateTime?>(null);

  BottleConnection? _connection;
  SensorService? _sensorService;
  LogService? _logService;
  HealthSyncService? _healthSyncService;
  RefreshLoop? _refreshLoop;
  bool _connecting = false;

  BottleController({required this.name, required this.remoteId});

  void updateScan(ScanResult result) {
    scanResult.value = result;
    rssi.value = result.rssi;
    if (connectionPhase.value == ConnectionPhase.notFound) {
      connectionPhase.value = ConnectionPhase.visible;
    }
  }

  Future<void> connect(ScanResult result) async {
    if (_connecting) return;
    if (connectionPhase.value == ConnectionPhase.connecting ||
        connectionPhase.value == ConnectionPhase.discovering ||
        connectionPhase.value == ConnectionPhase.ready) {
      return;
    }
    _connecting = true;
    updateScan(result);
    connectionPhase.value = ConnectionPhase.connecting;
    connectionError.value = null;

    try {
      final connection = BottleConnection();
      _connection = connection;
      await connection.connect(result.device);

      connectionPhase.value = ConnectionPhase.discovering;
      await connection.discoverServices();

      final logRepo = await LogRepository.instance;
      final bottleService = BottleService(connection);
      _sensorService = SensorService(bottleService, this);
      _logService = LogService(bottleService, logRepo, this);
      _healthSyncService = HealthSyncService(logRepo, this);

      await connection.subscribeToRx(bottleService.onResponse);

      connectionPhase.value = ConnectionPhase.ready;

      _refreshLoop = RefreshLoop(
          _sensorService!, _logService!, _healthSyncService, this)
        ..start();
    } catch (e) {
      connectionPhase.value = ConnectionPhase.failed;
      connectionError.value = e.toString();
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    _refreshLoop?.stop();
    await _connection?.disconnect();
    connectionPhase.value = ConnectionPhase.notFound;
    rssi.value = null;
  }

  void onDisconnected() {
    _refreshLoop?.stop();
    connectionPhase.value = ConnectionPhase.notFound;
    rssi.value = null;
  }

  Future<void> openHealthSettings() async {
    await _healthSyncService?.requestPermissions();
  }
}
