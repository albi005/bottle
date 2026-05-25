import 'package:signals/signals.dart';

import 'package:bottle/models/sensor_data.dart';
import 'package:bottle/services/bottle_service.dart';
import 'package:bottle/state/bottle_controller.dart';

class SensorService {
  final BottleService _bottleService;
  final BottleController _controller;

  SensorService(this._bottleService, this._controller);

  Future<void> refreshAllSensors() async {
    await _queryOne(
      _controller.uiState,
      () => _bottleService.getUiState(),
    );
    await _queryOne(
      _controller.tofDistance,
      () => _bottleService.getTofDistance(),
    );
    await _queryOne(
      _controller.sipCounter,
      () => _bottleService.getSipCounter(),
    );
    await _queryOne(
      _controller.hallEffect,
      () => _bottleService.getHallEffect(),
    );
    await _queryOne(
      _controller.bottlePresent,
      () => _bottleService.getBottlePresent(),
    );
    await _queryOne(
      _controller.ambientLight,
      () => _bottleService.getAmbientLight(),
    );
    await _queryOne(
      _controller.accelerometer,
      () => _bottleService.getAccelerometer(),
    );
    await _queryOne(
      _controller.batteryLevel,
      () => _bottleService.getBatteryLevel(),
    );
  }

  Future<void> _queryOne<T>(
    Signal<SensorValue<T>> target,
    Future<T> Function() fetch,
  ) async {
    final previous = target.peek();

    if (previous is SensorData<T>) {
      target.value = SensorData<T>(value: previous.value, refreshing: true);
    } else {
      target.value = SensorLoading<T>();
    }

    try {
      final result = await fetch();
      target.value = SensorData<T>(value: result);
    } catch (e) {
      if (previous is SensorData<T>) {
        target.value = SensorData<T>(value: previous.value, refreshing: false);
      } else if (previous is SensorError<T>) {
        target.value = previous;
      } else {
        target.value = SensorError<T>(message: e.toString());
      }
    }
  }
}
