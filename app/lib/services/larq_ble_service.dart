// LARQ PureVis 2 BLE Communication Service
// Uses flutter_blue_plus for BLE communication with the bottle.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/larq_protocol.dart';
import 'protobuf_codec.dart';

class LarqBleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _batteryCharacteristic;
  StreamSubscription? _notificationSubscription;

  int _requestIdCounter = 0;
  final _pendingRequests = HashMap<int, Completer<Uint8List>>();

  final _responseController = StreamController<LarqResponse>.broadcast();

  LarqDeviceInfo _deviceInfo = LarqDeviceInfo();
  LarqDeviceInfo get deviceInfo => _deviceInfo;

  bool _connected = false;
  bool get isConnected => _connected;

  String? _lastRemoteId;
  String? get lastRemoteId => _lastRemoteId;

  bool _intentionalDisconnect = false;
  bool get intentionalDisconnect => _intentionalDisconnect;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  int _batteryLevel = -1;
  int get batteryLevel => _batteryLevel;

  CapBottleSensorState? _bottleSensorState;
  CapBottleSensorState? get bottleSensorState => _bottleSensorState;

  CapSipSensorState? _sipSensorState;
  CapSipSensorState? get sipSensorState => _sipSensorState;

  CapTofState? _tofState;
  CapTofState? get tofState => _tofState;

  CapAccelerometerState? _accelerometerState;
  CapAccelerometerState? get accelerometerState => _accelerometerState;

  CapAmbientLightSensorState? _ambientLightState;
  CapAmbientLightSensorState? get ambientLightState => _ambientLightState;

  CapHallEffectSensorState? _hallEffectState;
  CapHallEffectSensorState? get hallEffectState => _hallEffectState;

  CapEnumUiState _uiState = CapEnumUiState.allOff;
  CapEnumUiState get uiState => _uiState;

  CapPowerSavingMode _powerSavingMode = CapPowerSavingMode.off;
  CapPowerSavingMode get powerSavingMode => _powerSavingMode;

  List<CapTofLog> _tofLogs = [];
  List<CapTofLog> get tofLogs => List.unmodifiable(_tofLogs);

  List<CapActivationLog> _activationLogs = [];
  List<CapActivationLog> get activationLogs => List.unmodifiable(_activationLogs);

  List<CapFaultLog> _faultLogs = [];
  List<CapFaultLog> get faultLogs => List.unmodifiable(_faultLogs);

  List<CapAdcLog> _activationAdcLogs = [];
  List<CapAdcLog> get activationAdcLogs => List.unmodifiable(_activationAdcLogs);

  List<CapAdcLog> _chargingAdcLogs = [];
  List<CapAdcLog> get chargingAdcLogs => List.unmodifiable(_chargingAdcLogs);

  Stream<LarqResponse> get responseStream => _responseController.stream;

  // Background poll loop
  bool _polling = false;
  Duration _lastPollDuration = Duration.zero;
  Timer? _pollTimer;
  int _pollSeq = 0;

  final _pollItemController = StreamController<String?>.broadcast();
  Stream<String?> get pollingItemStream => _pollItemController.stream;
  Duration get lastPollDuration => _lastPollDuration;

  void _startPoll() {
    if (_polling || !_connected) return;
    _pollSeq++;
    _scheduleNextPoll();
  }

  void _stopPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _polling = false;
    _pollSeq++; // cancel any in-progress poll cycle
    _pollItemController.add(null);
    for (final c in _pendingRequests.values) {
      c.completeError('Disconnected');
    }
    _pendingRequests.clear();
    print('[SVC] _stopPoll seq=$_pollSeq pending=${_pendingRequests.length}');
  }

  Future<void> _runPoll() async {
    if (_polling || !_connected) return;
    _polling = true;
    _pollSeq++;
    final seq = _pollSeq;
    final start = DateTime.now();

    try {
      await _pollItem('ToF Log', getTofLog);
      if (seq != _pollSeq) return;
      await _pollItem('ToF State', getTofState);
      if (seq != _pollSeq) return;
      await _pollItem('Bottle Sensor', getBottleSensorState);
      if (seq != _pollSeq) return;
      await _pollItem('UI State', getUiState);
      if (seq != _pollSeq) return;
      await _pollItem('SIP Sensor', getSipSensorState);
      if (seq != _pollSeq) return;
      await _pollItem('Accelerometer', getAccelerometerState);
      if (seq != _pollSeq) return;
      await _pollItem('Ambient Light', getAmbientLightSensorState);
      if (seq != _pollSeq) return;
      await _pollItem('Hall Effect', getHallEffectSensorState);
      if (seq != _pollSeq) return;
      await _pollItem('Activation Log', getActivationLog);
      if (seq != _pollSeq) return;
      await _pollItem('Fault Log', getFaultLog);
      if (seq != _pollSeq) return;
      await _pollItem('Act ADC Log', getActivationAdcLog);
      if (seq != _pollSeq) return;
      await _pollItem('Chg ADC Log', getChargingAdcLog);
      if (seq != _pollSeq) return;
      await _pollItem('Battery', readBleBatteryLevel);
    } catch (_) {}

    _lastPollDuration = DateTime.now().difference(start);
    _polling = false;
    _pollItemController.add(null);

    _scheduleNextPoll();
  }

  Future<void> _pollItem(String label, Future<void> Function() fetch) async {
    _pollItemController.add(label);
    await fetch();
  }

  void _scheduleNextPoll() {
    if (!_connected) return;
    _pollTimer?.cancel();
    final delay = _lastPollDuration * 2;
    if (delay < const Duration(seconds: 1)) {
      _pollTimer = Timer(const Duration(seconds: 1), _runPoll);
    } else {
      _pollTimer = Timer(delay, _runPoll);
    }
  }

  /// Scan for LARQ bottle devices. Shows all BLE devices on Linux
  /// since BlueZ doesn't always support service UUID filter in scan.
  Stream<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 15)}) {
    FlutterBluePlus.stopScan();
    final seenIds = <String>{};
    final results = <ScanResult>[];
    final scanController = StreamController<List<ScanResult>>.broadcast();

    FlutterBluePlus.startScan(timeout: timeout);
    print('[SVC] scanForDevices started (timeout=${timeout.inSeconds}s)');

    final sub = FlutterBluePlus.scanResults.listen((r) {
      print('[SVC] scanResults got ${r.length} devices');
      for (final result in r) {
        final remoteId = result.device.remoteId.toString().toUpperCase();
        final name = result.device.advName.isNotEmpty
            ? result.device.advName
            : result.device.platformName;
        final isLarq = name.toLowerCase().startsWith('larq_');
        if (isLarq) {
          print('[SVC]   device: $name ($remoteId) rssi=${result.rssi} larq=$isLarq');
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

  /// Connect to a LARQ bottle with detailed error reporting.
  Future<({bool success, String error})> connectWithResult(BluetoothDevice device) async {
    print('[SVC] connectWithResult connected=$_connected device=${device.remoteId}');
    if (_connected) await disconnect();

    _device = device;
    try {
      FlutterBluePlus.stopScan(); // ensure no scan is running
      await Future.delayed(const Duration(seconds: 1)); // let BlueZ settle
      print('[SVC] calling device.connect()...');
      await device.connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Connection timed out (15s)'),
      );
      print('[SVC] device.connect() OK');

      _connected = true;
      _connectionController.add(true);
      _lastRemoteId = device.remoteId.toString();
      _intentionalDisconnect = false;

      await _discoverServices();

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        await device.disconnect();
        _connected = false;
        _connectionController.add(false);
        return (
          success: false,
          error: 'UART service found but missing TX/RX characteristics. '
              'Device may be in DFU mode.'
        );
      }

      // Read standard BLE info (non-critical, don't fail on error)
      try { await _readDeviceInfo(); } catch (_) {}

      // Set up notifications on TX characteristic (bottle -> phone: 6e400003, notify)
      await _txCharacteristic!.setNotifyValue(true);
      _notificationSubscription = _txCharacteristic!.onValueReceived.listen(
        _handleNotification,
      );

      _startPoll();

      return (success: true, error: '');
    } on Exception catch (e) {
      _connected = false;
      _connectionController.add(false);
      try { await device.disconnect(); } catch (_) {}
      return (success: false, error: '${e.runtimeType}: $e');
    }
  }

  /// Legacy connect method for backward compatibility.
  Future<bool> connect(BluetoothDevice device) async {
    final result = await connectWithResult(device);
    return result.success;
  }

  Future<void> _discoverServices() async {
    if (_device == null) return;
    final services = await _device!.discoverServices();

    for (final service in services) {
      print('[LARQ] Discovered service: ${service.serviceUuid}');
      for (final char in service.characteristics) {
        final props = <String>[];
        if (char.properties.broadcast) props.add('BC');
        if (char.properties.read) props.add('RD');
        if (char.properties.writeWithoutResponse) props.add('WW');
        if (char.properties.write) props.add('WR');
        if (char.properties.notify) props.add('NF');
        if (char.properties.indicate) props.add('IN');
        print('[LARQ]   char: ${char.characteristicUuid} props=$props');

        if (_uuidMatch(service.serviceUuid, LarqBleUuids.serviceUart)) {
          if (_uuidMatch(char.characteristicUuid, LarqBleUuids.charTx)) {
            _txCharacteristic = char;
          } else if (_uuidMatch(char.characteristicUuid, LarqBleUuids.charRx)) {
            _rxCharacteristic = char;
          }
        } else if (_uuidMatch(service.serviceUuid, LarqBleUuids.serviceBattery)) {
          if (_uuidMatch(char.characteristicUuid, LarqBleUuids.charBatteryLevel)) {
            _batteryCharacteristic = char;
          }
        }
      }
    }
  }

  bool _uuidMatch(Guid a, String b) {
    var aStr = a.toString().toLowerCase().replaceAll('-', '');
    // Expand short UUIDs (16/32-bit) to 128-bit for comparison
    if (aStr.length <= 8) {
      aStr = '0000$aStr-0000-1000-8000-00805f9b34fb'.replaceAll('-', '');
    }
    return aStr == b.toLowerCase().replaceAll('-', '');
  }

  Future<void> _readDeviceInfo() async {
    if (_device == null) return;
    final services = await _device!.discoverServices();

    Future<String> readChar(String serviceUuid, String charUuid) async {
      try {
        for (final service in services) {
          if (_uuidMatch(service.serviceUuid, serviceUuid)) {
            for (final char in service.characteristics) {
              if (_uuidMatch(char.characteristicUuid, charUuid)) {
                final value = await char.read();
                return String.fromCharCodes(value);
              }
            }
          }
        }
      } catch (_) {}
      return '';
    }

    _deviceInfo = _deviceInfo.copyWith(
      modelNumber: await readChar(LarqBleUuids.serviceDeviceInfo, LarqBleUuids.charModelNumber),
      serialNumber: await readChar(LarqBleUuids.serviceDeviceInfo, LarqBleUuids.charSerialNumber),
      firmwareRevision: await readChar(LarqBleUuids.serviceDeviceInfo, LarqBleUuids.charFirmwareRevision),
      hardwareRevision: await readChar(LarqBleUuids.serviceDeviceInfo, LarqBleUuids.charHardwareRevision),
      softwareRevision: await readChar(LarqBleUuids.serviceDeviceInfo, LarqBleUuids.charSoftwareRevision),
    );

    // Try reading battery level via standard BLE Battery Service
    final battVal = await readChar(LarqBleUuids.serviceBattery, LarqBleUuids.charBatteryLevel);
    if (battVal.isNotEmpty) {
      _batteryLevel = battVal.codeUnits.first;
      print('[LARQ] Battery from BLE GATT: $_batteryLevel%');
    }
  }


  Future<void> disconnect({bool intentional = true}) async {
    print('[SVC] disconnect BEGIN intentional=$intentional connected=$_connected device=${_device?.remoteId}');
    _stopPoll();
    _intentionalDisconnect = intentional;
    if (_notificationSubscription != null) {
      print('[SVC]   cancelling notification subscription');
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
    }
    if (_device != null) {
      final remoteId = _device!.remoteId.toString();
      print('[SVC]   calling device.disconnect()...');
      try {
        await _device!.disconnect().timeout(const Duration(seconds: 5));
        print('[SVC]   device.disconnect() OK');
        // Remove from BlueZ cache so the bottle can reconnect immediately
        await _removeDeviceFromBlueZ(remoteId);
      } catch (e) {
        print('[SVC]   device.disconnect() failed: $e');
      }
    }
    print('[SVC] disconnect DONE, clearing state');
    _device = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _batteryCharacteristic = null;
    _connected = false;
    _connectionController.add(false);
    try { FlutterBluePlus.stopScan(); } catch (e) { print('[SVC] stopScan failed: $e'); }
  }

  /// Remove a device from BlueZ cache so it can be rediscovered immediately.
  Future<void> _removeDeviceFromBlueZ(String remoteId) async {
    try {
      final result = await Process.run(
        'bluetoothctl', ['remove', remoteId],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 3));
      if (result.exitCode == 0) {
        print('[SVC]   bluetoothctl remove $remoteId OK');
      } else {
        print('[SVC]   bluetoothctl remove $remoteId exit=${result.exitCode}');
      }
    } catch (e) {
      print('[SVC]   bluetoothctl remove failed: $e');
    }
  }

  Future<({CapEnumResponseCode code, Uint8List? body})> _sendRequest(
      CapBleRequestType type, [List<int>? payload]) async {
    if (_rxCharacteristic == null) {
      throw Exception('Not connected to bottle');
    }

    final requestId = ++_requestIdCounter;
    final requestData = encodeCapBleRequest(requestId, type, payload);
    print('[LARQ] TX id=$requestId type=$type bytes=${requestData.length}');
    final completer = Completer<Uint8List>();
    _pendingRequests[requestId] = completer;

    await _rxCharacteristic!.write(requestData, withoutResponse: true);

    try {
      final data = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      final decoded = decodeCapBleResponse(data);
      _pendingRequests.remove(requestId);
      return (code: decoded.code, body: decoded.bodyData);
    } catch (e) {
      _pendingRequests.remove(requestId);
      rethrow;
    }
  }

  void _handleNotification(List<int> data) {
    // Print first 64 bytes hex
    final preview = data.sublist(0, data.length.clamp(0, 64))
        .map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    print('[LARQ] RX ${data.length}B: $preview');

    // Full CapBleResponse protocol
    final decoded = decodeCapBleResponse(Uint8List.fromList(data),
      debugLog: (msg) => print('[LARQ]   $msg'),
    );
    print('[LARQ] id=${decoded.requestId} code=${decoded.code.name} type_url=${decoded.typeUrl} bodyLen=${decoded.bodyData?.length}');
    if (decoded.bodyData != null && decoded.bodyData!.isNotEmpty) {
      print('[LARQ]   body hex: ${decoded.bodyData!.sublist(0, decoded.bodyData!.length.clamp(0, 64)).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}');
    }
    _pendingRequests[decoded.requestId]?.complete(Uint8List.fromList(data));

    if (decoded.bodyData != null && decoded.typeUrl != null) {
      _processResponse(decoded.typeUrl!, decoded.bodyData!);
    }
  }

  void _processResponse(String typeUrl, Uint8List body) {
    try {
      // Remove any package prefix for matching
      final short = typeUrl.replaceFirst(RegExp(r'^.*/'), '');
      if (short == 'ResponseGetCapTofLog') {
        print('[LARQ] ToF log body hex: ${body.map((b) => b.toRadixString(16).padLeft(2, '0')).join()} (${body.length}B)');
        final newEntries = decodeResponseGetCapTofLog(body);
        print('[LARQ] ToF log entries: ${newEntries.length}');
        _mergeLogList(_tofLogs, newEntries);
        _tofLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _responseController.add(LarqResponse.tofLog(_tofLogs));
      } else if (short == 'ResponseGetCapStateLog') {
        print('[LARQ] StateLog body hex: ${body.map((b) => b.toRadixString(16).padLeft(2, '0')).join()} (${body.length}B)');
        final newEntries = decodeResponseGetCapTofLog(body);
        print('[LARQ] StateLog as ToF: ${newEntries.length} entries');
        _mergeLogList(_tofLogs, newEntries);
        _tofLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _responseController.add(LarqResponse.tofLog(_tofLogs));
      } else if (short == 'ResponseGetCapTofState') {
        _tofState = decodeResponseGetCapTofState(body);
        _responseController.add(LarqResponse.tofState(_tofState!));
      } else if (short == 'ResponseGetCapBottleSensorState') {
        _bottleSensorState = decodeResponseGetCapBottleSensorState(body);
        _responseController.add(LarqResponse.bottleSensorState(_bottleSensorState!));
      } else if (short == 'ResponseGetCapSipSensorState') {
        _sipSensorState = decodeResponseGetCapSipSensorState(body);
        _responseController.add(LarqResponse.sipSensorState(_sipSensorState!));
      } else if (short == 'ResponseGetCapAccelerometerState') {
        _accelerometerState = decodeResponseGetCapAccelerometerState(body);
        _responseController.add(LarqResponse.accelerometerState(_accelerometerState!));
      } else if (short == 'ResponseGetCapUiState') {
        final result = decodeResponseGetCapUiState(body);
        _uiState = result.state;
        _powerSavingMode = result.powerSavingMode;
        _responseController.add(LarqResponse.uiState(result.state, result.powerSavingMode));
      } else if (short == 'ResponseGetCapActivationLog') {
        print('[LARQ] Activation log body hex: ${body.map((b) => b.toRadixString(16).padLeft(2, '0')).join()} (${body.length}B)');
        final newEntries = decodeResponseGetCapActivationLog(body);
        print('[LARQ] Activation log entries: ${newEntries.length}');
        _mergeLogList(_activationLogs, newEntries);
        _activationLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (_activationLogs.isNotEmpty) {
          _batteryLevel = _activationLogs.last.batterySocInPercentage;
          print('[LARQ] Battery from activation log: $_batteryLevel%');
        }
        _responseController.add(LarqResponse.activationLog(_activationLogs));
      } else if (short == 'ResponseGetActivationCapAdcLog') {
        print('[LARQ] Act ADC body hex: ${body.map((b) => b.toRadixString(16).padLeft(2, '0')).join()} (${body.length}B)');
        final newEntries = decodeResponseGetActivationCapAdcLog(body);
        print('[LARQ] Act ADC log entries: ${newEntries.length}');
        _mergeLogList(_activationAdcLogs, newEntries);
        _activationAdcLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      } else if (short == 'ResponseGetChargingCapAdcLog') {
        final newEntries = decodeResponseGetChargingCapAdcLog(body);
        _mergeLogList(_chargingAdcLogs, newEntries);
        _chargingAdcLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        print('[LARQ] Chg ADC log entries: ${_chargingAdcLogs.length}');
      } else if (short == 'ResponseGetCapFaultLog') {
        final newEntries = decodeResponseGetCapFaultLog(body);
        _mergeLogList(_faultLogs, newEntries);
        _faultLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        print('[LARQ] Fault log entries: ${_faultLogs.length}');
        _responseController.add(LarqResponse.faultLog(_faultLogs));
      } else if (short == 'ResponseGetCapAmbientLightSensorState') {
        _ambientLightState = decodeResponseGetCapAmbientLightSensorState(body);
        _responseController.add(LarqResponse.ambientLightState(_ambientLightState!));
      } else if (short == 'ResponseGetCapHallEffectSensorState') {
        _hallEffectState = decodeResponseGetCapHallEffectSensorState(body);
        _responseController.add(LarqResponse.hallEffectState(_hallEffectState!));
      }
    } catch (e, st) {
      print('[LARQ] Parse error type_url=$typeUrl: $e');
      print('[LARQ] Stack: $st');
      _responseController.add(LarqResponse.error('Failed to parse response: $e'));
    }
  }

  // --- Public API methods ---

  Future<void> getCapStateLog() async {
    final q = encodeCapLogQuery(fromTimestamp: 0, limit: 255);
    final req = encodeRequestGetCapStateLog(q);
    await _sendRequest(CapBleRequestType.getCapStateLog, req);
  }
  Future<void> getTofLog() async {
    final query = encodeCapLogQuery(fromTimestamp: 0, limit: 255);
    final req = encodeRequestGetCapTofLog(query);
    await _sendRequest(CapBleRequestType.getCapTofLog, req);
  }
  Future<void> getTofState() async => _sendRequest(CapBleRequestType.getCapTofState);
  Future<void> getBottleSensorState() async => _sendRequest(CapBleRequestType.getCapBottleSensorState);
  Future<void> getUiState() async => _sendRequest(CapBleRequestType.getCapUiState);
  Future<void> getSipSensorState() async => _sendRequest(CapBleRequestType.getCapSipSensorState);
  Future<void> getAccelerometerState() async => _sendRequest(CapBleRequestType.getCapAccelerometerState);
  Future<void> getAmbientLightSensorState() async => _sendRequest(CapBleRequestType.getCapAmbientLightSensorState);
  Future<void> getHallEffectSensorState() async => _sendRequest(CapBleRequestType.getCapHallEffectSensorState);
  Future<void> getActivationLog() async {
    final q = encodeCapLogQuery(fromTimestamp: 0, limit: 255);
    final req = encodeRequestGetCapActivationLog(q);
    await _sendRequest(CapBleRequestType.getCapActivationLog, req);
  }
  Future<void> getFaultLog() async {
    final q = encodeCapLogQuery(fromTimestamp: 0, limit: 255);
    final req = encodeRequestGetCapFaultLog(q);
    await _sendRequest(CapBleRequestType.getCapFaultLog, req);
  }
  Future<void> getChargingAdcLog() async {
    final q = encodeCapLogQuery(fromTimestamp: 0, limit: 255);
    final req = encodeRequestGetChargingCapAdcLog(q);
    await _sendRequest(CapBleRequestType.getChargingCapAdcLog, req);
  }
  Future<void> getActivationAdcLog() async {
    final q = encodeCapLogQuery(fromTimestamp: 0, limit: 255);
    final req = encodeRequestGetActivationCapAdcLog(q);
    await _sendRequest(CapBleRequestType.getActivationCapAdcLog, req);
  }

  Future<void> startPurification() async {
    final payload = encodeRequestSetCapUvActivate(CapEnumUvActivationMode.standard);
    await _sendRequest(CapBleRequestType.setCapUvActivate, payload);
  }

  Future<void> stopPurification() async {
    final payload = encodeRequestSetCapUvActivate(CapEnumUvActivationMode.stop);
    await _sendRequest(CapBleRequestType.setCapUvActivate, payload);
  }

  Future<void> setPowerSavingMode(CapPowerSavingMode mode) async {
    final payload = encodeRequestSetCapPowerSavingMode(mode);
    await _sendRequest(CapBleRequestType.setCapPowerSavingMode, payload);
  }

  Future<void> factoryReset() async => _sendRequest(CapBleRequestType.factoryReset);
  Future<void> enterDfuMode() async => _sendRequest(CapBleRequestType.enterDfuMode);

  Future<void> readBleBatteryLevel() async {
    if (_device == null) return;
    try {
      if (_batteryCharacteristic == null) {
        await _discoverServices();
      }
      if (_batteryCharacteristic == null) return;
      final value = await _batteryCharacteristic!.read();
      if (value.isNotEmpty) {
        _batteryLevel = value[0];
        print('[LARQ] Battery GATT: $_batteryLevel%');
      }
    } catch (e) {
      print('[LARQ] Battery read failed: $e');
    }
  }

  Future<void> fetchAllData() async {
    await getTofLog();
    await getTofState();
    await getBottleSensorState();
    await getUiState();
    await getSipSensorState();
    await getAccelerometerState();
    await getAmbientLightSensorState();
    await getHallEffectSensorState();
    await getActivationLog();
    await getFaultLog();
    await getActivationAdcLog();
    await getChargingAdcLog();
    await readBleBatteryLevel();
  }


  void _mergeLogList<T extends dynamic>(List<T> existing, List<T> newEntries) {
    for (final entry in newEntries) {
      // Check for duplicate by timestamp (works for all log types)
      final newTs = (entry as dynamic).timestamp as int;
      final exists = existing.any((e) => (e as dynamic).timestamp == newTs);
      if (!exists) existing.add(entry);
    }
  }

  // --- Paginated loading ---

  Future<void> loadMoreTofLogs() async {
    final fromTs = _tofLogs.isEmpty ? 0 : _tofLogs.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b) + 1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetCapTofLog(q);
    await _sendRequest(CapBleRequestType.getCapTofLog, req);
  }

  Future<void> loadMoreActivationLogs() async {
    final fromTs = _activationLogs.isEmpty ? 0 : _activationLogs.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b) + 1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetCapActivationLog(q);
    await _sendRequest(CapBleRequestType.getCapActivationLog, req);
  }

  Future<void> loadMoreFaultLogs() async {
    final fromTs = _faultLogs.isEmpty ? 0 : _faultLogs.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b) + 1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetCapFaultLog(q);
    await _sendRequest(CapBleRequestType.getCapFaultLog, req);
  }

  Future<void> loadMoreActivationAdcLogs() async {
    final fromTs = _activationAdcLogs.isEmpty ? 0 : _activationAdcLogs.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b) + 1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetActivationCapAdcLog(q);
    await _sendRequest(CapBleRequestType.getActivationCapAdcLog, req);
  }

  Future<void> loadMoreChargingAdcLogs() async {
    final fromTs = _chargingAdcLogs.isEmpty ? 0 : _chargingAdcLogs.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b) + 1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetChargingCapAdcLog(q);
    await _sendRequest(CapBleRequestType.getChargingCapAdcLog, req);
  }


  void resetState() {
    _stopPoll();
    _bottleSensorState = null;
    _sipSensorState = null;
    _tofState = null;
    _accelerometerState = null;
    _ambientLightState = null;
    _hallEffectState = null;
    _uiState = CapEnumUiState.allOff;
    _powerSavingMode = CapPowerSavingMode.off;
    _activationLogs = [];
    _faultLogs = [];
    _activationAdcLogs = [];
    _chargingAdcLogs = [];
    _batteryCharacteristic = null;
  }

  void dispose() {
    print('[SVC] dispose called');
    _stopPoll();
    _pollItemController.close();
    _notificationSubscription?.cancel();
    _responseController.close();
    _connectionController.close();
    disconnect().then((_) => print('[SVC] dispose disconnect done'));
  }
}

class LarqResponse {
  final LarqResponseType type;
  final dynamic data;

  const LarqResponse._(this.type, this.data);

  factory LarqResponse.tofLog(List<CapTofLog> logs) =>
      LarqResponse._(LarqResponseType.tofLog, logs);
  factory LarqResponse.tofState(CapTofState state) =>
      LarqResponse._(LarqResponseType.tofState, state);
  factory LarqResponse.bottleSensorState(CapBottleSensorState state) =>
      LarqResponse._(LarqResponseType.bottleSensorState, state);
  factory LarqResponse.sipSensorState(CapSipSensorState state) =>
      LarqResponse._(LarqResponseType.sipSensorState, state);
  factory LarqResponse.accelerometerState(CapAccelerometerState state) =>
      LarqResponse._(LarqResponseType.accelerometerState, state);
  factory LarqResponse.ambientLightState(CapAmbientLightSensorState state) =>
      LarqResponse._(LarqResponseType.ambientLightState, state);
  factory LarqResponse.hallEffectState(CapHallEffectSensorState state) =>
      LarqResponse._(LarqResponseType.hallEffectState, state);
  factory LarqResponse.uiState(CapEnumUiState state, CapPowerSavingMode powerSaving) =>
      LarqResponse._(LarqResponseType.uiState, (state: state, powerSaving: powerSaving));
  factory LarqResponse.activationLog(List<CapActivationLog> logs) =>
      LarqResponse._(LarqResponseType.activationLog, logs);
  factory LarqResponse.faultLog(List<CapFaultLog> logs) =>
      LarqResponse._(LarqResponseType.faultLog, logs);
  factory LarqResponse.error(String message) =>
      LarqResponse._(LarqResponseType.error, message);
}

enum LarqResponseType {
  tofLog, tofState, bottleSensorState, sipSensorState,
  accelerometerState, ambientLightState, hallEffectState,
  uiState, activationLog, faultLog, error,
}
