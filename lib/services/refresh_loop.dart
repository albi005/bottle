import 'dart:async';

import 'package:bottle/models/bottle_device.dart';
import 'package:bottle/services/sensor_service.dart';
import 'package:bottle/services/log_service.dart';
import 'package:bottle/services/health_sync_service.dart';
import 'package:bottle/state/bottle_controller.dart';

class RefreshLoop {
  final SensorService _sensorService;
  final LogService _logService;
  final HealthSyncService? _healthSyncService;
  final BottleController _controller;
  Timer? _timer;
  bool _running = false;

  RefreshLoop(
    this._sensorService,
    this._logService,
    this._healthSyncService,
    this._controller,
  );

  void start() {
    if (_running) return;
    _running = true;
    _runCycle();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _runCycle() async {
    if (!_running) return;
    if (_controller.connectionPhase.value != ConnectionPhase.ready) return;

    try {
      _controller.logSyncPhase.value = LogSyncPhase.idle;
      _controller.refreshPhase.value = RefreshPhase.refreshingSensors;
      await _sensorService.refreshAllSensors();

      _controller.refreshPhase.value = RefreshPhase.syncingLogs;
      await _logService.syncAllLogTypes();

      if (_healthSyncService != null) {
        final hss = _healthSyncService;
        _controller.healthSyncError.value = null;
        final available = await hss.isAvailable();
        _controller.healthAvailable.value = available;
        if (available) {
          final hasPerms = await hss.hasPermissions();
          _controller.healthPermissionsGranted.value = hasPerms;
          if (hasPerms) {
            await hss.syncHydration(bottleName: _controller.name);
          }
        }
      }

      _controller.refreshPhase.value = RefreshPhase.idle;
      _controller.lastRefreshTime.value = DateTime.now();
    } catch (e, _) {
      _controller.refreshPhase.value = RefreshPhase.error;
      _controller.logSyncPhase.value = LogSyncPhase.error;
      _controller.logSyncError.value = '$e';
    }

    if (_running &&
        _controller.connectionPhase.value == ConnectionPhase.ready) {
      _timer = Timer(const Duration(seconds: 10), _runCycle);
    }
  }
}
