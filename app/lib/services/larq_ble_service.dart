// LARQ PureVis 2 BLE Communication Manager
// Coordinates scanning, session lifecycle, and startup recovery.

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bottle_session.dart';
import 'package:signals/signals.dart';

class Bottle {
  Signal<BluetoothDevice> device;

  Bottle(BluetoothDevice d) : device = signal(d) {
    _start();
  }

  Future<void> _start() async {
    try {
      await device.value.connect();
      device.set(device.value, force: true);
    } catch (e) {
      print(e);
    }
  }
}

class LarqBleService {
  final Map<String, BottleSession> _sessions = {};

  List<String> get connectedIds => _sessions.entries
      .where((e) => e.value.isConnected)
      .map((e) => e.key)
      .toList();

  BottleSession? getSession(String remoteId) => _sessions[remoteId];

  Iterable<BottleSession> get sessions => _sessions.values;

  final MapSignal<String, Bottle> _bottles = MapSignal({});

  /// Scan for LARQ bottle devices.
  Stream<List<ScanResult>> scanForDevices({
    Duration timeout = const Duration(seconds: 15),
  }) {
    final seenIds = <String>{};
    final results = <ScanResult>[];
    final scanController = StreamController<List<ScanResult>>.broadcast();

    FlutterBluePlus.startScan();

    bool filter(ScanResult scanResult) {
      return scanResult.device.platformName.startsWith('LARQ_');
    }

    bool filterDev(BluetoothDevice dev) {
      return dev.platformName.startsWith('LARQ_');
    }

    final sub = FlutterBluePlus.scanResults.listen((r) {
      print(r);
      print(
        '>>>>>>>>>>>>>>>>>>> ${r.where(filter).map((x) {
          return '${x.device.platformName} ${x.device.remoteId} ${x.rssi}';
        }).join('\n                    ')}',
      );

      for (final result in r) {
        if (!result.device.platformName.startsWith('LARQ_')) continue;
        final mac = result.device.remoteId.str;
        _bottles.putIfAbsent(mac, () {
          return Bottle(result.device);
        });
      }

      Future<void> asd() async {
        final asd = await FlutterBluePlus.systemDevices([]);
        print(asd);
        print(
          '||||||||||||||||||| ${asd.where(filterDev).map((device) {
            return '${device.platformName} ${device.remoteId}';
          }).join('\n                    ')}',
        );
      }

      asd();
      return;
      for (final result in r) {
        final remoteId = result.device.remoteId.toString().toUpperCase();
        final name = result.device.advName.isNotEmpty
            ? result.device.advName
            : result.device.platformName;
        final isLarq = name.toLowerCase().startsWith('larq_');
        if (isLarq) {
          print(
            '[SVC]   device: $name ($remoteId) rssi=${result.rssi} larq=$isLarq',
          );
        }
        if (!isLarq) continue;
        if (seenIds.add(remoteId)) {
          results.add(result);
        }
      }
      results.sort((a, b) => (b.rssi).compareTo(a.rssi));
      scanController.add(List.unmodifiable(results));
    });

    scanController.onCancel = () {
      sub.cancel();
      FlutterBluePlus.stopScan();
    };

    return scanController.stream;
  }

  /// Connect to a bottle and create a managed session.
  Future<({bool success, String error})> connectToBottle(
    BluetoothDevice device,
  ) async {
    final remoteId = device.remoteId.toString();
    // Reuse existing session if device already managed
    var session = _sessions[remoteId];
    if (session != null && session.isConnected) {
      print('[SVC] session $remoteId already connected');
      return (success: true, error: '');
    }
    session = BottleSession();
    _sessions[remoteId] = session;

    final result = await session.connect(device);
    if (!result.success) {
      _sessions.remove(remoteId);
    }
    return result;
  }

  /// Disconnect a specific bottle session.
  Future<void> disconnectBottle(String remoteId) async {
    final session = _sessions.remove(remoteId);
    if (session != null) {
      await session.disconnect();
      session.dispose();
    }
  }

  /// Disconnect all sessions.
  Future<void> disconnectAll() async {
    final ids = _sessions.keys.toList();
    for (final id in ids) {
      await disconnectBottle(id);
    }
  }

  /// On startup: log all connected devices and try to reconnect to any
  /// stale LARQ bottles found at the BlueZ system level. Fall back to
  /// disconnect if reconnect fails.
  Future<void> recoverStaleConnections() async {
    print('[SVC] recoverStaleConnections: checking connections...');

    final ourDevices = FlutterBluePlus.connectedDevices;
    print('[SVC]   connectedDevices (our app): ${ourDevices.length}');
    for (final d in ourDevices) {
      final name = d.platformName;
      print(
        '[SVC]     $name ${d.remoteId} isConnected=${d.isConnected} '
        'isDisconnected=${d.isDisconnected}',
      );
    }

    try {
      final systemDevices = await FlutterBluePlus.systemDevices([]);
      print('[SVC]   systemDevices (OS level): ${systemDevices.length}');
      for (final d in systemDevices) {
        final name = d.platformName;
        print(
          '[SVC]     $name ${d.remoteId} isConnected=${d.isConnected} '
          'isDisconnected=${d.isDisconnected}',
        );
        if (name.toLowerCase().startsWith('larq_')) {
          print('[SVC]   stale LARQ found, trying reconnect...');
          final result = await connectToBottle(d);
          if (result.success) {
            print('[SVC]   reconnect OK');
          } else {
            print(
              '[SVC]   reconnect failed: ${result.error}, disconnecting...',
            );
            try {
              await d.disconnect().timeout(const Duration(seconds: 5));
              print('[SVC]   disconnect OK');
            } catch (e) {
              print('[SVC]   disconnect failed: $e');
            }
          }
        }
      }
    } catch (e) {
      print('[SVC]   systemDevices error: $e');
    }
  }

  /// Disconnect and remove-bond a ghost/cached device (RSSI=0 scan entries).
  Future<void> disconnectGhost(BluetoothDevice device) async {
    final remoteId = device.remoteId.toString();
    print('[SVC] disconnectGhost: $remoteId');
    try {
      await device.disconnect().timeout(const Duration(seconds: 5));
      print('[SVC]   disconnect OK');
    } catch (e) {
      print('[SVC]   disconnect failed: $e');
    }
    try {
      await device.removeBond();
      print('[SVC]   removeBond OK');
    } catch (e) {
      print('[SVC]   removeBond failed: $e');
    }
  }

  void dispose() {
    print('[SVC] dispose: disconnecting all sessions');
    disconnectAll();
  }
}
