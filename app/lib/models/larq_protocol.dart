// LARQ PureVis 2 BLE Protocol Definitions
// Reverse-engineered from LARQ app v1.6.1 (build 71)

// --- BLE Identifiers ---

class LarqBleUuids {
  static const String serviceUart =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String charTx =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // Notify (bottle→phone)
  static const String charRx =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // Write (phone→bottle)
  static const String charFlowCtrl =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e'; // The 001 UUID is the service

  static const String serviceDeviceInfo =
      '0000180a-0000-1000-8000-00805f9b34fb';
  static const String serviceBattery =
      '0000180f-0000-1000-8000-00805f9b34fb';
  static const String charBatteryLevel =
      '00002a19-0000-1000-8000-00805f9b34fb';
  static const String charModelNumber =
      '00002a24-0000-1000-8000-00805f9b34fb';
  static const String charSerialNumber =
      '00002a25-0000-1000-8000-00805f9b34fb';
  static const String charFirmwareRevision =
      '00002a26-0000-1000-8000-00805f9b34fb';
  static const String charHardwareRevision =
      '00002a27-0000-1000-8000-00805f9b34fb';
  static const String charSoftwareRevision =
      '00002a28-0000-1000-8000-00805f9b34fb';

  static const String serviceDfu =
      '0000FE59-0000-1000-8000-00805F9B34FB';
  static const String charDfuControl =
      '8EC90003-F315-4F60-9FB8-838830DAEA50';

  // The bottle advertises with the UART service UUID
  static List<String> get scanUuids => [serviceUart];

  // Known bottle MAC for auto-connect
  static const String knownBottleRemoteId = '56:D3:EA:9B:A5:6A';
}

// --- Enums ---

enum CapEnumResponseCode {
  fail(0),
  success(1),
  notSupported(2);

  final int value;
  const CapEnumResponseCode(this.value);

  static CapEnumResponseCode fromValue(int v) {
    return CapEnumResponseCode.values
        .firstWhere((e) => e.value == v, orElse: () => fail);
  }
}

enum CapEnumUvActivationMode {
  maintenance(0),
  standard(1),
  adventure(2),
  stop(3);

  final int value;
  const CapEnumUvActivationMode(this.value);
}

enum CapEnumUiState {
  on(0),
  fault(1),
  uvMaintenance(2),
  uvNormal(3),
  uvAdventure(4),
  paired(5),
  hydrationReminder(6),
  batteryLow(7),
  charging(8),
  charged(9),
  uvInterlock(10),
  bottleCalibration(11),
  tofMeasurement(12),
  turnOff(13),
  factoryReset(14),
  allOff(15),
  locked(16),
  qc(17),
  last(18);

  final int value;
  const CapEnumUiState(this.value);

  static CapEnumUiState fromValue(int v) {
    return CapEnumUiState.values
        .firstWhere((e) => e.value == v, orElse: () => on);
  }
}

enum CapEnumTofTriggerType {
  request(0),
  interval(1),
  cap(2),
  capOnFlap(3),
  capOnFlapOpenSip(4);

  final int value;
  const CapEnumTofTriggerType(this.value);

  static CapEnumTofTriggerType fromValue(int v) {
    return CapEnumTofTriggerType.values
        .firstWhere((e) => e.value == v, orElse: () => request);
  }
}

enum CapEnumFaultType {
  uvOvertemp(0),
  uvLedShort(1),
  uvLedOpen(2),
  batteryTemp(3),
  batteryOpen(4),
  batteryShort(5),
  ambientLight(6);

  final int value;
  const CapEnumFaultType(this.value);

  static CapEnumFaultType fromValue(int v) {
    return CapEnumFaultType.values
        .firstWhere((e) => e.value == v, orElse: () => uvOvertemp);
  }
}

enum CapEnumDoNotDisturbState {
  off(0),
  on(1),
  auto(2);

  final int value;
  const CapEnumDoNotDisturbState(this.value);
}

enum CapEnumHydroReminderState {
  off(0),
  intervalFixed(1),
  intervalAdaptive(2);

  final int value;
  const CapEnumHydroReminderState(this.value);
}

enum CapPowerSavingMode {
  off(0),
  on(1),
  auto(2);

  final int value;
  const CapPowerSavingMode(this.value);

  static CapPowerSavingMode fromValue(int v) {
    return CapPowerSavingMode.values
        .firstWhere((e) => e.value == v, orElse: () => off);
  }
}

// --- Data Types ---

class CapTofLog {
  final int timestamp;
  final CapEnumTofTriggerType triggerType;
  final int distanceInMillimeter;
  final int kcps;
  final double uvLedTempInOhm;

  const CapTofLog({
    required this.timestamp,
    required this.triggerType,
    required this.distanceInMillimeter,
    required this.kcps,
    required this.uvLedTempInOhm,
  });

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

class CapTofState {
  final int distanceInMillimeter;
  final int kcps;

  const CapTofState({
    required this.distanceInMillimeter,
    required this.kcps,
  });
}

class CapBottleSensorState {
  final int value;
  final bool state;

  const CapBottleSensorState({required this.value, required this.state});
}

class CapSipSensorState {
  final int value;
  final bool state;

  const CapSipSensorState({required this.value, required this.state});
}

class CapAccelerometerState {
  final double x;
  final double y;
  final double z;

  const CapAccelerometerState({
    required this.x,
    required this.y,
    required this.z,
  });
}

class CapAmbientLightSensorState {
  final int value;

  const CapAmbientLightSensorState({required this.value});
}

class CapHallEffectSensorState {
  final bool state;

  const CapHallEffectSensorState({required this.state});
}

class CapActivationLog {
  final int timestamp;
  final CapEnumUvActivationMode mode;
  final int batterySocInPercentage;

  const CapActivationLog({
    required this.timestamp,
    required this.mode,
    required this.batterySocInPercentage,
  });

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}

class CapFaultLog {
  final int timestamp;
  final CapEnumFaultType type;

  const CapFaultLog({required this.timestamp, required this.type});
}

class CapUvConfig {
  final CapEnumUvActivationMode mode;
  final int durationInSeconds;

  const CapUvConfig({required this.mode, required this.durationInSeconds});
}

class CapAdcLog {
  final int timestamp;
  final double batteryInVolt;
  final double batteryTempInOhm;
  final double uvLedInVolt;
  final double uvLedCurrentInMilliamps;
  final double uvLedTempInOhm;
  final double cPcbTempInOhm;

  const CapAdcLog({
    required this.timestamp,
    required this.batteryInVolt,
    required this.batteryTempInOhm,
    required this.uvLedInVolt,
    required this.uvLedCurrentInMilliamps,
    required this.uvLedTempInOhm,
    required this.cPcbTempInOhm,
  });
}

// --- Device Info ---

class LarqDeviceInfo {
  final String modelNumber;
  final String serialNumber;
  final String firmwareRevision;
  final String hardwareRevision;
  final String softwareRevision;

  const LarqDeviceInfo({
    this.modelNumber = '',
    this.serialNumber = '',
    this.firmwareRevision = '',
    this.hardwareRevision = '',
    this.softwareRevision = '',
  });

  LarqDeviceInfo copyWith({
    String? modelNumber,
    String? serialNumber,
    String? firmwareRevision,
    String? hardwareRevision,
    String? softwareRevision,
  }) {
    return LarqDeviceInfo(
      modelNumber: modelNumber ?? this.modelNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      firmwareRevision: firmwareRevision ?? this.firmwareRevision,
      hardwareRevision: hardwareRevision ?? this.hardwareRevision,
      softwareRevision: softwareRevision ?? this.softwareRevision,
    );
  }
}

// --- Protocol message type identifiers ---

enum CapBleRequestType {
  // GET requests
  getCapBottleSensorState,
  getCapUvConfig,
  getCapTofLog,
  getCapTofSettings,
  getCapTofState,
  getCapTimeSettings,
  getCapLowBatterySettings,
  getCapHydroReminderSettings,
  getCapDoNotDisturbSettings,
  getCapAdcProtectionSettings,
  getCapCalibrationSettings,
  getCapStateThresholdSettings,
  getCapAccelerometerState,
  getCapAmbientLightSensorState,
  getCapHallEffectSensorState,
  getCapSipSensorState,
  getCapFaultLog,
  getCapStateLog,
  getCapActivationLog,
  getActivationCapAdcLog,
  getChargingCapAdcLog,
  getCapUiState,
  // SET requests
  setCapBottleSensorState,
  setCapUvConfig,
  setCapUvActivate,
  setCapTofSettings,
  setCapTimeSettings,
  setCapLowBatterySettings,
  setCapHydroReminderSettings,
  setCapDoNotDisturbSettings,
  setCapAdcProtectionSettings,
  setCapCalibrationSettings,
  setCapStateThresholdSettings,
  setCapPowerSavingMode,
  // Commands
  enterDfuMode,
  enterLowBatteryMode,
  factoryReset,
  startCapCalibration,
  stopCapCalibration,
}

// Map request types to their Any type_url strings (no package prefix in proto)
const Map<CapBleRequestType, String> requestTypeUrls = {
  CapBleRequestType.getCapBottleSensorState:
      'type.googleapis.com/RequestGetCapBottleSensorState',
  CapBleRequestType.getCapUvConfig:
      'type.googleapis.com/RequestGetCapUvConfig',
  CapBleRequestType.getCapTofLog:
      'type.googleapis.com/RequestGetCapTofLog',
  CapBleRequestType.getCapTofSettings:
      'type.googleapis.com/RequestGetCapTofSettings',
  CapBleRequestType.getCapTofState:
      'type.googleapis.com/RequestGetCapTofState',
  CapBleRequestType.getCapTimeSettings:
      'type.googleapis.com/RequestGetCapTimeSettings',
  CapBleRequestType.getCapLowBatterySettings:
      'type.googleapis.com/RequestGetCapLowBatterySettings',
  CapBleRequestType.getCapHydroReminderSettings:
      'type.googleapis.com/RequestGetCapHydroReminderSettings',
  CapBleRequestType.getCapDoNotDisturbSettings:
      'type.googleapis.com/RequestGetCapDoNotDisturbSettings',
  CapBleRequestType.getCapAdcProtectionSettings:
      'type.googleapis.com/RequestGetCapAdcProtectionSettings',
  CapBleRequestType.getCapCalibrationSettings:
      'type.googleapis.com/RequestGetCapCalibrationSettings',
  CapBleRequestType.getCapStateThresholdSettings:
      'type.googleapis.com/RequestGetCapStateThresholdSettings',
  CapBleRequestType.getCapAccelerometerState:
      'type.googleapis.com/RequestGetCapAccelerometerState',
  CapBleRequestType.getCapAmbientLightSensorState:
      'type.googleapis.com/RequestGetCapAmbientLightSensorState',
  CapBleRequestType.getCapHallEffectSensorState:
      'type.googleapis.com/RequestGetCapHallEffectSensorState',
  CapBleRequestType.getCapSipSensorState:
      'type.googleapis.com/RequestGetCapSipSensorState',
  CapBleRequestType.getCapFaultLog:
      'type.googleapis.com/RequestGetCapFaultLog',
  CapBleRequestType.getCapStateLog:
      'type.googleapis.com/RequestGetCapStateLog',
  CapBleRequestType.getCapActivationLog:
      'type.googleapis.com/RequestGetCapActivationLog',
  CapBleRequestType.getActivationCapAdcLog:
      'type.googleapis.com/RequestGetActivationCapAdcLog',
  CapBleRequestType.getChargingCapAdcLog:
      'type.googleapis.com/RequestGetChargingCapAdcLog',
  CapBleRequestType.getCapUiState:
      'type.googleapis.com/RequestGetCapUiState',
  CapBleRequestType.setCapBottleSensorState:
      'type.googleapis.com/RequestSetCapBottleSensorState',
  CapBleRequestType.setCapUvConfig:
      'type.googleapis.com/RequestSetCapUvConfig',
  CapBleRequestType.setCapUvActivate:
      'type.googleapis.com/RequestSetCapUvActivate',
  CapBleRequestType.setCapTofSettings:
      'type.googleapis.com/RequestSetCapTofSettings',
  CapBleRequestType.setCapTimeSettings:
      'type.googleapis.com/RequestSetCapTimeSettings',
  CapBleRequestType.setCapLowBatterySettings:
      'type.googleapis.com/RequestSetCapLowBatterySettings',
  CapBleRequestType.setCapHydroReminderSettings:
      'type.googleapis.com/RequestSetCapHydroReminderSettings',
  CapBleRequestType.setCapDoNotDisturbSettings:
      'type.googleapis.com/RequestSetCapDoNotDisturbSettings',
  CapBleRequestType.setCapAdcProtectionSettings:
      'type.googleapis.com/RequestSetCapAdcProtectionSettings',
  CapBleRequestType.setCapCalibrationSettings:
      'type.googleapis.com/RequestSetCapCalibrationSettings',
  CapBleRequestType.setCapStateThresholdSettings:
      'type.googleapis.com/RequestSetCapStateThresholdSettings',
  CapBleRequestType.setCapPowerSavingMode:
      'type.googleapis.com/RequestSetCapPowerSavingMode',
  CapBleRequestType.enterDfuMode:
      'type.googleapis.com/RequestCapEnterDfuMode',
  CapBleRequestType.enterLowBatteryMode:
      'type.googleapis.com/RequestCapEnterLowBatteryMode',
  CapBleRequestType.factoryReset:
      'type.googleapis.com/RequestCapFactoryReset',
  CapBleRequestType.startCapCalibration:
      'type.googleapis.com/RequestCapStartCapCalibration',
  CapBleRequestType.stopCapCalibration:
      'type.googleapis.com/RequestCapStopCapCalibration',
};
