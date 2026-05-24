import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/larq_protocol.dart';
import 'protobuf_codec.dart';

class BottleSession {
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

  String? get lastRemoteId => _device?.remoteId.toString();

  bool _intentionalDisconnect = false;
  bool get intentionalDisconnect => _intentionalDisconnect;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  int _batteryLevel = -1;
  int get batteryLevel => _batteryLevel;

  CapBottleSensorState? bottleSensorState;
  CapSipSensorState? sipSensorState;
  CapTofState? tofState;
  CapAccelerometerState? accelerometerState;
  CapAmbientLightSensorState? ambientLightState;
  CapHallEffectSensorState? hallEffectState;
  CapEnumUiState uiState = CapEnumUiState.allOff;
  CapPowerSavingMode powerSavingMode = CapPowerSavingMode.off;

  List<CapTofLog> tofLogs = [];
  List<CapActivationLog> activationLogs = [];
  List<CapFaultLog> faultLogs = [];
  List<CapAdcLog> activationAdcLogs = [];
  List<CapAdcLog> chargingAdcLogs = [];

  static const _maxAutoPages = 150;
  int _tofAutoPages = 0;
  int _actAutoPages = 0;
  int _faultAutoPages = 0;
  int _actAdcAutoPages = 0;
  int _chgAdcAutoPages = 0;

  bool _jumpedToLatest = false;

  // Poll loop
  bool _polling = false;
  Duration _lastPollDuration = Duration.zero;
  Timer? _pollTimer;
  int _pollSeq = 0;

  final _pollItemController = StreamController<String?>.broadcast();
  Stream<String?> get pollingItemStream => _pollItemController.stream;
  Duration get lastPollDuration => _lastPollDuration;

  String get _logId {
    final id = _device?.remoteId.toString() ?? '??';
    final short = id.length >= 4 ? id.substring(id.length - 4) : id;
    return short;
  }

  // --- Connection ---

  Future<({bool success, String error})> connect(
    BluetoothDevice device,
  ) async {
    print('[SES:$_logId] connect connected=$_connected');
    if (_connected) await disconnect();

    _device = device;
    try {
      FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(seconds: 1));
      print('[SES:$_logId] calling device.connect()...');
      await device.connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Connection timed out (15s)'),
      );
      print('[SES:$_logId] device.connect() OK');

      _connected = true;
      _connectionController.add(true);
      _intentionalDisconnect = false;

      await _discoverServices();

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        await device.disconnect();
        _connected = false;
        _connectionController.add(false);
        return (
          success: false,
          error: 'UART service found but missing TX/RX characteristics. '
              'Device may be in DFU mode.',
        );
      }

      try {
        await _readDeviceInfo();
      } catch (_) {}

      await _txCharacteristic!.setNotifyValue(true);
      _notificationSubscription = _txCharacteristic!.onValueReceived.listen(
        _handleNotification,
      );

      // TODO: re-enable sync loop after connect/disconnect testing
      // _startPoll();

      return (success: true, error: '');
    } on Exception catch (e) {
      _connected = false;
      _connectionController.add(false);
      try {
        await device.disconnect();
      } catch (_) {}
      return (success: false, error: '${e.runtimeType}: $e');
    }
  }

  Future<void> disconnect({bool intentional = true}) async {
    print(
      '[SES:$_logId] disconnect BEGIN intentional=$intentional connected=$_connected',
    );
    _stopPoll();
    _intentionalDisconnect = intentional;
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    if (_device != null) {
      try {
        await _device!.disconnect().timeout(const Duration(seconds: 5));
        print('[SES:$_logId] device.disconnect() OK');
      } catch (e) {
        print('[SES:$_logId] device.disconnect() failed: $e');
      }
    }
    print('[SES:$_logId] disconnect DONE');
    _device = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _batteryCharacteristic = null;
    _connected = false;
    _connectionController.add(false);
  }

  // --- Service discovery ---

  Future<void> _discoverServices() async {
    if (_device == null) return;
    final services = await _device!.discoverServices();

    for (final service in services) {
      print('[SES:$_logId] Discovered service: ${service.serviceUuid}');
      for (final char in service.characteristics) {
        final props = <String>[];
        if (char.properties.broadcast) props.add('BC');
        if (char.properties.read) props.add('RD');
        if (char.properties.writeWithoutResponse) props.add('WW');
        if (char.properties.write) props.add('WR');
        if (char.properties.notify) props.add('NF');
        if (char.properties.indicate) props.add('IN');
        print('[SES:$_logId]   char: ${char.characteristicUuid} props=$props');

        if (_uuidMatch(service.serviceUuid, LarqBleUuids.serviceUart)) {
          if (_uuidMatch(char.characteristicUuid, LarqBleUuids.charTx)) {
            _txCharacteristic = char;
          } else if (_uuidMatch(
            char.characteristicUuid,
            LarqBleUuids.charRx,
          )) {
            _rxCharacteristic = char;
          }
        } else if (_uuidMatch(
          service.serviceUuid,
          LarqBleUuids.serviceBattery,
        )) {
          if (_uuidMatch(
            char.characteristicUuid,
            LarqBleUuids.charBatteryLevel,
          )) {
            _batteryCharacteristic = char;
          }
        }
      }
    }
  }

  bool _uuidMatch(Guid a, String b) {
    var aStr = a.toString().toLowerCase().replaceAll('-', '');
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
      modelNumber: await readChar(
        LarqBleUuids.serviceDeviceInfo,
        LarqBleUuids.charModelNumber,
      ),
      serialNumber: await readChar(
        LarqBleUuids.serviceDeviceInfo,
        LarqBleUuids.charSerialNumber,
      ),
      firmwareRevision: await readChar(
        LarqBleUuids.serviceDeviceInfo,
        LarqBleUuids.charFirmwareRevision,
      ),
      hardwareRevision: await readChar(
        LarqBleUuids.serviceDeviceInfo,
        LarqBleUuids.charHardwareRevision,
      ),
      softwareRevision: await readChar(
        LarqBleUuids.serviceDeviceInfo,
        LarqBleUuids.charSoftwareRevision,
      ),
    );

    final battVal = await readChar(
      LarqBleUuids.serviceBattery,
      LarqBleUuids.charBatteryLevel,
    );
    if (battVal.isNotEmpty) {
      _batteryLevel = battVal.codeUnits.first;
      print('[SES:$_logId] Battery from BLE GATT: $_batteryLevel%');
    }
  }

  // --- Request/response protocol ---

  Future<({CapEnumResponseCode code, Uint8List? body})> _sendRequest(
    CapBleRequestType type, [
    List<int>? payload,
  ]) async {
    if (_rxCharacteristic == null) {
      throw Exception('Not connected to bottle');
    }

    final requestId = ++_requestIdCounter;
    final requestData = encodeCapBleRequest(requestId, type, payload);
    print('[SES:$_logId] TX id=$requestId type=$type bytes=${requestData.length}');
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
    final preview = data
        .sublist(0, data.length.clamp(0, 64))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    print('[SES:$_logId] RX ${data.length}B: $preview');

    final decoded = decodeCapBleResponse(
      Uint8List.fromList(data),
      debugLog: (msg) => print('[SES:$_logId]   $msg'),
    );
    print(
      '[SES:$_logId] id=${decoded.requestId} code=${decoded.code.name} '
      'type_url=${decoded.typeUrl} bodyLen=${decoded.bodyData?.length}',
    );
    if (decoded.bodyData != null && decoded.bodyData!.isNotEmpty) {
      print(
        '[SES:$_logId]   body hex: ${decoded.bodyData!.sublist(0, decoded.bodyData!.length.clamp(0, 64)).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
      );
    }
    _pendingRequests[decoded.requestId]?.complete(Uint8List.fromList(data));

    if (decoded.bodyData != null && decoded.typeUrl != null) {
      _processResponse(decoded.typeUrl!, decoded.bodyData!);
    }
  }

  void _processResponse(String typeUrl, Uint8List body) {
    try {
      final short = typeUrl.replaceFirst(RegExp(r'^.*/'), '');
      if (short == 'ResponseGetCapTofLog') {
        print(
          '[SES:$_logId] ToF log body hex: ${body.map((b) => b.toRadixString(16).padLeft(2, '0')).join()} (${body.length}B)',
        );
        final newEntries = decodeResponseGetCapTofLog(body);
        print('[SES:$_logId] ToF log entries: ${newEntries.length}');
        if (newEntries.isNotEmpty) {
          final firstTs = newEntries.first.timestamp;
          final lastTs = newEntries.last.timestamp;
          print(
            '[SES:$_logId] ToF ts range: $firstTs..$lastTs '
            '(${DateTime.fromMillisecondsSinceEpoch(firstTs * 1000, isUtc: true).toLocal()} .. '
            '${DateTime.fromMillisecondsSinceEpoch(lastTs * 1000, isUtc: true).toLocal()})',
          );
        }
        final added = _mergeLogList(tofLogs, newEntries);
        tofLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _responseController.add(LarqResponse.tofLog(tofLogs, _logId));
        if (added >= 7 && _tofAutoPages < _maxAutoPages) {
          _tofAutoPages++;
          _autoPageTofLogs();
        } else if (added < 7 && !_jumpedToLatest && tofLogs.isNotEmpty) {
          _jumpedToLatest = true;
          print('[SES:$_logId] Auto-paging done (added=$added), jumping to latest');
          _autoPageTofLogsHigh();
        }
      } else if (short == 'ResponseGetCapStateLog') {
        print(
          '[SES:$_logId] StateLog body hex: ${body.map((b) => b.toRadixString(16).padLeft(2, '0')).join()} (${body.length}B)',
        );
        final newEntries = decodeResponseGetCapTofLog(body);
        print('[SES:$_logId] StateLog as ToF: ${newEntries.length} entries');
        if (newEntries.isNotEmpty) {
          final firstTs = newEntries.first.timestamp;
          final lastTs = newEntries.last.timestamp;
          print(
            '[SES:$_logId] StateLog ts range: $firstTs..$lastTs '
            '(${DateTime.fromMillisecondsSinceEpoch(firstTs * 1000, isUtc: true).toLocal()} .. '
            '${DateTime.fromMillisecondsSinceEpoch(lastTs * 1000, isUtc: true).toLocal()})',
          );
        }
        final added = _mergeLogList(tofLogs, newEntries);
        tofLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _responseController.add(LarqResponse.tofLog(tofLogs, _logId));
        if (added >= 7 && _tofAutoPages < _maxAutoPages) {
          _tofAutoPages++;
          _autoPageTofLogs();
        }
      } else if (short == 'ResponseGetCapActivationLog') {
        print(
          '[SES:$_logId] Activation log body hex: ${body.map((b) => b.toRadixString(16).padLeft(2, '0')).join()} (${body.length}B)',
        );
        final newEntries = decodeResponseGetCapActivationLog(body);
        print('[SES:$_logId] Activation log entries: ${newEntries.length}');
        final added = _mergeLogList(activationLogs, newEntries);
        activationLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (activationLogs.isNotEmpty) {
          _batteryLevel = activationLogs.last.batterySocInPercentage;
          print('[SES:$_logId] Battery from activation log: $_batteryLevel%');
        }
        _responseController.add(LarqResponse.activationLog(activationLogs, _logId));
        if (added >= 7 && _actAutoPages < _maxAutoPages) {
          _actAutoPages++;
          _autoPageActivationLogs();
        }
      } else if (short == 'ResponseGetActivationCapAdcLog') {
        print(
          '[SES:$_logId] Act ADC body hex: ${body.map((b) => b.toRadixString(16).padLeft(2, '0')).join()} (${body.length}B)',
        );
        final newEntries = decodeResponseGetActivationCapAdcLog(body);
        print('[SES:$_logId] Act ADC log entries: ${newEntries.length}');
        final added = _mergeLogList(activationAdcLogs, newEntries);
        activationAdcLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (added >= 7 && _actAdcAutoPages < _maxAutoPages) {
          _actAdcAutoPages++;
          _autoPageActivationAdcLogs();
        }
      } else if (short == 'ResponseGetChargingCapAdcLog') {
        final newEntries = decodeResponseGetChargingCapAdcLog(body);
        final added = _mergeLogList(chargingAdcLogs, newEntries);
        chargingAdcLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        print('[SES:$_logId] Chg ADC log entries: ${chargingAdcLogs.length}');
        if (added >= 7 && _chgAdcAutoPages < _maxAutoPages) {
          _chgAdcAutoPages++;
          _autoPageChargingAdcLogs();
        }
      } else if (short == 'ResponseGetCapFaultLog') {
        final newEntries = decodeResponseGetCapFaultLog(body);
        final added = _mergeLogList(faultLogs, newEntries);
        faultLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        print('[SES:$_logId] Fault log entries: ${faultLogs.length}');
        _responseController.add(LarqResponse.faultLog(faultLogs, _logId));
        if (added >= 7 && _faultAutoPages < _maxAutoPages) {
          _faultAutoPages++;
          _autoPageFaultLogs();
        }
      } else if (short == 'ResponseGetCapAmbientLightSensorState') {
        ambientLightState = decodeResponseGetCapAmbientLightSensorState(body);
        _responseController.add(
          LarqResponse.ambientLightState(ambientLightState!, _logId),
        );
      } else if (short == 'ResponseGetCapHallEffectSensorState') {
        hallEffectState = decodeResponseGetCapHallEffectSensorState(body);
        _responseController.add(
          LarqResponse.hallEffectState(hallEffectState!, _logId),
        );
      }
    } catch (e, st) {
      print('[SES:$_logId] Parse error type_url=$typeUrl: $e');
      print('[SES:$_logId] Stack: $st');
      _responseController.add(
        LarqResponse.error('Failed to parse response: $e', _logId),
      );
    }
  }

  // --- Public API ---

  Stream<LarqResponse> get responseStream => _responseController.stream;

  Future<void> jumpToLatestTofLogs() async {
    final nowUtc = DateTime.now().toUtc();
    final ts = nowUtc.add(const Duration(days: 365));
    final epochSec = ts.millisecondsSinceEpoch ~/ 1000;
    print('[SES:$_logId] jumpToLatest: nowUtc=$nowUtc, queryTS=$epochSec');
    final q = encodeCapLogQuery(fromTimestamp: epochSec, limit: 255);
    final req = encodeRequestGetCapTofLog(q);
    await _sendRequest(CapBleRequestType.getCapTofLog, req);
  }

  Future<void> getCapStateLog() async {
    final q = encodeCapLogQuery(fromTimestamp: 0, limit: 255);
    final req = encodeRequestGetCapStateLog(q);
    await _sendRequest(CapBleRequestType.getCapStateLog, req);
  }

  Future<void> getActivationLog() async {
    final q = encodeCapLogQuery(
      fromTimestamp: _initialQueryTimestamp,
      limit: 255,
    );
    final req = encodeRequestGetCapActivationLog(q);
    await _sendRequest(CapBleRequestType.getCapActivationLog, req);
  }

  Future<void> getFaultLog() async {
    final q = encodeCapLogQuery(
      fromTimestamp: _initialQueryTimestamp,
      limit: 255,
    );
    final req = encodeRequestGetCapFaultLog(q);
    await _sendRequest(CapBleRequestType.getCapFaultLog, req);
  }

  Future<void> getChargingAdcLog() async {
    final q = encodeCapLogQuery(
      fromTimestamp: _initialQueryTimestamp,
      limit: 255,
    );
    final req = encodeRequestGetChargingCapAdcLog(q);
    await _sendRequest(CapBleRequestType.getChargingCapAdcLog, req);
  }

  Future<void> getActivationAdcLog() async {
    final q = encodeCapLogQuery(
      fromTimestamp: _initialQueryTimestamp,
      limit: 255,
    );
    final req = encodeRequestGetActivationCapAdcLog(q);
    await _sendRequest(CapBleRequestType.getActivationCapAdcLog, req);
  }

  Future<void> getTofLog() async {
    final query = encodeCapLogQuery(
      fromTimestamp: _initialQueryTimestamp,
      limit: 255,
    );
    final req = encodeRequestGetCapTofLog(query);
    await _sendRequest(CapBleRequestType.getCapTofLog, req);
  }

  static int get _initialQueryTimestamp {
    final t = DateTime.now().toUtc().subtract(const Duration(days: 7));
    return t.millisecondsSinceEpoch ~/ 1000;
  }

  Future<void> getTofState() async =>
      _sendRequest(CapBleRequestType.getCapTofState);
  Future<void> getBottleSensorState() async =>
      _sendRequest(CapBleRequestType.getCapBottleSensorState);
  Future<void> getUiState() async =>
      _sendRequest(CapBleRequestType.getCapUiState);
  Future<void> getSipSensorState() async =>
      _sendRequest(CapBleRequestType.getCapSipSensorState);
  Future<void> getAccelerometerState() async =>
      _sendRequest(CapBleRequestType.getCapAccelerometerState);
  Future<void> getAmbientLightSensorState() async =>
      _sendRequest(CapBleRequestType.getCapAmbientLightSensorState);
  Future<void> getHallEffectSensorState() async =>
      _sendRequest(CapBleRequestType.getCapHallEffectSensorState);

  Future<void> startPurification() async {
    final payload = encodeRequestSetCapUvActivate(
      CapEnumUvActivationMode.standard,
    );
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

  Future<void> factoryReset() async =>
      _sendRequest(CapBleRequestType.factoryReset);
  Future<void> enterDfuMode() async =>
      _sendRequest(CapBleRequestType.enterDfuMode);

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
        print('[SES:$_logId] Battery GATT: $_batteryLevel%');
      }
    } catch (e) {
      print('[SES:$_logId] Battery read failed: $e');
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

  // --- Log merge ---

  int _mergeLogList<T extends dynamic>(List<T> existing, List<T> newEntries) {
    int added = 0;
    for (final entry in newEntries) {
      final newTs = (entry as dynamic).timestamp as int;
      final exists = existing.any((e) => (e as dynamic).timestamp == newTs);
      if (!exists) {
        existing.add(entry);
        added++;
      }
    }
    return added;
  }

  // --- Paginated loading ---

  Future<void> loadMoreTofLogs() async {
    final fromTs = tofLogs.isEmpty
        ? 0
        : tofLogs.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b) + 1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetCapTofLog(q);
    await _sendRequest(CapBleRequestType.getCapTofLog, req);
  }

  Future<void> loadMoreActivationLogs() async {
    final fromTs = activationLogs.isEmpty
        ? 0
        : activationLogs
                  .map((e) => e.timestamp)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetCapActivationLog(q);
    await _sendRequest(CapBleRequestType.getCapActivationLog, req);
  }

  Future<void> loadMoreFaultLogs() async {
    final fromTs = faultLogs.isEmpty
        ? 0
        : faultLogs.map((e) => e.timestamp).reduce((a, b) => a > b ? a : b) +
              1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetCapFaultLog(q);
    await _sendRequest(CapBleRequestType.getCapFaultLog, req);
  }

  Future<void> loadMoreActivationAdcLogs() async {
    final fromTs = activationAdcLogs.isEmpty
        ? 0
        : activationAdcLogs
                  .map((e) => e.timestamp)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetActivationCapAdcLog(q);
    await _sendRequest(CapBleRequestType.getActivationCapAdcLog, req);
  }

  Future<void> loadMoreChargingAdcLogs() async {
    final fromTs = chargingAdcLogs.isEmpty
        ? 0
        : chargingAdcLogs
                  .map((e) => e.timestamp)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final q = encodeCapLogQuery(fromTimestamp: fromTs, limit: 255);
    final req = encodeRequestGetChargingCapAdcLog(q);
    await _sendRequest(CapBleRequestType.getChargingCapAdcLog, req);
  }

  // --- Auto-paging ---

  void _autoPageTofLogs() {
    Future.microtask(() async {
      try {
        await loadMoreTofLogs();
      } catch (e) {
        print('[SES:$_logId] autoPage tof failed: $e');
      }
    });
  }

  void _autoPageTofLogsHigh() {
    Future.microtask(() async {
      try {
        await jumpToLatestTofLogs();
      } catch (e) {
        print('[SES:$_logId] jumpToLatest failed: $e');
      }
    });
  }

  void _autoPageActivationLogs() {
    Future.microtask(() async {
      try {
        await loadMoreActivationLogs();
      } catch (e) {
        print('[SES:$_logId] autoPage activation failed: $e');
      }
    });
  }

  void _autoPageFaultLogs() {
    Future.microtask(() async {
      try {
        await loadMoreFaultLogs();
      } catch (e) {
        print('[SES:$_logId] autoPage fault failed: $e');
      }
    });
  }

  void _autoPageActivationAdcLogs() {
    Future.microtask(() async {
      try {
        await loadMoreActivationAdcLogs();
      } catch (e) {
        print('[SES:$_logId] autoPage act adc failed: $e');
      }
    });
  }

  void _autoPageChargingAdcLogs() {
    Future.microtask(() async {
      try {
        await loadMoreChargingAdcLogs();
      } catch (e) {
        print('[SES:$_logId] autoPage chg adc failed: $e');
      }
    });
  }

  // --- Poll loop ---

  void _startPoll() {
    if (_polling || !_connected) return;
    _pollSeq++;
    _scheduleNextPoll();
  }

  void _stopPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _polling = false;
    _pollSeq++;
    _pollItemController.add(null);
    for (final c in _pendingRequests.values) {
      c.completeError('Disconnected');
    }
    _pendingRequests.clear();
    print('[SES:$_logId] _stopPoll seq=$_pollSeq pending=${_pendingRequests.length}');
  }

  Future<void> _runPoll() async {
    if (_polling || !_connected) return;
    _polling = true;
    _pollSeq++;
    final seq = _pollSeq;
    final start = DateTime.now();

    try {
      await _pollItem('ToF Log', getTofLog);
      if (!_jumpedToLatest && tofLogs.isNotEmpty && _connected) {
        _jumpedToLatest = true;
        final nowUtc = DateTime.now().toUtc();
        final highTs =
            nowUtc.add(const Duration(days: 365)).millisecondsSinceEpoch ~/
            1000;
        print('[SES:$_logId] Poll: sending high-TS jump query (ts=$highTs)');
        final q = encodeCapLogQuery(fromTimestamp: highTs, limit: 255);
        final req = encodeRequestGetCapTofLog(q);
        await _sendRequest(CapBleRequestType.getCapTofLog, req);
      }
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

  void resetState() {
    _stopPoll();
    bottleSensorState = null;
    sipSensorState = null;
    tofState = null;
    accelerometerState = null;
    ambientLightState = null;
    hallEffectState = null;
    uiState = CapEnumUiState.allOff;
    powerSavingMode = CapPowerSavingMode.off;
    tofLogs = [];
    activationLogs = [];
    faultLogs = [];
    activationAdcLogs = [];
    chargingAdcLogs = [];
    _batteryCharacteristic = null;
    _tofAutoPages = 0;
    _actAutoPages = 0;
    _faultAutoPages = 0;
    _actAdcAutoPages = 0;
    _chgAdcAutoPages = 0;
    _jumpedToLatest = false;
  }

  void dispose() {
    print('[SES:$_logId] dispose called');
    _stopPoll();
    _pollItemController.close();
    _notificationSubscription?.cancel();
    _responseController.close();
    _connectionController.close();
    disconnect().then((_) => print('[SES:$_logId] dispose disconnect done'));
  }
}

// --- LarqResponse (moved here, tagged with remoteId) ---

class LarqResponse {
  final LarqResponseType type;
  final dynamic data;
  final String remoteId;

  const LarqResponse._(this.type, this.data, this.remoteId);

  factory LarqResponse.tofLog(List<CapTofLog> logs, String remoteId) =>
      LarqResponse._(LarqResponseType.tofLog, logs, remoteId);
  factory LarqResponse.tofState(CapTofState state, String remoteId) =>
      LarqResponse._(LarqResponseType.tofState, state, remoteId);
  factory LarqResponse.bottleSensorState(
    CapBottleSensorState state,
    String remoteId,
  ) =>
      LarqResponse._(LarqResponseType.bottleSensorState, state, remoteId);
  factory LarqResponse.sipSensorState(
    CapSipSensorState state,
    String remoteId,
  ) =>
      LarqResponse._(LarqResponseType.sipSensorState, state, remoteId);
  factory LarqResponse.accelerometerState(
    CapAccelerometerState state,
    String remoteId,
  ) =>
      LarqResponse._(LarqResponseType.accelerometerState, state, remoteId);
  factory LarqResponse.ambientLightState(
    CapAmbientLightSensorState state,
    String remoteId,
  ) =>
      LarqResponse._(LarqResponseType.ambientLightState, state, remoteId);
  factory LarqResponse.hallEffectState(
    CapHallEffectSensorState state,
    String remoteId,
  ) =>
      LarqResponse._(LarqResponseType.hallEffectState, state, remoteId);
  factory LarqResponse.uiState(
    CapEnumUiState state,
    CapPowerSavingMode powerSaving,
    String remoteId,
  ) =>
      LarqResponse._(LarqResponseType.uiState, (
        state: state,
        powerSaving: powerSaving,
      ), remoteId);
  factory LarqResponse.activationLog(
    List<CapActivationLog> logs,
    String remoteId,
  ) =>
      LarqResponse._(LarqResponseType.activationLog, logs, remoteId);
  factory LarqResponse.faultLog(List<CapFaultLog> logs, String remoteId) =>
      LarqResponse._(LarqResponseType.faultLog, logs, remoteId);
  factory LarqResponse.error(String message, String remoteId) =>
      LarqResponse._(LarqResponseType.error, message, remoteId);
}

enum LarqResponseType {
  tofLog,
  tofState,
  bottleSensorState,
  sipSensorState,
  accelerometerState,
  ambientLightState,
  hallEffectState,
  uiState,
  activationLog,
  faultLog,
  error,
}
