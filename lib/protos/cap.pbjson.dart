// This is a generated file - do not edit.
//
// Generated from protos/cap.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use capEnumResponseCodeDescriptor instead')
const CapEnumResponseCode$json = {
  '1': 'CapEnumResponseCode',
  '2': [
    {'1': 'FAIL', '2': 0},
    {'1': 'SUCCESS', '2': 1},
    {'1': 'NOT_SUPPORTED', '2': 2},
  ],
};

/// Descriptor for `CapEnumResponseCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List capEnumResponseCodeDescriptor = $convert.base64Decode(
    'ChNDYXBFbnVtUmVzcG9uc2VDb2RlEggKBEZBSUwQABILCgdTVUNDRVNTEAESEQoNTk9UX1NVUF'
    'BPUlRFRBAC');

@$core.Deprecated('Use capEnumLogQuerySearchAlgoDescriptor instead')
const CapEnumLogQuerySearchAlgo$json = {
  '1': 'CapEnumLogQuerySearchAlgo',
  '2': [
    {'1': 'SEARCH_ALGO_TIMESTAMP', '2': 0},
    {'1': 'SEARCH_ALGO_INCREMENT', '2': 1},
  ],
};

/// Descriptor for `CapEnumLogQuerySearchAlgo`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List capEnumLogQuerySearchAlgoDescriptor =
    $convert.base64Decode(
        'ChlDYXBFbnVtTG9nUXVlcnlTZWFyY2hBbGdvEhkKFVNFQVJDSF9BTEdPX1RJTUVTVEFNUBAAEh'
        'kKFVNFQVJDSF9BTEdPX0lOQ1JFTUVOVBAB');

@$core.Deprecated('Use capEnumTofTriggerTypeDescriptor instead')
const CapEnumTofTriggerType$json = {
  '1': 'CapEnumTofTriggerType',
  '2': [
    {'1': 'TYPE_REQUEST', '2': 0},
    {'1': 'TYPE_INTERVAL', '2': 1},
    {'1': 'TYPE_CAP', '2': 2},
    {'1': 'TYPE_CAP_ON_FLAP', '2': 3},
    {'1': 'TYPE_CAP_ON_FLAP_OPEN_SIP', '2': 4},
  ],
};

/// Descriptor for `CapEnumTofTriggerType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List capEnumTofTriggerTypeDescriptor = $convert.base64Decode(
    'ChVDYXBFbnVtVG9mVHJpZ2dlclR5cGUSEAoMVFlQRV9SRVFVRVNUEAASEQoNVFlQRV9JTlRFUl'
    'ZBTBABEgwKCFRZUEVfQ0FQEAISFAoQVFlQRV9DQVBfT05fRkxBUBADEh0KGVRZUEVfQ0FQX09O'
    'X0ZMQVBfT1BFTl9TSVAQBA==');

@$core.Deprecated('Use capEnumUvActivationModeDescriptor instead')
const CapEnumUvActivationMode$json = {
  '1': 'CapEnumUvActivationMode',
  '2': [
    {'1': 'UV_MAINTENANCE', '2': 0},
    {'1': 'UV_STANDARD', '2': 1},
    {'1': 'UV_ADVENTURE', '2': 2},
    {'1': 'UV_STOP', '2': 3},
  ],
};

/// Descriptor for `CapEnumUvActivationMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List capEnumUvActivationModeDescriptor =
    $convert.base64Decode(
        'ChdDYXBFbnVtVXZBY3RpdmF0aW9uTW9kZRISCg5VVl9NQUlOVEVOQU5DRRAAEg8KC1VWX1NUQU'
        '5EQVJEEAESEAoMVVZfQURWRU5UVVJFEAISCwoHVVZfU1RPUBAD');

@$core.Deprecated('Use capEnumFaultTypeDescriptor instead')
const CapEnumFaultType$json = {
  '1': 'CapEnumFaultType',
  '2': [
    {'1': 'UV_OVERTEMP', '2': 0},
    {'1': 'UV_LED_SHORT', '2': 1},
    {'1': 'UV_LED_OPEN', '2': 2},
    {'1': 'BATTERY_TEMP', '2': 3},
    {'1': 'BATTERY_OPEN', '2': 4},
    {'1': 'BATTERY_SHORT', '2': 5},
    {'1': 'AMBIENT_LIGHT', '2': 6},
  ],
};

/// Descriptor for `CapEnumFaultType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List capEnumFaultTypeDescriptor = $convert.base64Decode(
    'ChBDYXBFbnVtRmF1bHRUeXBlEg8KC1VWX09WRVJURU1QEAASEAoMVVZfTEVEX1NIT1JUEAESDw'
    'oLVVZfTEVEX09QRU4QAhIQCgxCQVRURVJZX1RFTVAQAxIQCgxCQVRURVJZX09QRU4QBBIRCg1C'
    'QVRURVJZX1NIT1JUEAUSEQoNQU1CSUVOVF9MSUdIVBAG');

@$core.Deprecated('Use capEnumUiStateDescriptor instead')
const CapEnumUiState$json = {
  '1': 'CapEnumUiState',
  '2': [
    {'1': 'UI_ON', '2': 0},
    {'1': 'UI_FAULT', '2': 1},
    {'1': 'UI_UV_MAINTENANCE', '2': 2},
    {'1': 'UI_UV_NORMAL', '2': 3},
    {'1': 'UI_UV_ADVENTURE', '2': 4},
    {'1': 'UI_PAIRED', '2': 5},
    {'1': 'UI_HYDRATION_REMINDER', '2': 6},
    {'1': 'UI_BATTERY_LOW', '2': 7},
    {'1': 'UI_CHARGING', '2': 8},
    {'1': 'UI_CHARGED', '2': 9},
    {'1': 'UI_UV_INTERLOCK', '2': 10},
    {'1': 'UI_BOTTLE_CALIBRATION', '2': 11},
    {'1': 'UI_TOF_MEASUREMENT', '2': 12},
    {'1': 'UI_TURN_OFF', '2': 13},
    {'1': 'UI_FACTORY_RESET', '2': 14},
    {'1': 'UI_ALL_OFF', '2': 15},
    {'1': 'UI_LOCKED', '2': 16},
    {'1': 'UI_QC', '2': 17},
    {'1': 'UI_LAST', '2': 18},
  ],
};

/// Descriptor for `CapEnumUiState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List capEnumUiStateDescriptor = $convert.base64Decode(
    'Cg5DYXBFbnVtVWlTdGF0ZRIJCgVVSV9PThAAEgwKCFVJX0ZBVUxUEAESFQoRVUlfVVZfTUFJTl'
    'RFTkFOQ0UQAhIQCgxVSV9VVl9OT1JNQUwQAxITCg9VSV9VVl9BRFZFTlRVUkUQBBINCglVSV9Q'
    'QUlSRUQQBRIZChVVSV9IWURSQVRJT05fUkVNSU5ERVIQBhISCg5VSV9CQVRURVJZX0xPVxAHEg'
    '8KC1VJX0NIQVJHSU5HEAgSDgoKVUlfQ0hBUkdFRBAJEhMKD1VJX1VWX0lOVEVSTE9DSxAKEhkK'
    'FVVJX0JPVFRMRV9DQUxJQlJBVElPThALEhYKElVJX1RPRl9NRUFTVVJFTUVOVBAMEg8KC1VJX1'
    'RVUk5fT0ZGEA0SFAoQVUlfRkFDVE9SWV9SRVNFVBAOEg4KClVJX0FMTF9PRkYQDxINCglVSV9M'
    'T0NLRUQQEBIJCgVVSV9RQxAREgsKB1VJX0xBU1QQEg==');

@$core.Deprecated('Use capPowerSavingModeDescriptor instead')
const CapPowerSavingMode$json = {
  '1': 'CapPowerSavingMode',
  '2': [
    {'1': 'POWER_SAVING_OFF', '2': 0},
    {'1': 'POWER_SAVING_ON', '2': 1},
    {'1': 'POWER_SAVING_AUTO', '2': 2},
  ],
};

/// Descriptor for `CapPowerSavingMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List capPowerSavingModeDescriptor = $convert.base64Decode(
    'ChJDYXBQb3dlclNhdmluZ01vZGUSFAoQUE9XRVJfU0FWSU5HX09GRhAAEhMKD1BPV0VSX1NBVk'
    'lOR19PThABEhUKEVBPV0VSX1NBVklOR19BVVRPEAI=');

@$core.Deprecated('Use capBleRequestDescriptor instead')
const CapBleRequest$json = {
  '1': 'CapBleRequest',
  '2': [
    {'1': 'requestId', '3': 1, '4': 1, '5': 7, '10': 'requestId'},
    {
      '1': 'body',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'body'
    },
  ],
};

/// Descriptor for `CapBleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capBleRequestDescriptor = $convert.base64Decode(
    'Cg1DYXBCbGVSZXF1ZXN0EhwKCXJlcXVlc3RJZBgBIAEoB1IJcmVxdWVzdElkEigKBGJvZHkYAi'
    'ABKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgRib2R5');

@$core.Deprecated('Use capBleResponseDescriptor instead')
const CapBleResponse$json = {
  '1': 'CapBleResponse',
  '2': [
    {'1': 'requestId', '3': 1, '4': 1, '5': 7, '10': 'requestId'},
    {
      '1': 'code',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapEnumResponseCode',
      '10': 'code'
    },
    {
      '1': 'body',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'body'
    },
  ],
};

/// Descriptor for `CapBleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capBleResponseDescriptor = $convert.base64Decode(
    'Cg5DYXBCbGVSZXNwb25zZRIcCglyZXF1ZXN0SWQYASABKAdSCXJlcXVlc3RJZBIvCgRjb2RlGA'
    'IgASgOMhsuYm90dGxlLkNhcEVudW1SZXNwb25zZUNvZGVSBGNvZGUSKAoEYm9keRgDIAEoCzIU'
    'Lmdvb2dsZS5wcm90b2J1Zi5BbnlSBGJvZHk=');

@$core.Deprecated('Use capLogQueryDescriptor instead')
const CapLogQuery$json = {
  '1': 'CapLogQuery',
  '2': [
    {'1': 'fromTimestamp', '3': 1, '4': 1, '5': 3, '10': 'fromTimestamp'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
    {
      '1': 'algo',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapEnumLogQuerySearchAlgo',
      '10': 'algo'
    },
  ],
};

/// Descriptor for `CapLogQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capLogQueryDescriptor = $convert.base64Decode(
    'CgtDYXBMb2dRdWVyeRIkCg1mcm9tVGltZXN0YW1wGAEgASgDUg1mcm9tVGltZXN0YW1wEhQKBW'
    'xpbWl0GAIgASgFUgVsaW1pdBI1CgRhbGdvGAMgASgOMiEuYm90dGxlLkNhcEVudW1Mb2dRdWVy'
    'eVNlYXJjaEFsZ29SBGFsZ28=');

@$core.Deprecated('Use capUiStateDescriptor instead')
const CapUiState$json = {
  '1': 'CapUiState',
  '2': [
    {
      '1': 'value',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapEnumUiState',
      '10': 'value'
    },
    {
      '1': 'powerSavingMode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapPowerSavingMode',
      '10': 'powerSavingMode'
    },
  ],
};

/// Descriptor for `CapUiState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capUiStateDescriptor = $convert.base64Decode(
    'CgpDYXBVaVN0YXRlEiwKBXZhbHVlGAEgASgOMhYuYm90dGxlLkNhcEVudW1VaVN0YXRlUgV2YW'
    'x1ZRJECg9wb3dlclNhdmluZ01vZGUYAiABKA4yGi5ib3R0bGUuQ2FwUG93ZXJTYXZpbmdNb2Rl'
    'Ug9wb3dlclNhdmluZ01vZGU=');

@$core.Deprecated('Use capTofStateDescriptor instead')
const CapTofState$json = {
  '1': 'CapTofState',
  '2': [
    {
      '1': 'distanceInMillimeter',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'distanceInMillimeter'
    },
    {'1': 'kcps', '3': 2, '4': 1, '5': 5, '10': 'kcps'},
  ],
};

/// Descriptor for `CapTofState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capTofStateDescriptor = $convert.base64Decode(
    'CgtDYXBUb2ZTdGF0ZRIyChRkaXN0YW5jZUluTWlsbGltZXRlchgBIAEoBVIUZGlzdGFuY2VJbk'
    '1pbGxpbWV0ZXISEgoEa2NwcxgCIAEoBVIEa2Nwcw==');

@$core.Deprecated('Use capSipSensorStateDescriptor instead')
const CapSipSensorState$json = {
  '1': 'CapSipSensorState',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
    {'1': 'state', '3': 2, '4': 1, '5': 8, '10': 'state'},
  ],
};

/// Descriptor for `CapSipSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capSipSensorStateDescriptor = $convert.base64Decode(
    'ChFDYXBTaXBTZW5zb3JTdGF0ZRIUCgV2YWx1ZRgBIAEoBVIFdmFsdWUSFAoFc3RhdGUYAiABKA'
    'hSBXN0YXRl');

@$core.Deprecated('Use capHallEffectSensorStateDescriptor instead')
const CapHallEffectSensorState$json = {
  '1': 'CapHallEffectSensorState',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `CapHallEffectSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capHallEffectSensorStateDescriptor =
    $convert.base64Decode(
        'ChhDYXBIYWxsRWZmZWN0U2Vuc29yU3RhdGUSHAoJdGltZXN0YW1wGAEgASgDUgl0aW1lc3RhbX'
        'ASFAoFdmFsdWUYAiABKAhSBXZhbHVl');

@$core.Deprecated('Use capBottleSensorStateDescriptor instead')
const CapBottleSensorState$json = {
  '1': 'CapBottleSensorState',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 17, '10': 'value'},
    {'1': 'state', '3': 2, '4': 1, '5': 8, '10': 'state'},
  ],
};

/// Descriptor for `CapBottleSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capBottleSensorStateDescriptor = $convert.base64Decode(
    'ChRDYXBCb3R0bGVTZW5zb3JTdGF0ZRIUCgV2YWx1ZRgBIAEoEVIFdmFsdWUSFAoFc3RhdGUYAi'
    'ABKAhSBXN0YXRl');

@$core.Deprecated('Use capAmbientLightSensorStateDescriptor instead')
const CapAmbientLightSensorState$json = {
  '1': 'CapAmbientLightSensorState',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 2, '10': 'value'},
  ],
};

/// Descriptor for `CapAmbientLightSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capAmbientLightSensorStateDescriptor =
    $convert.base64Decode(
        'ChpDYXBBbWJpZW50TGlnaHRTZW5zb3JTdGF0ZRIUCgV2YWx1ZRgBIAEoAlIFdmFsdWU=');

@$core.Deprecated('Use capAccelerometerStateDescriptor instead')
const CapAccelerometerState$json = {
  '1': 'CapAccelerometerState',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 2, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 2, '10': 'y'},
    {'1': 'z', '3': 3, '4': 1, '5': 2, '10': 'z'},
  ],
};

/// Descriptor for `CapAccelerometerState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capAccelerometerStateDescriptor = $convert.base64Decode(
    'ChVDYXBBY2NlbGVyb21ldGVyU3RhdGUSDAoBeBgBIAEoAlIBeBIMCgF5GAIgASgCUgF5EgwKAX'
    'oYAyABKAJSAXo=');

@$core.Deprecated('Use capTofLogDescriptor instead')
const CapTofLog$json = {
  '1': 'CapTofLog',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {
      '1': 'triggerType',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapEnumTofTriggerType',
      '10': 'triggerType'
    },
    {
      '1': 'distanceInMillimeter',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'distanceInMillimeter'
    },
    {'1': 'kcps', '3': 4, '4': 1, '5': 5, '10': 'kcps'},
    {'1': 'uvLedTempInOhm', '3': 5, '4': 1, '5': 2, '10': 'uvLedTempInOhm'},
  ],
};

/// Descriptor for `CapTofLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capTofLogDescriptor = $convert.base64Decode(
    'CglDYXBUb2ZMb2cSHAoJdGltZXN0YW1wGAEgASgDUgl0aW1lc3RhbXASPwoLdHJpZ2dlclR5cG'
    'UYAiABKA4yHS5ib3R0bGUuQ2FwRW51bVRvZlRyaWdnZXJUeXBlUgt0cmlnZ2VyVHlwZRIyChRk'
    'aXN0YW5jZUluTWlsbGltZXRlchgDIAEoBVIUZGlzdGFuY2VJbk1pbGxpbWV0ZXISEgoEa2Nwcx'
    'gEIAEoBVIEa2NwcxImCg51dkxlZFRlbXBJbk9obRgFIAEoAlIOdXZMZWRUZW1wSW5PaG0=');

@$core.Deprecated('Use capActivationLogDescriptor instead')
const CapActivationLog$json = {
  '1': 'CapActivationLog',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapEnumUvActivationMode',
      '10': 'mode'
    },
    {
      '1': 'batterySocInPercentage',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'batterySocInPercentage'
    },
  ],
};

/// Descriptor for `CapActivationLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capActivationLogDescriptor = $convert.base64Decode(
    'ChBDYXBBY3RpdmF0aW9uTG9nEhwKCXRpbWVzdGFtcBgBIAEoA1IJdGltZXN0YW1wEjMKBG1vZG'
    'UYAiABKA4yHy5ib3R0bGUuQ2FwRW51bVV2QWN0aXZhdGlvbk1vZGVSBG1vZGUSNgoWYmF0dGVy'
    'eVNvY0luUGVyY2VudGFnZRgDIAEoBVIWYmF0dGVyeVNvY0luUGVyY2VudGFnZQ==');

@$core.Deprecated('Use capFaultLogDescriptor instead')
const CapFaultLog$json = {
  '1': 'CapFaultLog',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapEnumFaultType',
      '10': 'type'
    },
  ],
};

/// Descriptor for `CapFaultLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capFaultLogDescriptor = $convert.base64Decode(
    'CgtDYXBGYXVsdExvZxIcCgl0aW1lc3RhbXAYASABKANSCXRpbWVzdGFtcBIsCgR0eXBlGAIgAS'
    'gOMhguYm90dGxlLkNhcEVudW1GYXVsdFR5cGVSBHR5cGU=');

@$core.Deprecated('Use capAdcLogDescriptor instead')
const CapAdcLog$json = {
  '1': 'CapAdcLog',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'batteryInVolt', '3': 2, '4': 1, '5': 2, '10': 'batteryInVolt'},
    {'1': 'batteryTempInOhm', '3': 3, '4': 1, '5': 2, '10': 'batteryTempInOhm'},
    {'1': 'uvLedInVolt', '3': 4, '4': 1, '5': 2, '10': 'uvLedInVolt'},
    {
      '1': 'uvLedCurrentInMilliamps',
      '3': 5,
      '4': 1,
      '5': 2,
      '10': 'uvLedCurrentInMilliamps'
    },
    {'1': 'uvLedTempInOhm', '3': 6, '4': 1, '5': 2, '10': 'uvLedTempInOhm'},
    {'1': 'cPcbTempInOhm', '3': 7, '4': 1, '5': 2, '10': 'cPcbTempInOhm'},
  ],
};

/// Descriptor for `CapAdcLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capAdcLogDescriptor = $convert.base64Decode(
    'CglDYXBBZGNMb2cSHAoJdGltZXN0YW1wGAEgASgDUgl0aW1lc3RhbXASJAoNYmF0dGVyeUluVm'
    '9sdBgCIAEoAlINYmF0dGVyeUluVm9sdBIqChBiYXR0ZXJ5VGVtcEluT2htGAMgASgCUhBiYXR0'
    'ZXJ5VGVtcEluT2htEiAKC3V2TGVkSW5Wb2x0GAQgASgCUgt1dkxlZEluVm9sdBI4Chd1dkxlZE'
    'N1cnJlbnRJbk1pbGxpYW1wcxgFIAEoAlIXdXZMZWRDdXJyZW50SW5NaWxsaWFtcHMSJgoOdXZM'
    'ZWRUZW1wSW5PaG0YBiABKAJSDnV2TGVkVGVtcEluT2htEiQKDWNQY2JUZW1wSW5PaG0YByABKA'
    'JSDWNQY2JUZW1wSW5PaG0=');

@$core.Deprecated('Use capStateLogDescriptor instead')
const CapStateLog$json = {
  '1': 'CapStateLog',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'hall', '3': 2, '4': 1, '5': 8, '10': 'hall'},
    {'1': 'bottleDetection', '3': 3, '4': 1, '5': 8, '10': 'bottleDetection'},
    {'1': 'ambientLight', '3': 4, '4': 1, '5': 8, '10': 'ambientLight'},
    {'1': 'sipDetection', '3': 5, '4': 1, '5': 8, '10': 'sipDetection'},
    {
      '1': 'bottleDetectionCapacitorValue',
      '3': 6,
      '4': 1,
      '5': 2,
      '10': 'bottleDetectionCapacitorValue'
    },
    {
      '1': 'ambientLightSensorValue',
      '3': 7,
      '4': 1,
      '5': 2,
      '10': 'ambientLightSensorValue'
    },
    {
      '1': 'sipDetectionCapacitorSensorValue',
      '3': 8,
      '4': 1,
      '5': 2,
      '10': 'sipDetectionCapacitorSensorValue'
    },
  ],
};

/// Descriptor for `CapStateLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List capStateLogDescriptor = $convert.base64Decode(
    'CgtDYXBTdGF0ZUxvZxIcCgl0aW1lc3RhbXAYASABKANSCXRpbWVzdGFtcBISCgRoYWxsGAIgAS'
    'gIUgRoYWxsEigKD2JvdHRsZURldGVjdGlvbhgDIAEoCFIPYm90dGxlRGV0ZWN0aW9uEiIKDGFt'
    'YmllbnRMaWdodBgEIAEoCFIMYW1iaWVudExpZ2h0EiIKDHNpcERldGVjdGlvbhgFIAEoCFIMc2'
    'lwRGV0ZWN0aW9uEkQKHWJvdHRsZURldGVjdGlvbkNhcGFjaXRvclZhbHVlGAYgASgCUh1ib3R0'
    'bGVEZXRlY3Rpb25DYXBhY2l0b3JWYWx1ZRI4ChdhbWJpZW50TGlnaHRTZW5zb3JWYWx1ZRgHIA'
    'EoAlIXYW1iaWVudExpZ2h0U2Vuc29yVmFsdWUSSgogc2lwRGV0ZWN0aW9uQ2FwYWNpdG9yU2Vu'
    'c29yVmFsdWUYCCABKAJSIHNpcERldGVjdGlvbkNhcGFjaXRvclNlbnNvclZhbHVl');

@$core.Deprecated('Use requestGetCapUiStateDescriptor instead')
const RequestGetCapUiState$json = {
  '1': 'RequestGetCapUiState',
};

/// Descriptor for `RequestGetCapUiState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapUiStateDescriptor =
    $convert.base64Decode('ChRSZXF1ZXN0R2V0Q2FwVWlTdGF0ZQ==');

@$core.Deprecated('Use requestGetCapTofStateDescriptor instead')
const RequestGetCapTofState$json = {
  '1': 'RequestGetCapTofState',
};

/// Descriptor for `RequestGetCapTofState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapTofStateDescriptor =
    $convert.base64Decode('ChVSZXF1ZXN0R2V0Q2FwVG9mU3RhdGU=');

@$core.Deprecated('Use requestGetCapSipSensorStateDescriptor instead')
const RequestGetCapSipSensorState$json = {
  '1': 'RequestGetCapSipSensorState',
};

/// Descriptor for `RequestGetCapSipSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapSipSensorStateDescriptor =
    $convert.base64Decode('ChtSZXF1ZXN0R2V0Q2FwU2lwU2Vuc29yU3RhdGU=');

@$core.Deprecated('Use requestGetCapHallEffectSensorStateDescriptor instead')
const RequestGetCapHallEffectSensorState$json = {
  '1': 'RequestGetCapHallEffectSensorState',
};

/// Descriptor for `RequestGetCapHallEffectSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapHallEffectSensorStateDescriptor =
    $convert.base64Decode('CiJSZXF1ZXN0R2V0Q2FwSGFsbEVmZmVjdFNlbnNvclN0YXRl');

@$core.Deprecated('Use requestGetCapBottleSensorStateDescriptor instead')
const RequestGetCapBottleSensorState$json = {
  '1': 'RequestGetCapBottleSensorState',
};

/// Descriptor for `RequestGetCapBottleSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapBottleSensorStateDescriptor =
    $convert.base64Decode('Ch5SZXF1ZXN0R2V0Q2FwQm90dGxlU2Vuc29yU3RhdGU=');

@$core.Deprecated('Use requestGetCapAmbientLightSensorStateDescriptor instead')
const RequestGetCapAmbientLightSensorState$json = {
  '1': 'RequestGetCapAmbientLightSensorState',
};

/// Descriptor for `RequestGetCapAmbientLightSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapAmbientLightSensorStateDescriptor =
    $convert
        .base64Decode('CiRSZXF1ZXN0R2V0Q2FwQW1iaWVudExpZ2h0U2Vuc29yU3RhdGU=');

@$core.Deprecated('Use requestGetCapAccelerometerStateDescriptor instead')
const RequestGetCapAccelerometerState$json = {
  '1': 'RequestGetCapAccelerometerState',
};

/// Descriptor for `RequestGetCapAccelerometerState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapAccelerometerStateDescriptor =
    $convert.base64Decode('Ch9SZXF1ZXN0R2V0Q2FwQWNjZWxlcm9tZXRlclN0YXRl');

@$core.Deprecated('Use responseGetCapUiStateDescriptor instead')
const ResponseGetCapUiState$json = {
  '1': 'ResponseGetCapUiState',
  '2': [
    {
      '1': 'state',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapEnumUiState',
      '10': 'state'
    },
    {
      '1': 'powerSavingMode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.bottle.CapPowerSavingMode',
      '10': 'powerSavingMode'
    },
  ],
};

/// Descriptor for `ResponseGetCapUiState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapUiStateDescriptor = $convert.base64Decode(
    'ChVSZXNwb25zZUdldENhcFVpU3RhdGUSLAoFc3RhdGUYASABKA4yFi5ib3R0bGUuQ2FwRW51bV'
    'VpU3RhdGVSBXN0YXRlEkQKD3Bvd2VyU2F2aW5nTW9kZRgCIAEoDjIaLmJvdHRsZS5DYXBQb3dl'
    'clNhdmluZ01vZGVSD3Bvd2VyU2F2aW5nTW9kZQ==');

@$core.Deprecated('Use responseGetCapTofStateDescriptor instead')
const ResponseGetCapTofState$json = {
  '1': 'ResponseGetCapTofState',
  '2': [
    {
      '1': 'distanceInMillimeter',
      '3': 1,
      '4': 1,
      '5': 5,
      '10': 'distanceInMillimeter'
    },
    {'1': 'kcps', '3': 2, '4': 1, '5': 5, '10': 'kcps'},
  ],
};

/// Descriptor for `ResponseGetCapTofState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapTofStateDescriptor =
    $convert.base64Decode(
        'ChZSZXNwb25zZUdldENhcFRvZlN0YXRlEjIKFGRpc3RhbmNlSW5NaWxsaW1ldGVyGAEgASgFUh'
        'RkaXN0YW5jZUluTWlsbGltZXRlchISCgRrY3BzGAIgASgFUgRrY3Bz');

@$core.Deprecated('Use responseGetCapSipSensorStateDescriptor instead')
const ResponseGetCapSipSensorState$json = {
  '1': 'ResponseGetCapSipSensorState',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 5, '10': 'value'},
    {'1': 'state', '3': 2, '4': 1, '5': 8, '10': 'state'},
  ],
};

/// Descriptor for `ResponseGetCapSipSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapSipSensorStateDescriptor =
    $convert.base64Decode(
        'ChxSZXNwb25zZUdldENhcFNpcFNlbnNvclN0YXRlEhQKBXZhbHVlGAEgASgFUgV2YWx1ZRIUCg'
        'VzdGF0ZRgCIAEoCFIFc3RhdGU=');

@$core.Deprecated('Use responseGetCapHallEffectSensorStateDescriptor instead')
const ResponseGetCapHallEffectSensorState$json = {
  '1': 'ResponseGetCapHallEffectSensorState',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
};

/// Descriptor for `ResponseGetCapHallEffectSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapHallEffectSensorStateDescriptor =
    $convert.base64Decode(
        'CiNSZXNwb25zZUdldENhcEhhbGxFZmZlY3RTZW5zb3JTdGF0ZRIcCgl0aW1lc3RhbXAYASABKA'
        'NSCXRpbWVzdGFtcBIUCgV2YWx1ZRgCIAEoCFIFdmFsdWU=');

@$core.Deprecated('Use responseGetCapBottleSensorStateDescriptor instead')
const ResponseGetCapBottleSensorState$json = {
  '1': 'ResponseGetCapBottleSensorState',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 17, '10': 'value'},
    {'1': 'state', '3': 2, '4': 1, '5': 8, '10': 'state'},
  ],
};

/// Descriptor for `ResponseGetCapBottleSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapBottleSensorStateDescriptor =
    $convert.base64Decode(
        'Ch9SZXNwb25zZUdldENhcEJvdHRsZVNlbnNvclN0YXRlEhQKBXZhbHVlGAEgASgRUgV2YWx1ZR'
        'IUCgVzdGF0ZRgCIAEoCFIFc3RhdGU=');

@$core.Deprecated('Use responseGetCapAmbientLightSensorStateDescriptor instead')
const ResponseGetCapAmbientLightSensorState$json = {
  '1': 'ResponseGetCapAmbientLightSensorState',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 2, '10': 'value'},
  ],
};

/// Descriptor for `ResponseGetCapAmbientLightSensorState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapAmbientLightSensorStateDescriptor =
    $convert.base64Decode(
        'CiVSZXNwb25zZUdldENhcEFtYmllbnRMaWdodFNlbnNvclN0YXRlEhQKBXZhbHVlGAEgASgCUg'
        'V2YWx1ZQ==');

@$core.Deprecated('Use responseGetCapAccelerometerStateDescriptor instead')
const ResponseGetCapAccelerometerState$json = {
  '1': 'ResponseGetCapAccelerometerState',
  '2': [
    {'1': 'x', '3': 1, '4': 1, '5': 2, '10': 'x'},
    {'1': 'y', '3': 2, '4': 1, '5': 2, '10': 'y'},
    {'1': 'z', '3': 3, '4': 1, '5': 2, '10': 'z'},
  ],
};

/// Descriptor for `ResponseGetCapAccelerometerState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapAccelerometerStateDescriptor =
    $convert.base64Decode(
        'CiBSZXNwb25zZUdldENhcEFjY2VsZXJvbWV0ZXJTdGF0ZRIMCgF4GAEgASgCUgF4EgwKAXkYAi'
        'ABKAJSAXkSDAoBehgDIAEoAlIBeg==');

@$core.Deprecated('Use requestGetCapTofLogDescriptor instead')
const RequestGetCapTofLog$json = {
  '1': 'RequestGetCapTofLog',
  '2': [
    {
      '1': 'query',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bottle.CapLogQuery',
      '10': 'query'
    },
  ],
};

/// Descriptor for `RequestGetCapTofLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapTofLogDescriptor = $convert.base64Decode(
    'ChNSZXF1ZXN0R2V0Q2FwVG9mTG9nEikKBXF1ZXJ5GAEgASgLMhMuYm90dGxlLkNhcExvZ1F1ZX'
    'J5UgVxdWVyeQ==');

@$core.Deprecated('Use requestGetCapStateLogDescriptor instead')
const RequestGetCapStateLog$json = {
  '1': 'RequestGetCapStateLog',
  '2': [
    {
      '1': 'query',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bottle.CapLogQuery',
      '10': 'query'
    },
  ],
};

/// Descriptor for `RequestGetCapStateLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapStateLogDescriptor = $convert.base64Decode(
    'ChVSZXF1ZXN0R2V0Q2FwU3RhdGVMb2cSKQoFcXVlcnkYASABKAsyEy5ib3R0bGUuQ2FwTG9nUX'
    'VlcnlSBXF1ZXJ5');

@$core.Deprecated('Use requestGetCapActivationLogDescriptor instead')
const RequestGetCapActivationLog$json = {
  '1': 'RequestGetCapActivationLog',
  '2': [
    {
      '1': 'query',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bottle.CapLogQuery',
      '10': 'query'
    },
  ],
};

/// Descriptor for `RequestGetCapActivationLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapActivationLogDescriptor =
    $convert.base64Decode(
        'ChpSZXF1ZXN0R2V0Q2FwQWN0aXZhdGlvbkxvZxIpCgVxdWVyeRgBIAEoCzITLmJvdHRsZS5DYX'
        'BMb2dRdWVyeVIFcXVlcnk=');

@$core.Deprecated('Use requestGetCapFaultLogDescriptor instead')
const RequestGetCapFaultLog$json = {
  '1': 'RequestGetCapFaultLog',
  '2': [
    {
      '1': 'query',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bottle.CapLogQuery',
      '10': 'query'
    },
  ],
};

/// Descriptor for `RequestGetCapFaultLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetCapFaultLogDescriptor = $convert.base64Decode(
    'ChVSZXF1ZXN0R2V0Q2FwRmF1bHRMb2cSKQoFcXVlcnkYASABKAsyEy5ib3R0bGUuQ2FwTG9nUX'
    'VlcnlSBXF1ZXJ5');

@$core.Deprecated('Use requestGetActivationCapAdcLogDescriptor instead')
const RequestGetActivationCapAdcLog$json = {
  '1': 'RequestGetActivationCapAdcLog',
  '2': [
    {
      '1': 'query',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bottle.CapLogQuery',
      '10': 'query'
    },
  ],
};

/// Descriptor for `RequestGetActivationCapAdcLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetActivationCapAdcLogDescriptor =
    $convert.base64Decode(
        'Ch1SZXF1ZXN0R2V0QWN0aXZhdGlvbkNhcEFkY0xvZxIpCgVxdWVyeRgBIAEoCzITLmJvdHRsZS'
        '5DYXBMb2dRdWVyeVIFcXVlcnk=');

@$core.Deprecated('Use requestGetChargingCapAdcLogDescriptor instead')
const RequestGetChargingCapAdcLog$json = {
  '1': 'RequestGetChargingCapAdcLog',
  '2': [
    {
      '1': 'query',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bottle.CapLogQuery',
      '10': 'query'
    },
  ],
};

/// Descriptor for `RequestGetChargingCapAdcLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestGetChargingCapAdcLogDescriptor =
    $convert.base64Decode(
        'ChtSZXF1ZXN0R2V0Q2hhcmdpbmdDYXBBZGNMb2cSKQoFcXVlcnkYASABKAsyEy5ib3R0bGUuQ2'
        'FwTG9nUXVlcnlSBXF1ZXJ5');

@$core.Deprecated('Use responseGetCapTofLogDescriptor instead')
const ResponseGetCapTofLog$json = {
  '1': 'ResponseGetCapTofLog',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bottle.CapTofLog',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ResponseGetCapTofLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapTofLogDescriptor = $convert.base64Decode(
    'ChRSZXNwb25zZUdldENhcFRvZkxvZxIrCgdlbnRyaWVzGAEgAygLMhEuYm90dGxlLkNhcFRvZk'
    'xvZ1IHZW50cmllcw==');

@$core.Deprecated('Use responseGetCapStateLogDescriptor instead')
const ResponseGetCapStateLog$json = {
  '1': 'ResponseGetCapStateLog',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bottle.CapStateLog',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ResponseGetCapStateLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapStateLogDescriptor =
    $convert.base64Decode(
        'ChZSZXNwb25zZUdldENhcFN0YXRlTG9nEi0KB2VudHJpZXMYASADKAsyEy5ib3R0bGUuQ2FwU3'
        'RhdGVMb2dSB2VudHJpZXM=');

@$core.Deprecated('Use responseGetCapActivationLogDescriptor instead')
const ResponseGetCapActivationLog$json = {
  '1': 'ResponseGetCapActivationLog',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bottle.CapActivationLog',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ResponseGetCapActivationLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapActivationLogDescriptor =
    $convert.base64Decode(
        'ChtSZXNwb25zZUdldENhcEFjdGl2YXRpb25Mb2cSMgoHZW50cmllcxgBIAMoCzIYLmJvdHRsZS'
        '5DYXBBY3RpdmF0aW9uTG9nUgdlbnRyaWVz');

@$core.Deprecated('Use responseGetCapFaultLogDescriptor instead')
const ResponseGetCapFaultLog$json = {
  '1': 'ResponseGetCapFaultLog',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bottle.CapFaultLog',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ResponseGetCapFaultLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetCapFaultLogDescriptor =
    $convert.base64Decode(
        'ChZSZXNwb25zZUdldENhcEZhdWx0TG9nEi0KB2VudHJpZXMYASADKAsyEy5ib3R0bGUuQ2FwRm'
        'F1bHRMb2dSB2VudHJpZXM=');

@$core.Deprecated('Use responseGetActivationCapAdcLogDescriptor instead')
const ResponseGetActivationCapAdcLog$json = {
  '1': 'ResponseGetActivationCapAdcLog',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bottle.CapAdcLog',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ResponseGetActivationCapAdcLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetActivationCapAdcLogDescriptor =
    $convert.base64Decode(
        'Ch5SZXNwb25zZUdldEFjdGl2YXRpb25DYXBBZGNMb2cSKwoHZW50cmllcxgBIAMoCzIRLmJvdH'
        'RsZS5DYXBBZGNMb2dSB2VudHJpZXM=');

@$core.Deprecated('Use responseGetChargingCapAdcLogDescriptor instead')
const ResponseGetChargingCapAdcLog$json = {
  '1': 'ResponseGetChargingCapAdcLog',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bottle.CapAdcLog',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `ResponseGetChargingCapAdcLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseGetChargingCapAdcLogDescriptor =
    $convert.base64Decode(
        'ChxSZXNwb25zZUdldENoYXJnaW5nQ2FwQWRjTG9nEisKB2VudHJpZXMYASADKAsyES5ib3R0bG'
        'UuQ2FwQWRjTG9nUgdlbnRyaWVz');
