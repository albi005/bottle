import 'dart:math';

import 'package:bottle/services/bottle_service.dart';
import 'package:bottle/db/log_repository.dart';
import 'package:bottle/models/bottle_device.dart';
import 'package:bottle/state/bottle_controller.dart';

class LogService {
  final BottleService _bottleService;
  final LogRepository _repo;
  final BottleController _controller;

  LogService(this._bottleService, this._repo, this._controller);

  Future<void> syncAllLogTypes() async {
    _controller.logSyncPhase.value = LogSyncPhase.syncing;
    _controller.logSyncError.value = null;
    _controller.logTypesSynced.clear();

    final name = _controller.name;

    await _syncLogType(
      name: 'TOF Log',
      table: 'tof_logs',
      fetcher: (ts) => _bottleService.getTofLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertTofLogs(name, es),
      entryTs: (e) => e.timestamp.toInt(),
    );

    await _syncLogType(
      name: 'Activation Log',
      table: 'activation_logs',
      fetcher: (ts) => _bottleService.getActivationLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertActivationLogs(name, es),
      entryTs: (e) => e.timestamp.toInt(),
    );

    await _syncLogType(
      name: 'Fault Log',
      table: 'fault_logs',
      fetcher: (ts) => _bottleService.getFaultLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertFaultLogs(name, es),
      entryTs: (e) => e.timestamp.toInt(),
    );

    await _syncLogType(
      name: 'State Log',
      table: 'state_logs',
      fetcher: (ts) => _bottleService.getStateLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertStateLogs(name, es),
      entryTs: (e) => e.timestamp.toInt(),
    );

    await _syncLogType(
      name: 'Activation ADC Log',
      table: 'activation_adc_logs',
      fetcher: (ts) =>
          _bottleService.getActivationAdcLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertActivationAdcLogs(name, es),
      entryTs: (e) => e.timestamp.toInt(),
    );

    await _syncLogType(
      name: 'Charging ADC Log',
      table: 'charging_adc_logs',
      fetcher: (ts) =>
          _bottleService.getChargingAdcLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertChargingAdcLogs(name, es),
      entryTs: (e) => e.timestamp.toInt(),
    );

    _controller.logSyncPhase.value =
        _controller.logSyncError.value != null
            ? LogSyncPhase.error
            : LogSyncPhase.done;
  }

  Future<void> _syncLogType<T>({
    required String name,
    required String table,
    required Future<List<T>> Function(int) fetcher,
    required Future<int> Function(List<T>) inserter,
    required int Function(T) entryTs,
  }) async {
    int cursor = await _repo.getLatestTimestamp(table, _controller.name);
    print('[LGS] _syncLogType $name starting cursor=$cursor');

    while (true) {
      if (_controller.connectionPhase.value != ConnectionPhase.ready) {
        print('[LGS] _syncLogType $name disconnected');
        _controller.logSyncError.value = 'Disconnected during $name sync';
        return;
      }

      _controller.logSyncProgress.value = (name, cursor);

      List<T> entries;
      try {
        entries = await fetcher(cursor);
      } catch (e) {
        print('[LGS] _syncLogType $name error: $e');
        _controller.logSyncError.value = 'Sync $name: $e';
        return;
      }

      if (entries.isEmpty) {
        print('[LGS] _syncLogType $name empty, done');
        break;
      }

      await inserter(entries);
      print('[LGS] _syncLogType $name inserted ${entries.length} entries');

      cursor = entries.map(entryTs).reduce(max) + 1;
    }

    _controller.logTypesSynced.add(name);
  }
}
