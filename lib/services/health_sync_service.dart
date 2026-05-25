import 'package:bottle/db/log_repository.dart';
import 'package:bottle/services/health_connect.dart';
import 'package:bottle/state/bottle_controller.dart';

class HealthSyncService {
  // 4th-degree polynomial coefficients for PureVis 2 1000ml bottle.
  // Converts TOF distance (mm, cap-to-water-surface) to volume remaining (ml).
  // volume_mL = a4·d⁴ + a3·d³ + a2·d² + a1·d + a0
  // Sourced from LARQ app's hardcoded defaults (fb/f.java).
  static const double _a4 = -1.1e-6;
  static const double _a3 = 5.5211e-4;
  static const double _a2 = -0.08516349;
  static const double _a1 = -0.2839113;
  static const double _a0 = 1026.71212239;

  // Default thresholds from LARQ Firebase Remote Config:
  // cap_drink_threshold_in_milliliter  -> default 25.0 ml
  static const double _drinkThresholdMl = 25.0;
  static const double _maxDrinkMl = 500.0;

  final LogRepository _repo;
  final BottleController _controller;

  HealthSyncService(this._repo, this._controller);

  Future<bool> isAvailable() => HealthConnect.isAvailable();

  Future<bool> hasPermissions() => HealthConnect.hasPermissions();

  Future<bool> requestPermissions() => HealthConnect.requestPermissions();

  Future<bool> openSettings() => HealthConnect.openSettings();

  static double _distanceToVolume(int distanceMm) {
    final d = distanceMm.toDouble();
    return _a4 * d * d * d * d +
           _a3 * d * d * d +
           _a2 * d * d +
           _a1 * d +
           _a0;
  }

  Future<void> syncHydration({required String bottleName}) async {
    final lastTs = await _repo.getHealthSyncTimestamp(bottleName);
    final rows = await _repo.getTofLogsSince(bottleName, lastTs, limit: 2000);

    if (rows.length < 2) {
      if (rows.isNotEmpty) {
        await _repo.setHealthSyncTimestamp(
            bottleName, rows.last['timestamp'] as int);
      }
      return;
    }

    final records = <({
      DateTime startTime,
      DateTime endTime,
      double volumeMl,
    })>[];
    int maxTs = lastTs;

    for (int i = 1; i < rows.length; i++) {
      final prev = rows[i - 1];
      final curr = rows[i];

      final prevDist = prev['distance_mm'] as int;
      final currDist = curr['distance_mm'] as int;
      final ts = curr['timestamp'] as int;
      maxTs = ts;

      final prevVol = _distanceToVolume(prevDist);
      final currVol = _distanceToVolume(currDist);
      final volumeDelta = prevVol - currVol;

      if (volumeDelta >= _drinkThresholdMl && volumeDelta <= _maxDrinkMl) {
        records.add((
          startTime:
              DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
          endTime:
              DateTime.fromMillisecondsSinceEpoch(ts * 1000 + 5000, isUtc: true),
          volumeMl: volumeDelta,
        ));
      }
    }

    if (records.isNotEmpty) {
      try {
        await HealthConnect.writeHydration(records);
      } catch (e) {
        _controller.healthSyncError.value =
            'Health Connect write failed: $e';
        return;
      }
    }

    await _repo.setHealthSyncTimestamp(bottleName, maxTs);
    _controller.healthSyncError.value = null;
  }
}
