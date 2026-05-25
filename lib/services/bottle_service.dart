import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart' show Any;

import 'package:bottle/protos/cap.pb.dart';
import 'package:bottle/services/bottle_connection.dart';
import 'package:bottle/models/bottle_device.dart';

class BottleService {
  final BottleConnection _connection;
  int _nextRequestId = 0;
  final _pending = <int, Completer<CapBleResponse>>{};

  BottleService(this._connection);

  void onResponse(List<int> data) {
    final response = CapBleResponse.fromBuffer(data);
    final completer = _pending.remove(response.requestId);
    if (completer == null) return;
    completer.complete(response);
  }

  Future<CapBleResponse> _sendRequest(Uint8List writtenBytes) async {
    final requestId = _nextRequestId++;

    final bytes = Uint8List(writtenBytes.length);
    bytes.setAll(0, writtenBytes);
    bytes[1] = (requestId >> 0) & 0xFF;
    bytes[2] = (requestId >> 8) & 0xFF;
    bytes[3] = (requestId >> 16) & 0xFF;
    bytes[4] = (requestId >> 24) & 0xFF;

    final completer = Completer<CapBleResponse>();
    _pending[requestId] = completer;

    await _connection.txChar!.write(bytes, withoutResponse: false);

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

    final response = await _sendRequest(
      Uint8List.fromList(request.writeToBuffer()));

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
        return data.distanceInMillimeter;
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
        return data.value;
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
          timestamp: data.timestamp.toInt(),
          value: data.value,
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
        return data.state;
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
        return data.value;
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
        return AccelData(x: data.x, y: data.y, z: data.z);
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
    int limit = 8,
  }) async {
    final query = CapLogQuery()
      ..fromTimestamp = Int64(fromTimestamp)
      ..limit = limit
      ..algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP;

    final req = RequestGetCapTofLog()..query = query;
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapTofLog',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapTofLog.fromBuffer(r.body.value);
        return data.entries.where((e) => e.timestamp.toInt() >= 1000).toList();
      },
    );
  }

  Future<List<CapActivationLog>> getActivationLogPage({
    required int fromTimestamp,
    int limit = 8,
  }) async {
    final query = CapLogQuery()
      ..fromTimestamp = Int64(fromTimestamp)
      ..limit = limit
      ..algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP;

    final req = RequestGetCapActivationLog()..query = query;
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapActivationLog',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapActivationLog.fromBuffer(r.body.value);
        return data.entries;
      },
    );
  }

  Future<List<CapFaultLog>> getFaultLogPage({
    required int fromTimestamp,
    int limit = 8,
  }) async {
    final query = CapLogQuery()
      ..fromTimestamp = Int64(fromTimestamp)
      ..limit = limit
      ..algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP;

    final req = RequestGetCapFaultLog()..query = query;
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapFaultLog',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapFaultLog.fromBuffer(r.body.value);
        return data.entries;
      },
    );
  }

  Future<List<CapStateLog>> getStateLogPage({
    required int fromTimestamp,
    int limit = 8,
  }) async {
    final query = CapLogQuery()
      ..fromTimestamp = Int64(fromTimestamp)
      ..limit = limit
      ..algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP;

    final req = RequestGetCapStateLog()..query = query;
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapStateLog',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapStateLog.fromBuffer(r.body.value);
        return data.entries;
      },
    );
  }

  Future<List<CapAdcLog>> getActivationAdcLogPage({
    required int fromTimestamp,
    int limit = 8,
  }) async {
    final query = CapLogQuery()
      ..fromTimestamp = Int64(fromTimestamp)
      ..limit = limit
      ..algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP;

    final req = RequestGetActivationCapAdcLog()..query = query;
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetActivationCapAdcLog',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetActivationCapAdcLog.fromBuffer(r.body.value);
        return data.entries;
      },
    );
  }

  Future<List<CapAdcLog>> getChargingAdcLogPage({
    required int fromTimestamp,
    int limit = 8,
  }) async {
    final query = CapLogQuery()
      ..fromTimestamp = Int64(fromTimestamp)
      ..limit = limit
      ..algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP;

    final req = RequestGetChargingCapAdcLog()..query = query;
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetChargingCapAdcLog',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetChargingCapAdcLog.fromBuffer(r.body.value);
        return data.entries;
      },
    );
  }
}
