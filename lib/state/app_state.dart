import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:signals/signals.dart';

import 'package:bottle/state/bottle_controller.dart';

final activeBottles = listSignal<BottleController>([]);

final selectedBottleIndex = signal<int?>(null);

final bluetoothAdapterState =
    signal<BluetoothAdapterState>(BluetoothAdapterState.unknown);

final isScanning = signal<bool>(false);
