// This is a generated file - do not edit.
//
// Generated from protos/cap.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CapEnumResponseCode extends $pb.ProtobufEnum {
  static const CapEnumResponseCode FAIL =
      CapEnumResponseCode._(0, _omitEnumNames ? '' : 'FAIL');
  static const CapEnumResponseCode SUCCESS =
      CapEnumResponseCode._(1, _omitEnumNames ? '' : 'SUCCESS');
  static const CapEnumResponseCode NOT_SUPPORTED =
      CapEnumResponseCode._(2, _omitEnumNames ? '' : 'NOT_SUPPORTED');

  static const $core.List<CapEnumResponseCode> values = <CapEnumResponseCode>[
    FAIL,
    SUCCESS,
    NOT_SUPPORTED,
  ];

  static final $core.List<CapEnumResponseCode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CapEnumResponseCode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CapEnumResponseCode._(super.value, super.name);
}

class CapEnumLogQuerySearchAlgo extends $pb.ProtobufEnum {
  static const CapEnumLogQuerySearchAlgo SEARCH_ALGO_TIMESTAMP =
      CapEnumLogQuerySearchAlgo._(
          0, _omitEnumNames ? '' : 'SEARCH_ALGO_TIMESTAMP');
  static const CapEnumLogQuerySearchAlgo SEARCH_ALGO_INCREMENT =
      CapEnumLogQuerySearchAlgo._(
          1, _omitEnumNames ? '' : 'SEARCH_ALGO_INCREMENT');

  static const $core.List<CapEnumLogQuerySearchAlgo> values =
      <CapEnumLogQuerySearchAlgo>[
    SEARCH_ALGO_TIMESTAMP,
    SEARCH_ALGO_INCREMENT,
  ];

  static final $core.List<CapEnumLogQuerySearchAlgo?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static CapEnumLogQuerySearchAlgo? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CapEnumLogQuerySearchAlgo._(super.value, super.name);
}

class CapEnumTofTriggerType extends $pb.ProtobufEnum {
  static const CapEnumTofTriggerType TYPE_REQUEST =
      CapEnumTofTriggerType._(0, _omitEnumNames ? '' : 'TYPE_REQUEST');
  static const CapEnumTofTriggerType TYPE_INTERVAL =
      CapEnumTofTriggerType._(1, _omitEnumNames ? '' : 'TYPE_INTERVAL');
  static const CapEnumTofTriggerType TYPE_CAP =
      CapEnumTofTriggerType._(2, _omitEnumNames ? '' : 'TYPE_CAP');
  static const CapEnumTofTriggerType TYPE_CAP_ON_FLAP =
      CapEnumTofTriggerType._(3, _omitEnumNames ? '' : 'TYPE_CAP_ON_FLAP');
  static const CapEnumTofTriggerType TYPE_CAP_ON_FLAP_OPEN_SIP =
      CapEnumTofTriggerType._(
          4, _omitEnumNames ? '' : 'TYPE_CAP_ON_FLAP_OPEN_SIP');

  static const $core.List<CapEnumTofTriggerType> values =
      <CapEnumTofTriggerType>[
    TYPE_REQUEST,
    TYPE_INTERVAL,
    TYPE_CAP,
    TYPE_CAP_ON_FLAP,
    TYPE_CAP_ON_FLAP_OPEN_SIP,
  ];

  static final $core.List<CapEnumTofTriggerType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static CapEnumTofTriggerType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CapEnumTofTriggerType._(super.value, super.name);
}

class CapEnumUvActivationMode extends $pb.ProtobufEnum {
  static const CapEnumUvActivationMode UV_MAINTENANCE =
      CapEnumUvActivationMode._(0, _omitEnumNames ? '' : 'UV_MAINTENANCE');
  static const CapEnumUvActivationMode UV_STANDARD =
      CapEnumUvActivationMode._(1, _omitEnumNames ? '' : 'UV_STANDARD');
  static const CapEnumUvActivationMode UV_ADVENTURE =
      CapEnumUvActivationMode._(2, _omitEnumNames ? '' : 'UV_ADVENTURE');
  static const CapEnumUvActivationMode UV_STOP =
      CapEnumUvActivationMode._(3, _omitEnumNames ? '' : 'UV_STOP');

  static const $core.List<CapEnumUvActivationMode> values =
      <CapEnumUvActivationMode>[
    UV_MAINTENANCE,
    UV_STANDARD,
    UV_ADVENTURE,
    UV_STOP,
  ];

  static final $core.List<CapEnumUvActivationMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static CapEnumUvActivationMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CapEnumUvActivationMode._(super.value, super.name);
}

class CapEnumFaultType extends $pb.ProtobufEnum {
  static const CapEnumFaultType UV_OVERTEMP =
      CapEnumFaultType._(0, _omitEnumNames ? '' : 'UV_OVERTEMP');
  static const CapEnumFaultType UV_LED_SHORT =
      CapEnumFaultType._(1, _omitEnumNames ? '' : 'UV_LED_SHORT');
  static const CapEnumFaultType UV_LED_OPEN =
      CapEnumFaultType._(2, _omitEnumNames ? '' : 'UV_LED_OPEN');
  static const CapEnumFaultType BATTERY_TEMP =
      CapEnumFaultType._(3, _omitEnumNames ? '' : 'BATTERY_TEMP');
  static const CapEnumFaultType BATTERY_OPEN =
      CapEnumFaultType._(4, _omitEnumNames ? '' : 'BATTERY_OPEN');
  static const CapEnumFaultType BATTERY_SHORT =
      CapEnumFaultType._(5, _omitEnumNames ? '' : 'BATTERY_SHORT');
  static const CapEnumFaultType AMBIENT_LIGHT =
      CapEnumFaultType._(6, _omitEnumNames ? '' : 'AMBIENT_LIGHT');

  static const $core.List<CapEnumFaultType> values = <CapEnumFaultType>[
    UV_OVERTEMP,
    UV_LED_SHORT,
    UV_LED_OPEN,
    BATTERY_TEMP,
    BATTERY_OPEN,
    BATTERY_SHORT,
    AMBIENT_LIGHT,
  ];

  static final $core.List<CapEnumFaultType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static CapEnumFaultType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CapEnumFaultType._(super.value, super.name);
}

class CapEnumUiState extends $pb.ProtobufEnum {
  static const CapEnumUiState UI_ON =
      CapEnumUiState._(0, _omitEnumNames ? '' : 'UI_ON');
  static const CapEnumUiState UI_FAULT =
      CapEnumUiState._(1, _omitEnumNames ? '' : 'UI_FAULT');
  static const CapEnumUiState UI_UV_MAINTENANCE =
      CapEnumUiState._(2, _omitEnumNames ? '' : 'UI_UV_MAINTENANCE');
  static const CapEnumUiState UI_UV_NORMAL =
      CapEnumUiState._(3, _omitEnumNames ? '' : 'UI_UV_NORMAL');
  static const CapEnumUiState UI_UV_ADVENTURE =
      CapEnumUiState._(4, _omitEnumNames ? '' : 'UI_UV_ADVENTURE');
  static const CapEnumUiState UI_PAIRED =
      CapEnumUiState._(5, _omitEnumNames ? '' : 'UI_PAIRED');
  static const CapEnumUiState UI_HYDRATION_REMINDER =
      CapEnumUiState._(6, _omitEnumNames ? '' : 'UI_HYDRATION_REMINDER');
  static const CapEnumUiState UI_BATTERY_LOW =
      CapEnumUiState._(7, _omitEnumNames ? '' : 'UI_BATTERY_LOW');
  static const CapEnumUiState UI_CHARGING =
      CapEnumUiState._(8, _omitEnumNames ? '' : 'UI_CHARGING');
  static const CapEnumUiState UI_CHARGED =
      CapEnumUiState._(9, _omitEnumNames ? '' : 'UI_CHARGED');
  static const CapEnumUiState UI_UV_INTERLOCK =
      CapEnumUiState._(10, _omitEnumNames ? '' : 'UI_UV_INTERLOCK');
  static const CapEnumUiState UI_BOTTLE_CALIBRATION =
      CapEnumUiState._(11, _omitEnumNames ? '' : 'UI_BOTTLE_CALIBRATION');
  static const CapEnumUiState UI_TOF_MEASUREMENT =
      CapEnumUiState._(12, _omitEnumNames ? '' : 'UI_TOF_MEASUREMENT');
  static const CapEnumUiState UI_TURN_OFF =
      CapEnumUiState._(13, _omitEnumNames ? '' : 'UI_TURN_OFF');
  static const CapEnumUiState UI_FACTORY_RESET =
      CapEnumUiState._(14, _omitEnumNames ? '' : 'UI_FACTORY_RESET');
  static const CapEnumUiState UI_ALL_OFF =
      CapEnumUiState._(15, _omitEnumNames ? '' : 'UI_ALL_OFF');
  static const CapEnumUiState UI_LOCKED =
      CapEnumUiState._(16, _omitEnumNames ? '' : 'UI_LOCKED');
  static const CapEnumUiState UI_QC =
      CapEnumUiState._(17, _omitEnumNames ? '' : 'UI_QC');
  static const CapEnumUiState UI_LAST =
      CapEnumUiState._(18, _omitEnumNames ? '' : 'UI_LAST');

  static const $core.List<CapEnumUiState> values = <CapEnumUiState>[
    UI_ON,
    UI_FAULT,
    UI_UV_MAINTENANCE,
    UI_UV_NORMAL,
    UI_UV_ADVENTURE,
    UI_PAIRED,
    UI_HYDRATION_REMINDER,
    UI_BATTERY_LOW,
    UI_CHARGING,
    UI_CHARGED,
    UI_UV_INTERLOCK,
    UI_BOTTLE_CALIBRATION,
    UI_TOF_MEASUREMENT,
    UI_TURN_OFF,
    UI_FACTORY_RESET,
    UI_ALL_OFF,
    UI_LOCKED,
    UI_QC,
    UI_LAST,
  ];

  static final $core.List<CapEnumUiState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 18);
  static CapEnumUiState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CapEnumUiState._(super.value, super.name);
}

class CapPowerSavingMode extends $pb.ProtobufEnum {
  static const CapPowerSavingMode POWER_SAVING_OFF =
      CapPowerSavingMode._(0, _omitEnumNames ? '' : 'POWER_SAVING_OFF');
  static const CapPowerSavingMode POWER_SAVING_ON =
      CapPowerSavingMode._(1, _omitEnumNames ? '' : 'POWER_SAVING_ON');
  static const CapPowerSavingMode POWER_SAVING_AUTO =
      CapPowerSavingMode._(2, _omitEnumNames ? '' : 'POWER_SAVING_AUTO');

  static const $core.List<CapPowerSavingMode> values = <CapPowerSavingMode>[
    POWER_SAVING_OFF,
    POWER_SAVING_ON,
    POWER_SAVING_AUTO,
  ];

  static final $core.List<CapPowerSavingMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static CapPowerSavingMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CapPowerSavingMode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
