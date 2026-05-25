import 'dart:async';
import 'package:flutter/services.dart';

class HealthConnect {
  static const _channel = MethodChannel('bottle/health_connect');

  static Future<bool> isAvailable() async {
    return _channel.invokeMethod<bool>('isAvailable').then((v) => v ?? false);
  }

  static Future<bool> hasPermissions() async {
    return _channel.invokeMethod<bool>('hasPermissions').then((v) => v ?? false);
  }

  static Future<bool> requestPermissions() async {
    return _channel
        .invokeMethod<bool>('requestPermissions')
        .then((v) => v ?? false);
  }

  static Future<bool> openSettings() async {
    return _channel.invokeMethod<bool>('openSettings').then((v) => v ?? false);
  }

  static Future<void> writeHydration(
      List<({DateTime startTime, DateTime endTime, double volumeMl})>
          records) async {
    await _channel.invokeMethod('writeHydration', {
      'records': records
          .map((r) => {
                'startTime': r.startTime.toUtc().toIso8601String(),
                'endTime': r.endTime.toUtc().toIso8601String(),
                'volumeMl': r.volumeMl,
              })
          .toList(),
    });
  }
}
