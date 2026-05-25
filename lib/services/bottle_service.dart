import 'dart:async';
import 'dart:typed_data';

import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart' show Any;

import 'package:bottle/protos/cap.pb.dart';
import 'package:bottle/services/bottle_connection.dart';
import 'package:bottle/models/bottle_device.dart';

class BottleService {
  final BottleConnection _connection;
  int _nextRequestId = 0;
  final _pending = <int, Completer<CapBleResponse>>{};
  final _buffer = <int>[];
  Timer? _reassemblyTimer;

  BottleService(this._connection);

  Uint8List _encodeLogQuery({required int fromTimestamp, int limit = 8}) {
    final buf = <int>[];
    buf.add(0x08);
    var v = fromTimestamp;
    while (v > 0x7F) {
      buf.add((v & 0x7F) | 0x80);
      v = v >>> 7;
    }
    buf.add(v & 0x7F);
    buf.add(0x15);
    buf.addAll([
      limit & 0xFF,
      (limit >> 8) & 0xFF,
      (limit >> 16) & 0xFF,
      (limit >> 24) & 0xFF,
    ]);
    print('[BTL] _encodeLogQuery from=$fromTimestamp limit=$limit => '
        '${buf.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');
    return Uint8List.fromList(buf);
  }

  Uint8List _encodeLogRequest({required int fromTimestamp, int limit = 8}) {
    final query = _encodeLogQuery(fromTimestamp: fromTimestamp, limit: limit);
    final buf = <int>[];
    buf.add(0x0a);
    var len = query.length;
    while (len > 0x7F) {
      buf.add((len & 0x7F) | 0x80);
      len = len >>> 7;
    }
    buf.add(len & 0x7F);
    buf.addAll(query);
    return Uint8List.fromList(buf);
  }

  void onResponse(List<int> data) {
    print('[BTL] onResponse ${data.length} bytes: '
        '${data.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');
    _buffer.addAll(data);

    _reassemblyTimer?.cancel();
    _reassemblyTimer = Timer(const Duration(milliseconds: 200), () {
      final bytes = Uint8List.fromList(List.of(_buffer));
      _buffer.clear();

      CapBleResponse response;
      try {
        response = CapBleResponse.fromBuffer(bytes);
      } catch (e) {
        print('[BTL] failed to parse response: $e');
        return;
      }

      final completer = _pending.remove(response.requestId);
      if (completer == null) return;
      completer.complete(response);
    });
  }

  Future<CapBleResponse> _sendRequest(CapBleRequest request) async {
    final requestId = ++_nextRequestId;
    request.requestId = requestId;

    final completer = Completer<CapBleResponse>();
    _pending[requestId] = completer;

    final bytes = Uint8List.fromList(request.writeToBuffer());
    print('[BTL] _sendRequest id=$requestId '
        '${bytes.length} bytes: '
        '${bytes.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');
    await _connection.txChar!.write(
      bytes,
      withoutResponse: true,
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Request $requestId timed out'),
    );
  }

  Future<T> _sendGetter<T>({
    required String typeUrl,
    required Uint8List body,
    required T Function(CapBleResponse) decoder,
  }) async {
    final request = CapBleRequest()
      ..body = (Any()
        ..typeUrl = typeUrl
        ..value = body);

    final response = await _sendRequest(request);

    print('[BTL] _sendGetter typeUrl=$typeUrl code=${response.code} '
        'bodySize=${response.body.value.length}');
    print('[BTL]   body hex=${response.body.value.map((b) => b.toRadixString(16).padLeft(2, "0")).join(" ")}');

    if (response.code != CapEnumResponseCode.SUCCESS) {
      throw Exception('Request failed: code=${response.code} typeUrl=$typeUrl');
    }

    return decoder(response);
  }

  Future<CapUiStateData> getUiState() async {
    final req = RequestGetCapUiState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapUiState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapUiState.fromBuffer(r.body.value);
        return CapUiStateData(
          state: data.state,
          powerSavingMode: data.powerSavingMode,
        );
      },
    );
  }

  Future<int> getTofDistance() async {
    final req = RequestGetCapTofState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapTofState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapTofState.fromBuffer(r.body.value);
        return data.state.distanceInMillimeter;
      },
    );
  }

  Future<int> getSipCounter() async {
    final req = RequestGetCapSipSensorState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapSipSensorState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapSipSensorState.fromBuffer(r.body.value);
        return data.state.value;
      },
    );
  }

  Future<HallEffectData> getHallEffect() async {
    final req = RequestGetCapHallEffectSensorState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapHallEffectSensorState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapHallEffectSensorState.fromBuffer(r.body.value);
        return HallEffectData(
          timestamp: data.state.timestamp.toInt(),
          value: data.state.value,
        );
      },
    );
  }

  Future<bool> getBottlePresent() async {
    final req = RequestGetCapBottleSensorState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapBottleSensorState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapBottleSensorState.fromBuffer(r.body.value);
        return data.state.state;
      },
    );
  }

  Future<double> getAmbientLight() async {
    final req = RequestGetCapAmbientLightSensorState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapAmbientLightSensorState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapAmbientLightSensorState.fromBuffer(r.body.value);
        return data.state.value;
      },
    );
  }

  Future<AccelData> getAccelerometer() async {
    final req = RequestGetCapAccelerometerState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapAccelerometerState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapAccelerometerState.fromBuffer(r.body.value);
        return AccelData(x: data.state.x, y: data.state.y, z: data.state.z);
      },
    );
  }

  Future<int> getBatteryLevel() async {
    if (_connection.batteryChar == null) throw StateError('Battery characteristic not found');
    final raw = await _connection.batteryChar!.read();
    return raw[0];
  }

  Future<DeviceInfo> getDeviceInfo() async {
    String model = '';
    String fw = '';
    if (_connection.modelNumberChar != null) {
      model = String.fromCharCodes(await _connection.modelNumberChar!.read());
    }
    if (_connection.firmwareRevChar != null) {
      fw = String.fromCharCodes(await _connection.firmwareRevChar!.read());
    }
    return DeviceInfo(model: model, firmware: fw);
  }

  Future<List<CapTofLog>> getTofLogPage({
    required int fromTimestamp,
    int limit = 7,
  }) async {
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapTofLog',
      body: _encodeLogRequest(fromTimestamp: fromTimestamp, limit: limit),
      decoder: (r) {
        final data = ResponseGetCapTofLog.fromBuffer(r.body.value);
        final items = data.items.where((e) => e.timestamp.toInt() >= 1000).toList();
        print('[BTL] getTofLogPage from=$fromTimestamp got ${items.length} items');
        return items;
      },
    );
  }

  Future<List<CapActivationLog>> getActivationLogPage({
    required int fromTimestamp,
    int limit = 8,
  }) async {
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapActivationLog',
      body: _encodeLogRequest(fromTimestamp: fromTimestamp, limit: limit),
      decoder: (r) {
        final data = ResponseGetCapActivationLog.fromBuffer(r.body.value);
        print('[BTL] getActivationLogPage from=$fromTimestamp got ${data.items.length} items');
        return data.items;
      },
    );
  }

  Future<List<CapFaultLog>> getFaultLogPage({
    required int fromTimestamp,
    int limit = 8,
  }) async {
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapFaultLog',
      body: _encodeLogRequest(fromTimestamp: fromTimestamp, limit: limit),
      decoder: (r) {
        final data = ResponseGetCapFaultLog.fromBuffer(r.body.value);
        print('[BTL] getFaultLogPage from=$fromTimestamp got ${data.items.length} items');
        return data.items;
      },
    );
  }

  Future<List<CapStateLog>> getStateLogPage({
    required int fromTimestamp,
    int limit = 6,
  }) async {
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapStateLog',
      body: _encodeLogRequest(fromTimestamp: fromTimestamp, limit: limit),
      decoder: (r) {
        final data = ResponseGetCapStateLog.fromBuffer(r.body.value);
        print('[BTL] getStateLogPage from=$fromTimestamp got ${data.items.length} items');
        return data.items;
      },
    );
  }

  Future<List<CapAdcLog>> getActivationAdcLogPage({
    required int fromTimestamp,
    int limit = 5,
  }) async {
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetActivationCapAdcLog',
      body: _encodeLogRequest(fromTimestamp: fromTimestamp, limit: limit),
      decoder: (r) {
        final data = ResponseGetActivationCapAdcLog.fromBuffer(r.body.value);
        print('[BTL] getActivationAdcLogPage from=$fromTimestamp got ${data.items.length} items');
        return data.items;
      },
    );
  }

  Future<List<CapAdcLog>> getChargingAdcLogPage({
    required int fromTimestamp,
    int limit = 5,
  }) async {
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetChargingCapAdcLog',
      body: _encodeLogRequest(fromTimestamp: fromTimestamp, limit: limit),
      decoder: (r) {
        final data = ResponseGetChargingCapAdcLog.fromBuffer(r.body.value);
        print('[BTL] getChargingAdcLogPage from=$fromTimestamp got ${data.items.length} items');
        return data.items;
      },
    );
  }
}

