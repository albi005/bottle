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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart' as $0;

import 'cap.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'cap.pbenum.dart';

class CapBleRequest extends $pb.GeneratedMessage {
  factory CapBleRequest({
    $core.int? requestId,
    $0.Any? body,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    if (body != null) result.body = body;
    return result;
  }

  CapBleRequest._();

  factory CapBleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapBleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapBleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'requestId',
        protoName: 'requestId', fieldType: $pb.PbFieldType.OF3)
    ..aOM<$0.Any>(2, _omitFieldNames ? '' : 'body', subBuilder: $0.Any.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapBleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapBleRequest copyWith(void Function(CapBleRequest) updates) =>
      super.copyWith((message) => updates(message as CapBleRequest))
          as CapBleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapBleRequest create() => CapBleRequest._();
  @$core.override
  CapBleRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapBleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapBleRequest>(create);
  static CapBleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get requestId => $_getIZ(0);
  @$pb.TagNumber(1)
  set requestId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.Any get body => $_getN(1);
  @$pb.TagNumber(2)
  set body($0.Any value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.Any ensureBody() => $_ensure(1);
}

class CapBleResponse extends $pb.GeneratedMessage {
  factory CapBleResponse({
    $core.int? requestId,
    CapEnumResponseCode? code,
    $0.Any? body,
  }) {
    final result = create();
    if (requestId != null) result.requestId = requestId;
    if (code != null) result.code = code;
    if (body != null) result.body = body;
    return result;
  }

  CapBleResponse._();

  factory CapBleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapBleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapBleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'requestId',
        protoName: 'requestId', fieldType: $pb.PbFieldType.OF3)
    ..aE<CapEnumResponseCode>(2, _omitFieldNames ? '' : 'code',
        enumValues: CapEnumResponseCode.values)
    ..aOM<$0.Any>(3, _omitFieldNames ? '' : 'body', subBuilder: $0.Any.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapBleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapBleResponse copyWith(void Function(CapBleResponse) updates) =>
      super.copyWith((message) => updates(message as CapBleResponse))
          as CapBleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapBleResponse create() => CapBleResponse._();
  @$core.override
  CapBleResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapBleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapBleResponse>(create);
  static CapBleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get requestId => $_getIZ(0);
  @$pb.TagNumber(1)
  set requestId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => $_clearField(1);

  @$pb.TagNumber(2)
  CapEnumResponseCode get code => $_getN(1);
  @$pb.TagNumber(2)
  set code(CapEnumResponseCode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $0.Any get body => $_getN(2);
  @$pb.TagNumber(3)
  set body($0.Any value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasBody() => $_has(2);
  @$pb.TagNumber(3)
  void clearBody() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.Any ensureBody() => $_ensure(2);
}

class CapLogQuery extends $pb.GeneratedMessage {
  factory CapLogQuery({
    $fixnum.Int64? fromTimestamp,
    $core.int? limit,
    CapEnumLogQuerySearchAlgo? algo,
  }) {
    final result = create();
    if (fromTimestamp != null) result.fromTimestamp = fromTimestamp;
    if (limit != null) result.limit = limit;
    if (algo != null) result.algo = algo;
    return result;
  }

  CapLogQuery._();

  factory CapLogQuery.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapLogQuery.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapLogQuery',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'fromTimestamp',
        protoName: 'fromTimestamp')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..aE<CapEnumLogQuerySearchAlgo>(3, _omitFieldNames ? '' : 'algo',
        enumValues: CapEnumLogQuerySearchAlgo.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapLogQuery clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapLogQuery copyWith(void Function(CapLogQuery) updates) =>
      super.copyWith((message) => updates(message as CapLogQuery))
          as CapLogQuery;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapLogQuery create() => CapLogQuery._();
  @$core.override
  CapLogQuery createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapLogQuery getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapLogQuery>(create);
  static CapLogQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get fromTimestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set fromTimestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFromTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);

  @$pb.TagNumber(3)
  CapEnumLogQuerySearchAlgo get algo => $_getN(2);
  @$pb.TagNumber(3)
  set algo(CapEnumLogQuerySearchAlgo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAlgo() => $_has(2);
  @$pb.TagNumber(3)
  void clearAlgo() => $_clearField(3);
}

class CapUiState extends $pb.GeneratedMessage {
  factory CapUiState({
    CapEnumUiState? value,
    CapPowerSavingMode? powerSavingMode,
  }) {
    final result = create();
    if (value != null) result.value = value;
    if (powerSavingMode != null) result.powerSavingMode = powerSavingMode;
    return result;
  }

  CapUiState._();

  factory CapUiState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapUiState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapUiState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aE<CapEnumUiState>(1, _omitFieldNames ? '' : 'value',
        enumValues: CapEnumUiState.values)
    ..aE<CapPowerSavingMode>(2, _omitFieldNames ? '' : 'powerSavingMode',
        protoName: 'powerSavingMode', enumValues: CapPowerSavingMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapUiState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapUiState copyWith(void Function(CapUiState) updates) =>
      super.copyWith((message) => updates(message as CapUiState)) as CapUiState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapUiState create() => CapUiState._();
  @$core.override
  CapUiState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapUiState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapUiState>(create);
  static CapUiState? _defaultInstance;

  @$pb.TagNumber(1)
  CapEnumUiState get value => $_getN(0);
  @$pb.TagNumber(1)
  set value(CapEnumUiState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  CapPowerSavingMode get powerSavingMode => $_getN(1);
  @$pb.TagNumber(2)
  set powerSavingMode(CapPowerSavingMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPowerSavingMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearPowerSavingMode() => $_clearField(2);
}

class CapTofState extends $pb.GeneratedMessage {
  factory CapTofState({
    $core.int? distanceInMillimeter,
    $core.int? kcps,
  }) {
    final result = create();
    if (distanceInMillimeter != null)
      result.distanceInMillimeter = distanceInMillimeter;
    if (kcps != null) result.kcps = kcps;
    return result;
  }

  CapTofState._();

  factory CapTofState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapTofState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapTofState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'distanceInMillimeter',
        protoName: 'distanceInMillimeter')
    ..aI(2, _omitFieldNames ? '' : 'kcps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapTofState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapTofState copyWith(void Function(CapTofState) updates) =>
      super.copyWith((message) => updates(message as CapTofState))
          as CapTofState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapTofState create() => CapTofState._();
  @$core.override
  CapTofState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapTofState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapTofState>(create);
  static CapTofState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get distanceInMillimeter => $_getIZ(0);
  @$pb.TagNumber(1)
  set distanceInMillimeter($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDistanceInMillimeter() => $_has(0);
  @$pb.TagNumber(1)
  void clearDistanceInMillimeter() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get kcps => $_getIZ(1);
  @$pb.TagNumber(2)
  set kcps($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKcps() => $_has(1);
  @$pb.TagNumber(2)
  void clearKcps() => $_clearField(2);
}

class CapSipSensorState extends $pb.GeneratedMessage {
  factory CapSipSensorState({
    $core.int? value,
    $core.bool? state,
  }) {
    final result = create();
    if (value != null) result.value = value;
    if (state != null) result.state = state;
    return result;
  }

  CapSipSensorState._();

  factory CapSipSensorState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapSipSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapSipSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value')
    ..aOB(2, _omitFieldNames ? '' : 'state')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapSipSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapSipSensorState copyWith(void Function(CapSipSensorState) updates) =>
      super.copyWith((message) => updates(message as CapSipSensorState))
          as CapSipSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapSipSensorState create() => CapSipSensorState._();
  @$core.override
  CapSipSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapSipSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapSipSensorState>(create);
  static CapSipSensorState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get state => $_getBF(1);
  @$pb.TagNumber(2)
  set state($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);
}

class CapHallEffectSensorState extends $pb.GeneratedMessage {
  factory CapHallEffectSensorState({
    $fixnum.Int64? timestamp,
    $core.bool? value,
  }) {
    final result = create();
    if (timestamp != null) result.timestamp = timestamp;
    if (value != null) result.value = value;
    return result;
  }

  CapHallEffectSensorState._();

  factory CapHallEffectSensorState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapHallEffectSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapHallEffectSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestamp')
    ..aOB(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapHallEffectSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapHallEffectSensorState copyWith(
          void Function(CapHallEffectSensorState) updates) =>
      super.copyWith((message) => updates(message as CapHallEffectSensorState))
          as CapHallEffectSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapHallEffectSensorState create() => CapHallEffectSensorState._();
  @$core.override
  CapHallEffectSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapHallEffectSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapHallEffectSensorState>(create);
  static CapHallEffectSensorState? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get value => $_getBF(1);
  @$pb.TagNumber(2)
  set value($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);
}

class CapBottleSensorState extends $pb.GeneratedMessage {
  factory CapBottleSensorState({
    $core.int? value,
    $core.bool? state,
  }) {
    final result = create();
    if (value != null) result.value = value;
    if (state != null) result.state = state;
    return result;
  }

  CapBottleSensorState._();

  factory CapBottleSensorState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapBottleSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapBottleSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'value', fieldType: $pb.PbFieldType.OS3)
    ..aOB(2, _omitFieldNames ? '' : 'state')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapBottleSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapBottleSensorState copyWith(void Function(CapBottleSensorState) updates) =>
      super.copyWith((message) => updates(message as CapBottleSensorState))
          as CapBottleSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapBottleSensorState create() => CapBottleSensorState._();
  @$core.override
  CapBottleSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapBottleSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapBottleSensorState>(create);
  static CapBottleSensorState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get value => $_getIZ(0);
  @$pb.TagNumber(1)
  set value($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get state => $_getBF(1);
  @$pb.TagNumber(2)
  set state($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);
}

class CapAmbientLightSensorState extends $pb.GeneratedMessage {
  factory CapAmbientLightSensorState({
    $core.double? value,
  }) {
    final result = create();
    if (value != null) result.value = value;
    return result;
  }

  CapAmbientLightSensorState._();

  factory CapAmbientLightSensorState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapAmbientLightSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapAmbientLightSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'value', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapAmbientLightSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapAmbientLightSensorState copyWith(
          void Function(CapAmbientLightSensorState) updates) =>
      super.copyWith(
              (message) => updates(message as CapAmbientLightSensorState))
          as CapAmbientLightSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapAmbientLightSensorState create() => CapAmbientLightSensorState._();
  @$core.override
  CapAmbientLightSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapAmbientLightSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapAmbientLightSensorState>(create);
  static CapAmbientLightSensorState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get value => $_getN(0);
  @$pb.TagNumber(1)
  set value($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);
}

class CapAccelerometerState extends $pb.GeneratedMessage {
  factory CapAccelerometerState({
    $core.double? x,
    $core.double? y,
    $core.double? z,
  }) {
    final result = create();
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (z != null) result.z = z;
    return result;
  }

  CapAccelerometerState._();

  factory CapAccelerometerState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapAccelerometerState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapAccelerometerState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aD(1, _omitFieldNames ? '' : 'x', fieldType: $pb.PbFieldType.OF)
    ..aD(2, _omitFieldNames ? '' : 'y', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'z', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapAccelerometerState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapAccelerometerState copyWith(
          void Function(CapAccelerometerState) updates) =>
      super.copyWith((message) => updates(message as CapAccelerometerState))
          as CapAccelerometerState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapAccelerometerState create() => CapAccelerometerState._();
  @$core.override
  CapAccelerometerState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapAccelerometerState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapAccelerometerState>(create);
  static CapAccelerometerState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get x => $_getN(0);
  @$pb.TagNumber(1)
  set x($core.double value) => $_setFloat(0, value);
  @$pb.TagNumber(1)
  $core.bool hasX() => $_has(0);
  @$pb.TagNumber(1)
  void clearX() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get y => $_getN(1);
  @$pb.TagNumber(2)
  set y($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasY() => $_has(1);
  @$pb.TagNumber(2)
  void clearY() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get z => $_getN(2);
  @$pb.TagNumber(3)
  set z($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasZ() => $_has(2);
  @$pb.TagNumber(3)
  void clearZ() => $_clearField(3);
}

class CapTofLog extends $pb.GeneratedMessage {
  factory CapTofLog({
    $fixnum.Int64? timestamp,
    CapEnumTofTriggerType? triggerType,
    $core.int? distanceInMillimeter,
    $core.int? kcps,
    $core.double? uvLedTempInOhm,
  }) {
    final result = create();
    if (timestamp != null) result.timestamp = timestamp;
    if (triggerType != null) result.triggerType = triggerType;
    if (distanceInMillimeter != null)
      result.distanceInMillimeter = distanceInMillimeter;
    if (kcps != null) result.kcps = kcps;
    if (uvLedTempInOhm != null) result.uvLedTempInOhm = uvLedTempInOhm;
    return result;
  }

  CapTofLog._();

  factory CapTofLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapTofLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapTofLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestamp')
    ..aE<CapEnumTofTriggerType>(2, _omitFieldNames ? '' : 'triggerType',
        protoName: 'triggerType', enumValues: CapEnumTofTriggerType.values)
    ..aI(3, _omitFieldNames ? '' : 'distanceInMillimeter',
        protoName: 'distanceInMillimeter')
    ..aI(4, _omitFieldNames ? '' : 'kcps')
    ..aD(5, _omitFieldNames ? '' : 'uvLedTempInOhm',
        protoName: 'uvLedTempInOhm', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapTofLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapTofLog copyWith(void Function(CapTofLog) updates) =>
      super.copyWith((message) => updates(message as CapTofLog)) as CapTofLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapTofLog create() => CapTofLog._();
  @$core.override
  CapTofLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapTofLog getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CapTofLog>(create);
  static CapTofLog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  CapEnumTofTriggerType get triggerType => $_getN(1);
  @$pb.TagNumber(2)
  set triggerType(CapEnumTofTriggerType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTriggerType() => $_has(1);
  @$pb.TagNumber(2)
  void clearTriggerType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get distanceInMillimeter => $_getIZ(2);
  @$pb.TagNumber(3)
  set distanceInMillimeter($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDistanceInMillimeter() => $_has(2);
  @$pb.TagNumber(3)
  void clearDistanceInMillimeter() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get kcps => $_getIZ(3);
  @$pb.TagNumber(4)
  set kcps($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKcps() => $_has(3);
  @$pb.TagNumber(4)
  void clearKcps() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get uvLedTempInOhm => $_getN(4);
  @$pb.TagNumber(5)
  set uvLedTempInOhm($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUvLedTempInOhm() => $_has(4);
  @$pb.TagNumber(5)
  void clearUvLedTempInOhm() => $_clearField(5);
}

class CapActivationLog extends $pb.GeneratedMessage {
  factory CapActivationLog({
    $fixnum.Int64? timestamp,
    CapEnumUvActivationMode? mode,
    $core.int? batterySocInPercentage,
  }) {
    final result = create();
    if (timestamp != null) result.timestamp = timestamp;
    if (mode != null) result.mode = mode;
    if (batterySocInPercentage != null)
      result.batterySocInPercentage = batterySocInPercentage;
    return result;
  }

  CapActivationLog._();

  factory CapActivationLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapActivationLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapActivationLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestamp')
    ..aE<CapEnumUvActivationMode>(2, _omitFieldNames ? '' : 'mode',
        enumValues: CapEnumUvActivationMode.values)
    ..aI(3, _omitFieldNames ? '' : 'batterySocInPercentage',
        protoName: 'batterySocInPercentage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapActivationLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapActivationLog copyWith(void Function(CapActivationLog) updates) =>
      super.copyWith((message) => updates(message as CapActivationLog))
          as CapActivationLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapActivationLog create() => CapActivationLog._();
  @$core.override
  CapActivationLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapActivationLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapActivationLog>(create);
  static CapActivationLog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  CapEnumUvActivationMode get mode => $_getN(1);
  @$pb.TagNumber(2)
  set mode(CapEnumUvActivationMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get batterySocInPercentage => $_getIZ(2);
  @$pb.TagNumber(3)
  set batterySocInPercentage($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBatterySocInPercentage() => $_has(2);
  @$pb.TagNumber(3)
  void clearBatterySocInPercentage() => $_clearField(3);
}

class CapFaultLog extends $pb.GeneratedMessage {
  factory CapFaultLog({
    $fixnum.Int64? timestamp,
    CapEnumFaultType? type,
  }) {
    final result = create();
    if (timestamp != null) result.timestamp = timestamp;
    if (type != null) result.type = type;
    return result;
  }

  CapFaultLog._();

  factory CapFaultLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapFaultLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapFaultLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestamp')
    ..aE<CapEnumFaultType>(2, _omitFieldNames ? '' : 'type',
        enumValues: CapEnumFaultType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapFaultLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapFaultLog copyWith(void Function(CapFaultLog) updates) =>
      super.copyWith((message) => updates(message as CapFaultLog))
          as CapFaultLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapFaultLog create() => CapFaultLog._();
  @$core.override
  CapFaultLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapFaultLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapFaultLog>(create);
  static CapFaultLog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  CapEnumFaultType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(CapEnumFaultType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);
}

class CapAdcLog extends $pb.GeneratedMessage {
  factory CapAdcLog({
    $fixnum.Int64? timestamp,
    $core.double? batteryInVolt,
    $core.double? batteryTempInOhm,
    $core.double? uvLedInVolt,
    $core.double? uvLedCurrentInMilliamps,
    $core.double? uvLedTempInOhm,
    $core.double? cPcbTempInOhm,
  }) {
    final result = create();
    if (timestamp != null) result.timestamp = timestamp;
    if (batteryInVolt != null) result.batteryInVolt = batteryInVolt;
    if (batteryTempInOhm != null) result.batteryTempInOhm = batteryTempInOhm;
    if (uvLedInVolt != null) result.uvLedInVolt = uvLedInVolt;
    if (uvLedCurrentInMilliamps != null)
      result.uvLedCurrentInMilliamps = uvLedCurrentInMilliamps;
    if (uvLedTempInOhm != null) result.uvLedTempInOhm = uvLedTempInOhm;
    if (cPcbTempInOhm != null) result.cPcbTempInOhm = cPcbTempInOhm;
    return result;
  }

  CapAdcLog._();

  factory CapAdcLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapAdcLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapAdcLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestamp')
    ..aD(2, _omitFieldNames ? '' : 'batteryInVolt',
        protoName: 'batteryInVolt', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'batteryTempInOhm',
        protoName: 'batteryTempInOhm', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'uvLedInVolt',
        protoName: 'uvLedInVolt', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'uvLedCurrentInMilliamps',
        protoName: 'uvLedCurrentInMilliamps', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'uvLedTempInOhm',
        protoName: 'uvLedTempInOhm', fieldType: $pb.PbFieldType.OF)
    ..aD(7, _omitFieldNames ? '' : 'cPcbTempInOhm',
        protoName: 'cPcbTempInOhm', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapAdcLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapAdcLog copyWith(void Function(CapAdcLog) updates) =>
      super.copyWith((message) => updates(message as CapAdcLog)) as CapAdcLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapAdcLog create() => CapAdcLog._();
  @$core.override
  CapAdcLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapAdcLog getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CapAdcLog>(create);
  static CapAdcLog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get batteryInVolt => $_getN(1);
  @$pb.TagNumber(2)
  set batteryInVolt($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBatteryInVolt() => $_has(1);
  @$pb.TagNumber(2)
  void clearBatteryInVolt() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get batteryTempInOhm => $_getN(2);
  @$pb.TagNumber(3)
  set batteryTempInOhm($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBatteryTempInOhm() => $_has(2);
  @$pb.TagNumber(3)
  void clearBatteryTempInOhm() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get uvLedInVolt => $_getN(3);
  @$pb.TagNumber(4)
  set uvLedInVolt($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUvLedInVolt() => $_has(3);
  @$pb.TagNumber(4)
  void clearUvLedInVolt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get uvLedCurrentInMilliamps => $_getN(4);
  @$pb.TagNumber(5)
  set uvLedCurrentInMilliamps($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUvLedCurrentInMilliamps() => $_has(4);
  @$pb.TagNumber(5)
  void clearUvLedCurrentInMilliamps() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get uvLedTempInOhm => $_getN(5);
  @$pb.TagNumber(6)
  set uvLedTempInOhm($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUvLedTempInOhm() => $_has(5);
  @$pb.TagNumber(6)
  void clearUvLedTempInOhm() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get cPcbTempInOhm => $_getN(6);
  @$pb.TagNumber(7)
  set cPcbTempInOhm($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCPcbTempInOhm() => $_has(6);
  @$pb.TagNumber(7)
  void clearCPcbTempInOhm() => $_clearField(7);
}

class CapStateLog extends $pb.GeneratedMessage {
  factory CapStateLog({
    $fixnum.Int64? timestamp,
    $core.bool? hall,
    $core.bool? bottleDetection,
    $core.bool? ambientLight,
    $core.bool? sipDetection,
    $core.double? bottleDetectionCapacitorValue,
    $core.double? ambientLightSensorValue,
    $core.double? sipDetectionCapacitorSensorValue,
  }) {
    final result = create();
    if (timestamp != null) result.timestamp = timestamp;
    if (hall != null) result.hall = hall;
    if (bottleDetection != null) result.bottleDetection = bottleDetection;
    if (ambientLight != null) result.ambientLight = ambientLight;
    if (sipDetection != null) result.sipDetection = sipDetection;
    if (bottleDetectionCapacitorValue != null)
      result.bottleDetectionCapacitorValue = bottleDetectionCapacitorValue;
    if (ambientLightSensorValue != null)
      result.ambientLightSensorValue = ambientLightSensorValue;
    if (sipDetectionCapacitorSensorValue != null)
      result.sipDetectionCapacitorSensorValue =
          sipDetectionCapacitorSensorValue;
    return result;
  }

  CapStateLog._();

  factory CapStateLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CapStateLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CapStateLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestamp')
    ..aOB(2, _omitFieldNames ? '' : 'hall')
    ..aOB(3, _omitFieldNames ? '' : 'bottleDetection',
        protoName: 'bottleDetection')
    ..aOB(4, _omitFieldNames ? '' : 'ambientLight', protoName: 'ambientLight')
    ..aOB(5, _omitFieldNames ? '' : 'sipDetection', protoName: 'sipDetection')
    ..aD(6, _omitFieldNames ? '' : 'bottleDetectionCapacitorValue',
        protoName: 'bottleDetectionCapacitorValue',
        fieldType: $pb.PbFieldType.OF)
    ..aD(7, _omitFieldNames ? '' : 'ambientLightSensorValue',
        protoName: 'ambientLightSensorValue', fieldType: $pb.PbFieldType.OF)
    ..aD(8, _omitFieldNames ? '' : 'sipDetectionCapacitorSensorValue',
        protoName: 'sipDetectionCapacitorSensorValue',
        fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapStateLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CapStateLog copyWith(void Function(CapStateLog) updates) =>
      super.copyWith((message) => updates(message as CapStateLog))
          as CapStateLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CapStateLog create() => CapStateLog._();
  @$core.override
  CapStateLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CapStateLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CapStateLog>(create);
  static CapStateLog? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get hall => $_getBF(1);
  @$pb.TagNumber(2)
  set hall($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHall() => $_has(1);
  @$pb.TagNumber(2)
  void clearHall() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get bottleDetection => $_getBF(2);
  @$pb.TagNumber(3)
  set bottleDetection($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBottleDetection() => $_has(2);
  @$pb.TagNumber(3)
  void clearBottleDetection() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get ambientLight => $_getBF(3);
  @$pb.TagNumber(4)
  set ambientLight($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAmbientLight() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmbientLight() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get sipDetection => $_getBF(4);
  @$pb.TagNumber(5)
  set sipDetection($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSipDetection() => $_has(4);
  @$pb.TagNumber(5)
  void clearSipDetection() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get bottleDetectionCapacitorValue => $_getN(5);
  @$pb.TagNumber(6)
  set bottleDetectionCapacitorValue($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBottleDetectionCapacitorValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearBottleDetectionCapacitorValue() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get ambientLightSensorValue => $_getN(6);
  @$pb.TagNumber(7)
  set ambientLightSensorValue($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAmbientLightSensorValue() => $_has(6);
  @$pb.TagNumber(7)
  void clearAmbientLightSensorValue() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get sipDetectionCapacitorSensorValue => $_getN(7);
  @$pb.TagNumber(8)
  set sipDetectionCapacitorSensorValue($core.double value) =>
      $_setFloat(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSipDetectionCapacitorSensorValue() => $_has(7);
  @$pb.TagNumber(8)
  void clearSipDetectionCapacitorSensorValue() => $_clearField(8);
}

class RequestGetCapUiState extends $pb.GeneratedMessage {
  factory RequestGetCapUiState() => create();

  RequestGetCapUiState._();

  factory RequestGetCapUiState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapUiState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapUiState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapUiState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapUiState copyWith(void Function(RequestGetCapUiState) updates) =>
      super.copyWith((message) => updates(message as RequestGetCapUiState))
          as RequestGetCapUiState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapUiState create() => RequestGetCapUiState._();
  @$core.override
  RequestGetCapUiState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapUiState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapUiState>(create);
  static RequestGetCapUiState? _defaultInstance;
}

class RequestGetCapTofState extends $pb.GeneratedMessage {
  factory RequestGetCapTofState() => create();

  RequestGetCapTofState._();

  factory RequestGetCapTofState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapTofState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapTofState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapTofState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapTofState copyWith(
          void Function(RequestGetCapTofState) updates) =>
      super.copyWith((message) => updates(message as RequestGetCapTofState))
          as RequestGetCapTofState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapTofState create() => RequestGetCapTofState._();
  @$core.override
  RequestGetCapTofState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapTofState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapTofState>(create);
  static RequestGetCapTofState? _defaultInstance;
}

class RequestGetCapSipSensorState extends $pb.GeneratedMessage {
  factory RequestGetCapSipSensorState() => create();

  RequestGetCapSipSensorState._();

  factory RequestGetCapSipSensorState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapSipSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapSipSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapSipSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapSipSensorState copyWith(
          void Function(RequestGetCapSipSensorState) updates) =>
      super.copyWith(
              (message) => updates(message as RequestGetCapSipSensorState))
          as RequestGetCapSipSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapSipSensorState create() =>
      RequestGetCapSipSensorState._();
  @$core.override
  RequestGetCapSipSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapSipSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapSipSensorState>(create);
  static RequestGetCapSipSensorState? _defaultInstance;
}

class RequestGetCapHallEffectSensorState extends $pb.GeneratedMessage {
  factory RequestGetCapHallEffectSensorState() => create();

  RequestGetCapHallEffectSensorState._();

  factory RequestGetCapHallEffectSensorState.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapHallEffectSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapHallEffectSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapHallEffectSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapHallEffectSensorState copyWith(
          void Function(RequestGetCapHallEffectSensorState) updates) =>
      super.copyWith((message) =>
              updates(message as RequestGetCapHallEffectSensorState))
          as RequestGetCapHallEffectSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapHallEffectSensorState create() =>
      RequestGetCapHallEffectSensorState._();
  @$core.override
  RequestGetCapHallEffectSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapHallEffectSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapHallEffectSensorState>(
          create);
  static RequestGetCapHallEffectSensorState? _defaultInstance;
}

class RequestGetCapBottleSensorState extends $pb.GeneratedMessage {
  factory RequestGetCapBottleSensorState() => create();

  RequestGetCapBottleSensorState._();

  factory RequestGetCapBottleSensorState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapBottleSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapBottleSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapBottleSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapBottleSensorState copyWith(
          void Function(RequestGetCapBottleSensorState) updates) =>
      super.copyWith(
              (message) => updates(message as RequestGetCapBottleSensorState))
          as RequestGetCapBottleSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapBottleSensorState create() =>
      RequestGetCapBottleSensorState._();
  @$core.override
  RequestGetCapBottleSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapBottleSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapBottleSensorState>(create);
  static RequestGetCapBottleSensorState? _defaultInstance;
}

class RequestGetCapAmbientLightSensorState extends $pb.GeneratedMessage {
  factory RequestGetCapAmbientLightSensorState() => create();

  RequestGetCapAmbientLightSensorState._();

  factory RequestGetCapAmbientLightSensorState.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapAmbientLightSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapAmbientLightSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapAmbientLightSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapAmbientLightSensorState copyWith(
          void Function(RequestGetCapAmbientLightSensorState) updates) =>
      super.copyWith((message) =>
              updates(message as RequestGetCapAmbientLightSensorState))
          as RequestGetCapAmbientLightSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapAmbientLightSensorState create() =>
      RequestGetCapAmbientLightSensorState._();
  @$core.override
  RequestGetCapAmbientLightSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapAmbientLightSensorState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          RequestGetCapAmbientLightSensorState>(create);
  static RequestGetCapAmbientLightSensorState? _defaultInstance;
}

class RequestGetCapAccelerometerState extends $pb.GeneratedMessage {
  factory RequestGetCapAccelerometerState() => create();

  RequestGetCapAccelerometerState._();

  factory RequestGetCapAccelerometerState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapAccelerometerState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapAccelerometerState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapAccelerometerState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapAccelerometerState copyWith(
          void Function(RequestGetCapAccelerometerState) updates) =>
      super.copyWith(
              (message) => updates(message as RequestGetCapAccelerometerState))
          as RequestGetCapAccelerometerState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapAccelerometerState create() =>
      RequestGetCapAccelerometerState._();
  @$core.override
  RequestGetCapAccelerometerState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapAccelerometerState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapAccelerometerState>(
          create);
  static RequestGetCapAccelerometerState? _defaultInstance;
}

class ResponseGetCapUiState extends $pb.GeneratedMessage {
  factory ResponseGetCapUiState({
    CapEnumUiState? state,
    CapPowerSavingMode? powerSavingMode,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (powerSavingMode != null) result.powerSavingMode = powerSavingMode;
    return result;
  }

  ResponseGetCapUiState._();

  factory ResponseGetCapUiState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapUiState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapUiState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aE<CapEnumUiState>(1, _omitFieldNames ? '' : 'state',
        enumValues: CapEnumUiState.values)
    ..aE<CapPowerSavingMode>(2, _omitFieldNames ? '' : 'powerSavingMode',
        protoName: 'powerSavingMode', enumValues: CapPowerSavingMode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapUiState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapUiState copyWith(
          void Function(ResponseGetCapUiState) updates) =>
      super.copyWith((message) => updates(message as ResponseGetCapUiState))
          as ResponseGetCapUiState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapUiState create() => ResponseGetCapUiState._();
  @$core.override
  ResponseGetCapUiState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapUiState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapUiState>(create);
  static ResponseGetCapUiState? _defaultInstance;

  @$pb.TagNumber(1)
  CapEnumUiState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(CapEnumUiState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  @$pb.TagNumber(2)
  CapPowerSavingMode get powerSavingMode => $_getN(1);
  @$pb.TagNumber(2)
  set powerSavingMode(CapPowerSavingMode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPowerSavingMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearPowerSavingMode() => $_clearField(2);
}

class ResponseGetCapTofState extends $pb.GeneratedMessage {
  factory ResponseGetCapTofState({
    CapTofState? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  ResponseGetCapTofState._();

  factory ResponseGetCapTofState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapTofState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapTofState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapTofState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: CapTofState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapTofState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapTofState copyWith(
          void Function(ResponseGetCapTofState) updates) =>
      super.copyWith((message) => updates(message as ResponseGetCapTofState))
          as ResponseGetCapTofState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapTofState create() => ResponseGetCapTofState._();
  @$core.override
  ResponseGetCapTofState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapTofState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapTofState>(create);
  static ResponseGetCapTofState? _defaultInstance;

  @$pb.TagNumber(1)
  CapTofState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(CapTofState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  CapTofState ensureState() => $_ensure(0);
}

class ResponseGetCapSipSensorState extends $pb.GeneratedMessage {
  factory ResponseGetCapSipSensorState({
    CapSipSensorState? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  ResponseGetCapSipSensorState._();

  factory ResponseGetCapSipSensorState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapSipSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapSipSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapSipSensorState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: CapSipSensorState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapSipSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapSipSensorState copyWith(
          void Function(ResponseGetCapSipSensorState) updates) =>
      super.copyWith(
              (message) => updates(message as ResponseGetCapSipSensorState))
          as ResponseGetCapSipSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapSipSensorState create() =>
      ResponseGetCapSipSensorState._();
  @$core.override
  ResponseGetCapSipSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapSipSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapSipSensorState>(create);
  static ResponseGetCapSipSensorState? _defaultInstance;

  @$pb.TagNumber(1)
  CapSipSensorState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(CapSipSensorState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  CapSipSensorState ensureState() => $_ensure(0);
}

class ResponseGetCapHallEffectSensorState extends $pb.GeneratedMessage {
  factory ResponseGetCapHallEffectSensorState({
    CapHallEffectSensorState? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  ResponseGetCapHallEffectSensorState._();

  factory ResponseGetCapHallEffectSensorState.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapHallEffectSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapHallEffectSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapHallEffectSensorState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: CapHallEffectSensorState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapHallEffectSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapHallEffectSensorState copyWith(
          void Function(ResponseGetCapHallEffectSensorState) updates) =>
      super.copyWith((message) =>
              updates(message as ResponseGetCapHallEffectSensorState))
          as ResponseGetCapHallEffectSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapHallEffectSensorState create() =>
      ResponseGetCapHallEffectSensorState._();
  @$core.override
  ResponseGetCapHallEffectSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapHallEffectSensorState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          ResponseGetCapHallEffectSensorState>(create);
  static ResponseGetCapHallEffectSensorState? _defaultInstance;

  @$pb.TagNumber(1)
  CapHallEffectSensorState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(CapHallEffectSensorState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  CapHallEffectSensorState ensureState() => $_ensure(0);
}

class ResponseGetCapBottleSensorState extends $pb.GeneratedMessage {
  factory ResponseGetCapBottleSensorState({
    CapBottleSensorState? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  ResponseGetCapBottleSensorState._();

  factory ResponseGetCapBottleSensorState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapBottleSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapBottleSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapBottleSensorState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: CapBottleSensorState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapBottleSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapBottleSensorState copyWith(
          void Function(ResponseGetCapBottleSensorState) updates) =>
      super.copyWith(
              (message) => updates(message as ResponseGetCapBottleSensorState))
          as ResponseGetCapBottleSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapBottleSensorState create() =>
      ResponseGetCapBottleSensorState._();
  @$core.override
  ResponseGetCapBottleSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapBottleSensorState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapBottleSensorState>(
          create);
  static ResponseGetCapBottleSensorState? _defaultInstance;

  @$pb.TagNumber(1)
  CapBottleSensorState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(CapBottleSensorState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  CapBottleSensorState ensureState() => $_ensure(0);
}

class ResponseGetCapAmbientLightSensorState extends $pb.GeneratedMessage {
  factory ResponseGetCapAmbientLightSensorState({
    CapAmbientLightSensorState? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  ResponseGetCapAmbientLightSensorState._();

  factory ResponseGetCapAmbientLightSensorState.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapAmbientLightSensorState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapAmbientLightSensorState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapAmbientLightSensorState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: CapAmbientLightSensorState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapAmbientLightSensorState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapAmbientLightSensorState copyWith(
          void Function(ResponseGetCapAmbientLightSensorState) updates) =>
      super.copyWith((message) =>
              updates(message as ResponseGetCapAmbientLightSensorState))
          as ResponseGetCapAmbientLightSensorState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapAmbientLightSensorState create() =>
      ResponseGetCapAmbientLightSensorState._();
  @$core.override
  ResponseGetCapAmbientLightSensorState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapAmbientLightSensorState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          ResponseGetCapAmbientLightSensorState>(create);
  static ResponseGetCapAmbientLightSensorState? _defaultInstance;

  @$pb.TagNumber(1)
  CapAmbientLightSensorState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(CapAmbientLightSensorState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  CapAmbientLightSensorState ensureState() => $_ensure(0);
}

class ResponseGetCapAccelerometerState extends $pb.GeneratedMessage {
  factory ResponseGetCapAccelerometerState({
    CapAccelerometerState? state,
  }) {
    final result = create();
    if (state != null) result.state = state;
    return result;
  }

  ResponseGetCapAccelerometerState._();

  factory ResponseGetCapAccelerometerState.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapAccelerometerState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapAccelerometerState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapAccelerometerState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: CapAccelerometerState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapAccelerometerState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapAccelerometerState copyWith(
          void Function(ResponseGetCapAccelerometerState) updates) =>
      super.copyWith(
              (message) => updates(message as ResponseGetCapAccelerometerState))
          as ResponseGetCapAccelerometerState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapAccelerometerState create() =>
      ResponseGetCapAccelerometerState._();
  @$core.override
  ResponseGetCapAccelerometerState createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapAccelerometerState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapAccelerometerState>(
          create);
  static ResponseGetCapAccelerometerState? _defaultInstance;

  @$pb.TagNumber(1)
  CapAccelerometerState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(CapAccelerometerState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  CapAccelerometerState ensureState() => $_ensure(0);
}

class RequestGetCapTofLog extends $pb.GeneratedMessage {
  factory RequestGetCapTofLog({
    CapLogQuery? query,
  }) {
    final result = create();
    if (query != null) result.query = query;
    return result;
  }

  RequestGetCapTofLog._();

  factory RequestGetCapTofLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapTofLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapTofLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapLogQuery>(1, _omitFieldNames ? '' : 'query',
        subBuilder: CapLogQuery.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapTofLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapTofLog copyWith(void Function(RequestGetCapTofLog) updates) =>
      super.copyWith((message) => updates(message as RequestGetCapTofLog))
          as RequestGetCapTofLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapTofLog create() => RequestGetCapTofLog._();
  @$core.override
  RequestGetCapTofLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapTofLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapTofLog>(create);
  static RequestGetCapTofLog? _defaultInstance;

  @$pb.TagNumber(1)
  CapLogQuery get query => $_getN(0);
  @$pb.TagNumber(1)
  set query(CapLogQuery value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);
  @$pb.TagNumber(1)
  CapLogQuery ensureQuery() => $_ensure(0);
}

class RequestGetCapStateLog extends $pb.GeneratedMessage {
  factory RequestGetCapStateLog({
    CapLogQuery? query,
  }) {
    final result = create();
    if (query != null) result.query = query;
    return result;
  }

  RequestGetCapStateLog._();

  factory RequestGetCapStateLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapStateLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapStateLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapLogQuery>(1, _omitFieldNames ? '' : 'query',
        subBuilder: CapLogQuery.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapStateLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapStateLog copyWith(
          void Function(RequestGetCapStateLog) updates) =>
      super.copyWith((message) => updates(message as RequestGetCapStateLog))
          as RequestGetCapStateLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapStateLog create() => RequestGetCapStateLog._();
  @$core.override
  RequestGetCapStateLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapStateLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapStateLog>(create);
  static RequestGetCapStateLog? _defaultInstance;

  @$pb.TagNumber(1)
  CapLogQuery get query => $_getN(0);
  @$pb.TagNumber(1)
  set query(CapLogQuery value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);
  @$pb.TagNumber(1)
  CapLogQuery ensureQuery() => $_ensure(0);
}

class RequestGetCapActivationLog extends $pb.GeneratedMessage {
  factory RequestGetCapActivationLog({
    CapLogQuery? query,
  }) {
    final result = create();
    if (query != null) result.query = query;
    return result;
  }

  RequestGetCapActivationLog._();

  factory RequestGetCapActivationLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapActivationLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapActivationLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapLogQuery>(1, _omitFieldNames ? '' : 'query',
        subBuilder: CapLogQuery.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapActivationLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapActivationLog copyWith(
          void Function(RequestGetCapActivationLog) updates) =>
      super.copyWith(
              (message) => updates(message as RequestGetCapActivationLog))
          as RequestGetCapActivationLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapActivationLog create() => RequestGetCapActivationLog._();
  @$core.override
  RequestGetCapActivationLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapActivationLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapActivationLog>(create);
  static RequestGetCapActivationLog? _defaultInstance;

  @$pb.TagNumber(1)
  CapLogQuery get query => $_getN(0);
  @$pb.TagNumber(1)
  set query(CapLogQuery value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);
  @$pb.TagNumber(1)
  CapLogQuery ensureQuery() => $_ensure(0);
}

class RequestGetCapFaultLog extends $pb.GeneratedMessage {
  factory RequestGetCapFaultLog({
    CapLogQuery? query,
  }) {
    final result = create();
    if (query != null) result.query = query;
    return result;
  }

  RequestGetCapFaultLog._();

  factory RequestGetCapFaultLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetCapFaultLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetCapFaultLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapLogQuery>(1, _omitFieldNames ? '' : 'query',
        subBuilder: CapLogQuery.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapFaultLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetCapFaultLog copyWith(
          void Function(RequestGetCapFaultLog) updates) =>
      super.copyWith((message) => updates(message as RequestGetCapFaultLog))
          as RequestGetCapFaultLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetCapFaultLog create() => RequestGetCapFaultLog._();
  @$core.override
  RequestGetCapFaultLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetCapFaultLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetCapFaultLog>(create);
  static RequestGetCapFaultLog? _defaultInstance;

  @$pb.TagNumber(1)
  CapLogQuery get query => $_getN(0);
  @$pb.TagNumber(1)
  set query(CapLogQuery value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);
  @$pb.TagNumber(1)
  CapLogQuery ensureQuery() => $_ensure(0);
}

class RequestGetActivationCapAdcLog extends $pb.GeneratedMessage {
  factory RequestGetActivationCapAdcLog({
    CapLogQuery? query,
  }) {
    final result = create();
    if (query != null) result.query = query;
    return result;
  }

  RequestGetActivationCapAdcLog._();

  factory RequestGetActivationCapAdcLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetActivationCapAdcLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetActivationCapAdcLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapLogQuery>(1, _omitFieldNames ? '' : 'query',
        subBuilder: CapLogQuery.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetActivationCapAdcLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetActivationCapAdcLog copyWith(
          void Function(RequestGetActivationCapAdcLog) updates) =>
      super.copyWith(
              (message) => updates(message as RequestGetActivationCapAdcLog))
          as RequestGetActivationCapAdcLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetActivationCapAdcLog create() =>
      RequestGetActivationCapAdcLog._();
  @$core.override
  RequestGetActivationCapAdcLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetActivationCapAdcLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetActivationCapAdcLog>(create);
  static RequestGetActivationCapAdcLog? _defaultInstance;

  @$pb.TagNumber(1)
  CapLogQuery get query => $_getN(0);
  @$pb.TagNumber(1)
  set query(CapLogQuery value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);
  @$pb.TagNumber(1)
  CapLogQuery ensureQuery() => $_ensure(0);
}

class RequestGetChargingCapAdcLog extends $pb.GeneratedMessage {
  factory RequestGetChargingCapAdcLog({
    CapLogQuery? query,
  }) {
    final result = create();
    if (query != null) result.query = query;
    return result;
  }

  RequestGetChargingCapAdcLog._();

  factory RequestGetChargingCapAdcLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RequestGetChargingCapAdcLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RequestGetChargingCapAdcLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..aOM<CapLogQuery>(1, _omitFieldNames ? '' : 'query',
        subBuilder: CapLogQuery.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetChargingCapAdcLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RequestGetChargingCapAdcLog copyWith(
          void Function(RequestGetChargingCapAdcLog) updates) =>
      super.copyWith(
              (message) => updates(message as RequestGetChargingCapAdcLog))
          as RequestGetChargingCapAdcLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestGetChargingCapAdcLog create() =>
      RequestGetChargingCapAdcLog._();
  @$core.override
  RequestGetChargingCapAdcLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RequestGetChargingCapAdcLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RequestGetChargingCapAdcLog>(create);
  static RequestGetChargingCapAdcLog? _defaultInstance;

  @$pb.TagNumber(1)
  CapLogQuery get query => $_getN(0);
  @$pb.TagNumber(1)
  set query(CapLogQuery value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => $_clearField(1);
  @$pb.TagNumber(1)
  CapLogQuery ensureQuery() => $_ensure(0);
}

class ResponseGetCapTofLog extends $pb.GeneratedMessage {
  factory ResponseGetCapTofLog({
    $core.Iterable<CapTofLog>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResponseGetCapTofLog._();

  factory ResponseGetCapTofLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapTofLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapTofLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..pPM<CapTofLog>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CapTofLog.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapTofLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapTofLog copyWith(void Function(ResponseGetCapTofLog) updates) =>
      super.copyWith((message) => updates(message as ResponseGetCapTofLog))
          as ResponseGetCapTofLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapTofLog create() => ResponseGetCapTofLog._();
  @$core.override
  ResponseGetCapTofLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapTofLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapTofLog>(create);
  static ResponseGetCapTofLog? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CapTofLog> get items => $_getList(0);
}

class ResponseGetCapStateLog extends $pb.GeneratedMessage {
  factory ResponseGetCapStateLog({
    $core.Iterable<CapStateLog>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResponseGetCapStateLog._();

  factory ResponseGetCapStateLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapStateLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapStateLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..pPM<CapStateLog>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CapStateLog.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapStateLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapStateLog copyWith(
          void Function(ResponseGetCapStateLog) updates) =>
      super.copyWith((message) => updates(message as ResponseGetCapStateLog))
          as ResponseGetCapStateLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapStateLog create() => ResponseGetCapStateLog._();
  @$core.override
  ResponseGetCapStateLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapStateLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapStateLog>(create);
  static ResponseGetCapStateLog? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CapStateLog> get items => $_getList(0);
}

class ResponseGetCapActivationLog extends $pb.GeneratedMessage {
  factory ResponseGetCapActivationLog({
    $core.Iterable<CapActivationLog>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResponseGetCapActivationLog._();

  factory ResponseGetCapActivationLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapActivationLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapActivationLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..pPM<CapActivationLog>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CapActivationLog.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapActivationLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapActivationLog copyWith(
          void Function(ResponseGetCapActivationLog) updates) =>
      super.copyWith(
              (message) => updates(message as ResponseGetCapActivationLog))
          as ResponseGetCapActivationLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapActivationLog create() =>
      ResponseGetCapActivationLog._();
  @$core.override
  ResponseGetCapActivationLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapActivationLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapActivationLog>(create);
  static ResponseGetCapActivationLog? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CapActivationLog> get items => $_getList(0);
}

class ResponseGetCapFaultLog extends $pb.GeneratedMessage {
  factory ResponseGetCapFaultLog({
    $core.Iterable<CapFaultLog>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResponseGetCapFaultLog._();

  factory ResponseGetCapFaultLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetCapFaultLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetCapFaultLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..pPM<CapFaultLog>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CapFaultLog.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapFaultLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetCapFaultLog copyWith(
          void Function(ResponseGetCapFaultLog) updates) =>
      super.copyWith((message) => updates(message as ResponseGetCapFaultLog))
          as ResponseGetCapFaultLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetCapFaultLog create() => ResponseGetCapFaultLog._();
  @$core.override
  ResponseGetCapFaultLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetCapFaultLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetCapFaultLog>(create);
  static ResponseGetCapFaultLog? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CapFaultLog> get items => $_getList(0);
}

class ResponseGetActivationCapAdcLog extends $pb.GeneratedMessage {
  factory ResponseGetActivationCapAdcLog({
    $core.Iterable<CapAdcLog>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResponseGetActivationCapAdcLog._();

  factory ResponseGetActivationCapAdcLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetActivationCapAdcLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetActivationCapAdcLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..pPM<CapAdcLog>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CapAdcLog.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetActivationCapAdcLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetActivationCapAdcLog copyWith(
          void Function(ResponseGetActivationCapAdcLog) updates) =>
      super.copyWith(
              (message) => updates(message as ResponseGetActivationCapAdcLog))
          as ResponseGetActivationCapAdcLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetActivationCapAdcLog create() =>
      ResponseGetActivationCapAdcLog._();
  @$core.override
  ResponseGetActivationCapAdcLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetActivationCapAdcLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetActivationCapAdcLog>(create);
  static ResponseGetActivationCapAdcLog? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CapAdcLog> get items => $_getList(0);
}

class ResponseGetChargingCapAdcLog extends $pb.GeneratedMessage {
  factory ResponseGetChargingCapAdcLog({
    $core.Iterable<CapAdcLog>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ResponseGetChargingCapAdcLog._();

  factory ResponseGetChargingCapAdcLog.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ResponseGetChargingCapAdcLog.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResponseGetChargingCapAdcLog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bottle'),
      createEmptyInstance: create)
    ..pPM<CapAdcLog>(1, _omitFieldNames ? '' : 'items',
        subBuilder: CapAdcLog.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetChargingCapAdcLog clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResponseGetChargingCapAdcLog copyWith(
          void Function(ResponseGetChargingCapAdcLog) updates) =>
      super.copyWith(
              (message) => updates(message as ResponseGetChargingCapAdcLog))
          as ResponseGetChargingCapAdcLog;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResponseGetChargingCapAdcLog create() =>
      ResponseGetChargingCapAdcLog._();
  @$core.override
  ResponseGetChargingCapAdcLog createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ResponseGetChargingCapAdcLog getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResponseGetChargingCapAdcLog>(create);
  static ResponseGetChargingCapAdcLog? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CapAdcLog> get items => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
