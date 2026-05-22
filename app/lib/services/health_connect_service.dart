// Health Connect integration for syncing LARQ PureVis 2 hydration data.
// Uses the `health` package to write hydration records.
// Gracefully degrades on platforms without Health Connect support (e.g. Linux).

import 'dart:collection';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import '../models/larq_protocol.dart';

class HealthConnectService {
  Health? _health;
  bool _authorized = false;
  bool _isSupported = true;

  bool get isAuthorized => _authorized;
  bool get isSupported => _isSupported;

  HealthConnectService() {
    try {
      _health = Health();
    } on MissingPluginException {
      _isSupported = false;
    }
  }

  // LARQ PureVis 2 inner diameter is ~70mm, giving cross-sectional area:
  // π × (35mm)² ≈ 3848 mm²
  // 1 mm water level drop = 3848 mm³ = 3.848 ml
  static const double _bottleCrossSectionMm2 = 3848.0;
  static const double _mm3toMl = 1.0 / 1000.0;

  // Track synced log timestamps to avoid duplicates
  final _syncedTimestamps = HashSet<int>();

  /// Estimate drinking volume from consecutive ToF readings.
  ///
  /// The ToF sensor measures distance from cap to water surface in mm.
  /// When water is consumed, the distance increases. We compute the volume
  /// change using the bottle's cylindrical cross-sectional area.
  double _estimateVolumeFromLogs(List<CapTofLog> logs) {
    if (logs.length < 2) return 0;

    // Sort logs by timestamp to find consecutive drink events
    final sorted = List<CapTofLog>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double totalMl = 0;

    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];

      // Sip detected: distance increased (water level dropped)
      if (curr.triggerType == CapEnumTofTriggerType.capOnFlapOpenSip &&
          prev.triggerType != CapEnumTofTriggerType.request &&
          prev.distanceInMillimeter > 0 &&
          curr.timestamp - prev.timestamp < 30) {
        // Water level dropped = distance increased
        final deltaMm =
            max(curr.distanceInMillimeter - prev.distanceInMillimeter, 0);
        // Sanity check: a reasonable sip is 10-100ml (3-26mm drop)
        if (deltaMm > 0 && deltaMm < 50) {
          totalMl += deltaMm * _bottleCrossSectionMm2 * _mm3toMl;
        }
      }
    }

    return totalMl;
  }

  /// Authorize Health Connect permissions
  Future<bool> authorize() async {
    if (!_isSupported || _health == null) return false;
    try {
      final types = [
        HealthDataType.WATER,
      ];

      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.WRITE,
      ];

      _authorized = await _health!.requestAuthorization(
        types,
        permissions: permissions,
      );
      return _authorized;
    } catch (e) {
      _authorized = false;
      return false;
    }
  }

  /// Sync ToF logs to Health Connect as hydration records.
  /// Uses ToF distance changes to compute actual drinking volume.
  Future<int> syncTofLogsToHealthConnect(List<CapTofLog> logs) async {
    if (!_authorized) {
      final ok = await authorize();
      if (!ok) return 0;
    }

    final volumeMl = _estimateVolumeFromLogs(logs);
    if (volumeMl <= 0) return 0;

    // Check if we've already synced these timestamps
    final sorted = List<CapTofLog>.from(logs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final hash = sorted.map((e) => e.timestamp).join().hashCode;
    if (_syncedTimestamps.contains(hash)) return 0;

    // Use the latest log's timestamp as the event time
    final lastDt = sorted.isNotEmpty
        ? sorted.last.dateTime
        : DateTime.now();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    if (lastDt.isBefore(startOfDay)) return 0;

    try {
      final success = await _health!.writeHealthData(
        startTime: lastDt.subtract(const Duration(minutes: 1)),
        endTime: lastDt,
        value: volumeMl,
        type: HealthDataType.WATER,
        unit: HealthDataUnit.MILLILITER,
      );

      if (success) {
        _syncedTimestamps.add(hash);
        return 1;
      }
    } catch (_) {}

    return 0;
  }

  /// Get today's water intake from Health Connect
  Future<double> getTodayWaterIntake() async {
    if (!_authorized || !_isSupported || _health == null) return 0;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final result = await _health!.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: startOfDay,
        endTime: now,
      );

      double total = 0;
      for (final p in result) {
        final numValue = p.value as NumericHealthValue;
        final value = numValue.numericValue;
        if (value > 0) {
          total += switch (p.unit) {
            HealthDataUnit.MILLILITER => value,
            HealthDataUnit.LITER => value * 1000,
            _ => value,
          };
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  void resetSynced() {
    _syncedTimestamps.clear();
  }
}
