import 'package:flutter_health_connect/flutter_health_connect.dart';

import 'package:bottle/db/log_repository.dart';
import 'package:bottle/state/bottle_controller.dart';

class HealthSyncService {
  static const _volumePerMm = 3.848;
  static const _triggerTypeSip = 4;

  final LogRepository _repo;
  final BottleController _controller;

  HealthSyncService(this._repo, this._controller);

  Future<bool> isAvailable() async {
    final ok = await HealthConnectFactory.isApiSupported();
    if (!ok) return false;
    return HealthConnectFactory.isAvailable();
  }

  Future<bool> hasPermissions() async {
    return HealthConnectFactory.hasPermissions(
      [HealthConnectDataType.Hydration],
    );
  }

  Future<bool> requestPermissions() async {
    return HealthConnectFactory.requestPermissions(
      [HealthConnectDataType.Hydration],
    );
  }

  Future<bool> openSettings() async {
    return HealthConnectFactory.openHealthConnectSettings();
  }

  Future<void> syncHydration({required String bottleName}) async {
    final lastTs = await _repo.getHealthSyncTimestamp(bottleName);
    final rows = await _repo.getTofLogsSince(bottleName, lastTs, limit: 30);

    if (rows.length < 2) {
      if (rows.isNotEmpty) {
        await _repo.setHealthSyncTimestamp(
            bottleName, rows.last['timestamp'] as int);
      }
      return;
    }

    final toSync = <HydrationRecord>[];
    int maxTs = lastTs;

    for (int i = 1; i < rows.length; i++) {
      final prev = rows[i - 1];
      final curr = rows[i];

      final prevTrigger = prev['trigger_type'] as int;
      final currTrigger = curr['trigger_type'] as int;

      if (currTrigger != _triggerTypeSip || prevTrigger != _triggerTypeSip) {
        maxTs = curr['timestamp'] as int;
        continue;
      }

      final prevDist = prev['distance_mm'] as int;
      final currDist = curr['distance_mm'] as int;
      final delta = prevDist - currDist;

      if (delta > 0) {
        final volumeMl = delta * _volumePerMm;
        final ts = curr['timestamp'] as int;
        toSync.add(HydrationRecord(
          startTime: DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
          endTime: DateTime.fromMillisecondsSinceEpoch(ts * 1000 + 5000, isUtc: true),
          volume: Volume.milliliters(volumeMl),
        ));
        maxTs = ts;
      } else {
        maxTs = curr['timestamp'] as int;
      }
    }

    if (toSync.isNotEmpty) {
      try {
        await HealthConnectFactory.writeData(
          type: HealthConnectDataType.Hydration,
          data: toSync,
        );
      } catch (e) {
        _controller.healthSyncError.value = 'Health Connect write failed: $e';
        return;
      }
    }

    await _repo.setHealthSyncTimestamp(bottleName, maxTs);
    _controller.healthSyncError.value = null;
  }
}
