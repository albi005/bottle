import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:bottle/models/bottle_device.dart';
import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/state/app_state.dart';

class BleScanner {
  static final nusServiceUuid = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  StreamSubscription? _scanSubscription;

  void startScanning() {
    if (_scanSubscription != null) return;
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      final larqBottles = results.where(
        (r) => r.device.platformName.startsWith('LARQ_'),
      );

      final seenNames = <String>{};

      for (final result in larqBottles) {
        final name = result.device.platformName;
        seenNames.add(name);

        BottleController? existing;
        for (final b in activeBottles) {
          if (b.name == name) {
            existing = b;
            break;
          }
        }

        if (existing != null) {
          existing.updateScan(result);
          final phase = existing.connectionPhase.value;
          if (phase == ConnectionPhase.visible ||
              phase == ConnectionPhase.failed) {
            existing.connect(result);
          }
        } else {
          final controller = BottleController(
            name: name,
            remoteId: result.device.remoteId.toString(),
          )..updateScan(result);

          activeBottles.add(controller);

          if (selectedBottleIndex.value == null) {
            selectedBottleIndex.value = activeBottles.length - 1;
          }

          controller.connect(result);
        }
      }

      for (final controller in activeBottles) {
        if (!seenNames.contains(controller.name)) {
          if (controller.connectionPhase.value == ConnectionPhase.visible ||
              controller.connectionPhase.value == ConnectionPhase.connecting ||
              controller.connectionPhase.value == ConnectionPhase.failed) {
            controller.rssi.value = null;
          }
        }
      }
    });

    isScanning.value = true;

    FlutterBluePlus.startScan();
  }

  void stopScanning() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    isScanning.value = false;
  }

  void dispose() {
    stopScanning();
  }
}
