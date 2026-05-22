// Protobuf wire-format encoder/decoder for LARQ PureVis 2 protocol.
// Based on cap_ble.proto v1.12 — field types verified against schema.

import 'dart:typed_data';
import '../models/larq_protocol.dart';

// --- Wire format helpers ---

class _PbWriter {
  final _buf = <int>[];
  Uint8List toBytes() => Uint8List.fromList(_buf);

  void _writeVarint(int value) {
    var v = value;
    while (v > 0x7F) {
      _buf.add((v & 0x7F) | 0x80);
      v = v >>> 7;
    }
    _buf.add(v & 0x7F);
  }

  void _writeTag(int fieldNumber, int wireType) {
    _writeVarint((fieldNumber << 3) | wireType);
  }

  void writeFixed32(int fieldNumber, int value) {
    _writeTag(fieldNumber, 5);
    final bytes = ByteData(4)..setUint32(0, value, Endian.little);
    _buf.addAll(bytes.buffer.asUint8List());
  }

  void writeVarint32(int fieldNumber, int value) {
    if (value == 0) return;
    _writeTag(fieldNumber, 0);
    _writeVarint(value);
  }

  void writeUint64(int fieldNumber, int value) {
    if (value == 0) return;
    _writeTag(fieldNumber, 0);
    _writeVarint(value);
  }

  void writeSint32(int fieldNumber, int value) {
    if (value == 0) return;
    // Zigzag encode: (n << 1) ^ (n >> 31)
    final zigzag = (value << 1) ^ (value >> 31);
    _writeTag(fieldNumber, 0);
    _writeVarint(zigzag);
  }

  void writeBool(int fieldNumber, bool value) {
    if (!value) return;
    _writeTag(fieldNumber, 0);
    _writeVarint(1);
  }

  void writeFloat(int fieldNumber, double value) {
    if (value == 0.0) return;
    _writeTag(fieldNumber, 5);
    final bytes = ByteData(4)..setFloat32(0, value, Endian.little);
    _buf.addAll(bytes.buffer.asUint8List());
  }

  void writeBytes(int fieldNumber, List<int> data) {
    if (data.isEmpty) return;
    _writeTag(fieldNumber, 2);
    _writeVarint(data.length);
    _buf.addAll(data);
  }

  void writeString(int fieldNumber, String value) {
    if (value.isEmpty) return;
    writeBytes(fieldNumber, value.codeUnits);
  }

  void writeMessage(int fieldNumber, List<int> data) {
    writeBytes(fieldNumber, data);
  }
}

class _PbReader {
  final Uint8List _data;
  int _pos = 0;
  _PbReader(this._data);
  bool get isDone => _pos >= _data.length;

  int _readByte() => _data[_pos++];
  int _peekByte() => _data[_pos];

  int _readVarint() {
    int result = 0;
    int shift = 0;
    while (_pos < _data.length) {
      final b = _data[_pos++];
      result |= (b & 0x7F) << shift;
      if ((b & 0x80) == 0) break;
      shift += 7;
    }
    return result;
  }

  ({int fieldNumber, int wireType}) readField() {
    if (isDone) return (fieldNumber: 0, wireType: -1);
    final tag = _readVarint();
    return (fieldNumber: tag >> 3, wireType: tag & 0x7);
  }

  int readFixed32() {
    final bytes = _data.sublist(_pos, _pos + 4);
    _pos += 4;
    return ByteData.sublistView(bytes).getUint32(0, Endian.little);
  }

  int readInt32() => _readVarint();
  int readUint64() => _readVarint();
  bool readBool() => _readVarint() != 0;
  double readFloat() {
    final bytes = _data.sublist(_pos, _pos + 4);
    _pos += 4;
    return ByteData.sublistView(bytes).getFloat32(0, Endian.little);
  }

  int readSint32() {
    // Zigzag decode: (n >>> 1) ^ -(n & 1)
    final n = _readVarint();
    return (n >>> 1) ^ -(n & 1);
  }

  Uint8List readBytes() {
    final len = _readVarint();
    final result = _data.sublist(_pos, _pos + len);
    _pos += len;
    return result;
  }

  String readString() => String.fromCharCodes(readBytes());
  Uint8List readMessage() => readBytes();

  void skipField(int wireType) {
    switch (wireType) {
      case 0: _readVarint(); break; // varint
      case 1: _pos += 8; break; // 64-bit
      case 2: _pos += _readVarint(); break; // length-delimited
      case 5: _pos += 4; break; // 32-bit
    }
  }
}

// --- Encode CapBleRequest ---
// CapBleRequest: fixed32 requestId=1; Any body=2;
// Any: string type_url=1; bytes value=2;

Uint8List encodeCapBleRequest(int requestId, CapBleRequestType type,
    [List<int>? payloadBytes]) {
  final w = _PbWriter();
  w.writeFixed32(1, requestId);

  final anyW = _PbWriter();
  anyW.writeString(1, requestTypeUrls[type]!);
  if (payloadBytes != null && payloadBytes.isNotEmpty) {
    anyW.writeBytes(2, payloadBytes);
  }
  w.writeBytes(2, anyW.toBytes());

  return w.toBytes();
}

// --- Decode CapBleResponse ---
// CapBleResponse: fixed32 requestId=1; CapEnumResponseCode code=2; Any body=3;

({int requestId, CapEnumResponseCode code, String? typeUrl,
    Uint8List? bodyData}) decodeCapBleResponse(Uint8List data) {
  final r = _PbReader(data);
  int requestId = 0;
  CapEnumResponseCode code = CapEnumResponseCode.fail;
  String? typeUrl;
  Uint8List? bodyData;

  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    switch (f.fieldNumber) {
      case 1: requestId = r.readFixed32(); break;
      case 2: code = CapEnumResponseCode.fromValue(r.readInt32()); break;
      case 3:
        final anyData = r.readMessage();
        final ar = _PbReader(anyData);
        while (!ar.isDone) {
          final af = ar.readField();
          if (af.wireType < 0) break;
          switch (af.fieldNumber) {
            case 1: typeUrl = ar.readString(); break;
            case 2: bodyData = ar.readBytes(); break;
            default: ar.skipField(af.wireType);
          }
        }
        // If no value bytes were present but body is expected, use empty data
        bodyData ??= Uint8List(0);
        break;
      default: r.skipField(f.wireType);
    }
  }

  return (requestId: requestId, code: code, typeUrl: typeUrl, bodyData: bodyData);
}

// --- Decode individual response payloads ---

// CapTofLog: uint64 timestamp=1; enum triggerType=2; fixed32 distanceInMillimeter=3; fixed32 kcps=4; float uvLedTempInOhm=5;
CapTofLog _decodeCapTofLog(Uint8List data) {
  final r = _PbReader(data);
  int timestamp = 0, triggerTypeVal = 0, distanceMm = 0, kcps = 0;
  double uvLedTemp = 0.0;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    switch (f.fieldNumber) {
      case 1: timestamp = r.readUint64(); break;
      case 2: triggerTypeVal = r.readInt32(); break;
      case 3: distanceMm = r.readFixed32(); break;
      case 4: kcps = r.readFixed32(); break;
      case 5: uvLedTemp = r.readFloat(); break;
      default: r.skipField(f.wireType);
    }
  }
  return CapTofLog(
    timestamp: timestamp,
    triggerType: CapEnumTofTriggerType.fromValue(triggerTypeVal),
    distanceInMillimeter: distanceMm,
    kcps: kcps,
    uvLedTempInOhm: uvLedTemp,
  );
}

// ResponseGetCapTofLog: repeated CapTofLog items=1;
List<CapTofLog> decodeResponseGetCapTofLog(Uint8List data) {
  final r = _PbReader(data);
  final items = <CapTofLog>[];
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) items.add(_decodeCapTofLog(r.readMessage()));
    else r.skipField(f.wireType);
  }
  return items;
}

// CapTofState: fixed32 distanceInMillimeter=1; fixed32 kcps=2;
CapTofState _decodeCapTofState(Uint8List data) {
  final r = _PbReader(data);
  int dist = 0, kcps = 0;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    switch (f.fieldNumber) {
      case 1: dist = r.readFixed32(); break;
      case 2: kcps = r.readFixed32(); break;
      default: r.skipField(f.wireType);
    }
  }
  return CapTofState(distanceInMillimeter: dist, kcps: kcps);
}

// ResponseGetCapTofState: CapTofState state=1;
CapTofState decodeResponseGetCapTofState(Uint8List data) {
  final r = _PbReader(data);
  CapTofState? result;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) result = _decodeCapTofState(r.readMessage());
    else r.skipField(f.wireType);
  }
  return result ?? CapTofState(distanceInMillimeter: 0, kcps: 0);
}

// CapBottleSensorState: sint32 value=1; bool state=2;
CapBottleSensorState _decodeCapBottleSensorState(Uint8List data) {
  final r = _PbReader(data);
  int val = 0; bool state = false;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    switch (f.fieldNumber) {
      case 1: val = r.readSint32(); break;
      case 2: state = r.readBool(); break;
      default: r.skipField(f.wireType);
    }
  }
  return CapBottleSensorState(value: val, state: state);
}

CapBottleSensorState decodeResponseGetCapBottleSensorState(Uint8List data) {
  final r = _PbReader(data);
  CapBottleSensorState? result;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) result = _decodeCapBottleSensorState(r.readMessage());
    else r.skipField(f.wireType);
  }
  return result ?? CapBottleSensorState(value: 0, state: false);
}

// CapSipSensorState: sint32 value=1; bool state=2;
CapSipSensorState _decodeCapSipSensorState(Uint8List data) {
  final r = _PbReader(data);
  int val = 0; bool state = false;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    switch (f.fieldNumber) {
      case 1: val = r.readSint32(); break;
      case 2: state = r.readBool(); break;
      default: r.skipField(f.wireType);
    }
  }
  return CapSipSensorState(value: val, state: state);
}

CapSipSensorState decodeResponseGetCapSipSensorState(Uint8List data) {
  final r = _PbReader(data);
  CapSipSensorState? result;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) result = _decodeCapSipSensorState(r.readMessage());
    else r.skipField(f.wireType);
  }
  return result ?? CapSipSensorState(value: 0, state: false);
}

// CapAccelerometerState: float x=1; float y=2; float z=3;
CapAccelerometerState decodeResponseGetCapAccelerometerState(Uint8List data) {
  final r = _PbReader(data);
  double x = 0, y = 0, z = 0;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) {
      final inner = _PbReader(r.readMessage());
      while (!inner.isDone) {
        final fi = inner.readField();
        if (fi.wireType < 0) break;
        switch (fi.fieldNumber) {
          case 1: x = inner.readFloat(); break;
          case 2: y = inner.readFloat(); break;
          case 3: z = inner.readFloat(); break;
          default: inner.skipField(fi.wireType);
        }
      }
    } else { r.skipField(f.wireType); }
  }
  return CapAccelerometerState(x: x, y: y, z: z);
}

// ResponseGetCapUiState: CapEnumUiState state=1; CapPowerSavingMode powerSavingMode=2;
({CapEnumUiState state, CapPowerSavingMode powerSavingMode})
    decodeResponseGetCapUiState(Uint8List data) {
  final r = _PbReader(data);
  int stateVal = 0, psmVal = -1;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    switch (f.fieldNumber) {
      case 1: stateVal = r.readInt32(); break;
      case 2: psmVal = r.readInt32(); break;
      default: r.skipField(f.wireType);
    }
  }
  return (
    state: CapEnumUiState.fromValue(stateVal),
    powerSavingMode: psmVal == 0 ? CapPowerSavingMode.on : CapPowerSavingMode.off,
  );
}

// CapActivationLog: uint64 timestamp=1; enum mode=2; fixed32 batterySocInPercentage=3;
List<CapActivationLog> decodeResponseGetCapActivationLog(Uint8List data) {
  final r = _PbReader(data);
  final items = <CapActivationLog>[];
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) {
      final inner = _PbReader(r.readMessage());
      int ts = 0, modeV = 0, batt = 0;
      while (!inner.isDone) {
        final fi = inner.readField();
        if (fi.wireType < 0) break;
        switch (fi.fieldNumber) {
          case 1: ts = inner.readUint64(); break;
          case 2: modeV = inner.readInt32(); break;
          case 3: batt = inner.readFixed32(); break;
          default: inner.skipField(fi.wireType);
        }
      }
      items.add(CapActivationLog(
        timestamp: ts,
        mode: CapEnumUvActivationMode.values
            .firstWhere((e) => e.value == modeV,
                orElse: () => CapEnumUvActivationMode.standard),
        batterySocInPercentage: batt,
      ));
    } else { r.skipField(f.wireType); }
  }
  return items;
}

// CapFaultLog: uint64 timestamp=1; enum type=2;
List<CapFaultLog> decodeResponseGetCapFaultLog(Uint8List data) {
  final r = _PbReader(data);
  final items = <CapFaultLog>[];
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) {
      final inner = _PbReader(r.readMessage());
      int ts = 0, tv = 0;
      while (!inner.isDone) {
        final fi = inner.readField();
        if (fi.wireType < 0) break;
        switch (fi.fieldNumber) {
          case 1: ts = inner.readUint64(); break;
          case 2: tv = inner.readInt32(); break;
          default: inner.skipField(fi.wireType);
        }
      }
      items.add(CapFaultLog(timestamp: ts, type: CapEnumFaultType.fromValue(tv)));
    } else { r.skipField(f.wireType); }
  }
  return items;
}

// CapAdcLog: uint64 timestamp=1; float batteryVoltage=2; fixed32 batterySocInPercentage=3;
List<CapAdcLog> _decodeCapAdcLogList(Uint8List data) {
  final r = _PbReader(data);
  final items = <CapAdcLog>[];
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) {
      final inner = _PbReader(r.readMessage());
      int ts = 0;
      double v = 0;
      int soc = 0;
      while (!inner.isDone) {
        final fi = inner.readField();
        if (fi.wireType < 0) break;
        switch (fi.fieldNumber) {
          case 1: ts = inner.readUint64(); break;
          case 2: v = inner.readFloat(); break;
          case 3: soc = inner.readFixed32(); break;
          default: inner.skipField(fi.wireType);
        }
      }
      items.add(CapAdcLog(
        timestamp: ts,
        batteryVoltage: v,
        batterySocInPercentage: soc,
      ));
    } else { r.skipField(f.wireType); }
  }
  return items;
}

List<CapAdcLog> decodeResponseGetActivationCapAdcLog(Uint8List data) {
  return _decodeCapAdcLogList(data);
}

List<CapAdcLog> decodeResponseGetChargingCapAdcLog(Uint8List data) {
  return _decodeCapAdcLogList(data);
}

// CapAmbientLightSensorState: float value=1;
CapAmbientLightSensorState decodeResponseGetCapAmbientLightSensorState(
    Uint8List data) {
  final r = _PbReader(data);
  double val = 0;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) {
      final inner = _PbReader(r.readMessage());
      while (!inner.isDone) {
        final fi = inner.readField();
        if (fi.wireType < 0) break;
        if (fi.fieldNumber == 1) val = inner.readFloat();
        else inner.skipField(fi.wireType);
      }
    } else { r.skipField(f.wireType); }
  }
  return CapAmbientLightSensorState(value: val.toInt());
}

// CapHallEffectSensorState: uint64 timestamp=1; bool value=2;
CapHallEffectSensorState decodeResponseGetCapHallEffectSensorState(
    Uint8List data) {
  final r = _PbReader(data);
  bool val = false;
  while (!r.isDone) {
    final f = r.readField();
    if (f.wireType < 0) break;
    if (f.fieldNumber == 1) {
      final inner = _PbReader(r.readMessage());
      while (!inner.isDone) {
        final fi = inner.readField();
        if (fi.wireType < 0) break;
        if (fi.fieldNumber == 2) val = inner.readBool();
        else inner.skipField(fi.wireType);
      }
    } else { r.skipField(f.wireType); }
  }
  return CapHallEffectSensorState(state: val);
}

// --- Encode specific SET requests ---

// RequestSetCapUvActivate: CapEnumUvActivationMode mode=1;
Uint8List encodeRequestSetCapUvActivate(CapEnumUvActivationMode mode) {
  final w = _PbWriter();
  w.writeVarint32(1, mode.value);
  return w.toBytes();
}

// RequestSetCapPowerSavingMode: CapPowerSavingMode mode=1;
Uint8List encodeRequestSetCapPowerSavingMode(CapPowerSavingMode mode) {
  final w = _PbWriter();
  // From proto: POWER_SAVING_MODE_ON=0, POWER_SAVING_MODE_OFF=1
  w.writeVarint32(1, mode == CapPowerSavingMode.off ? 1 : 0);
  return w.toBytes();
}

// CapLogQuery: uint64 fromTimestamp=1; fixed32 limit=2; enum algo=3;
Uint8List encodeCapLogQuery({int fromTimestamp = 0, int limit = 50}) {
  final w = _PbWriter();
  w.writeFixed32(2, limit);
  // algo: SEARCH_ALGO_TIMESTAMP=0 (default, not written)
  return w.toBytes();
}
