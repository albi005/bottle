import 'dart:async';

import 'package:bottle/models/bottle_device.dart';
import 'package:bottle/services/sensor_service.dart';
import 'package:bottle/services/log_service.dart';
import 'package:bottle/state/bottle_controller.dart';

class RefreshLoop {
  final SensorService _sensorService;
  final LogService _logService;
  final BottleController _controller;
  Timer? _timer;
  bool _running = false;

  RefreshLoop(this._sensorService, this._logService, this._controller);

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

      _controller.refreshPhase.value = RefreshPhase.idle;
      _controller.lastRefreshTime.value = DateTime.now();
    } catch (e, _) {
      _controller.refreshPhase.value = RefreshPhase.error;
      _controller.logSyncPhase.value = LogSyncPhase.idle;
      _controller.logSyncError.value = '$e';
    }

    if (_running &&
        _controller.connectionPhase.value == ConnectionPhase.ready) {
      _timer = Timer(const Duration(seconds: 10), _runCycle);
    }
  }
}
