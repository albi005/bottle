import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BottleConnection {
  static const txUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const rxUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  BluetoothDevice? device;
  BluetoothCharacteristic? txChar;
  BluetoothCharacteristic? rxChar;
  BluetoothCharacteristic? batteryChar;
  BluetoothCharacteristic? modelNumberChar;
  BluetoothCharacteristic? firmwareRevChar;
  StreamSubscription<List<int>>? _rxSubscription;

  Future<void> connect(BluetoothDevice dev) async {
    device = dev;
    await device!.connect(
      license: License.free,
      autoConnect: false,
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> discoverServices() async {
    await device!.discoverServices();
    for (final svc in device!.servicesList) {
      for (final c in svc.characteristics) {
        final u = c.uuid.toString();
        if (u == txUuid) txChar = c;
        if (u == rxUuid) rxChar = c;
        if (u == '00002a19-0000-1000-8000-00805f9b34fb') batteryChar = c;
        if (u == '00002a24-0000-1000-8000-00805f9b34fb') modelNumberChar = c;
        if (u == '00002a26-0000-1000-8000-00805f9b34fb') firmwareRevChar = c;
      }
    }
  }

  Future<void> subscribeToRx(void Function(List<int>) onData) async {
    if (rxChar == null) throw StateError('RX characteristic not found');
    _rxSubscription = rxChar!.onValueReceived.listen(onData);
    await rxChar!.setNotifyValue(true);
  }

  Future<void> disconnect() async {
    await _rxSubscription?.cancel();
    _rxSubscription = null;
    await device?.disconnect();
  }
}
