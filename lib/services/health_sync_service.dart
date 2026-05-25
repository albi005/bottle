import 'package:bottle/db/log_repository.dart';
import 'package:bottle/services/health_connect.dart';
import 'package:bottle/state/bottle_controller.dart';

class HealthSyncService {
  static const _volumePerMm = 3.848;
  static const _drinkThresholdMm = 2;

  final LogRepository _repo;
  final BottleController _controller;

  HealthSyncService(this._repo, this._controller);

  Future<bool> isAvailable() => HealthConnect.isAvailable();

  Future<bool> hasPermissions() => HealthConnect.hasPermissions();

  Future<bool> requestPermissions() => HealthConnect.requestPermissions();

  Future<bool> openSettings() => HealthConnect.openSettings();

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
      final delta = prevDist - currDist;
      final ts = curr['timestamp'] as int;
      maxTs = ts;

      if (delta >= _drinkThresholdMm) {
        final volumeMl = delta * _volumePerMm;
        records.add((
          startTime:
              DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
          endTime:
              DateTime.fromMillisecondsSinceEpoch(ts * 1000 + 5000, isUtc: true),
          volumeMl: volumeMl,
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
