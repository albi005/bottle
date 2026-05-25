import 'package:bottle/protos/cap.pbenum.dart';

enum ConnectionPhase { notFound, visible, connecting, discovering, ready, failed }

enum LogSyncPhase { idle, syncing, done, error }

enum RefreshPhase { idle, refreshingSensors, syncingLogs, error }

class DeviceInfo {
  final String model;
  final String firmware;
  const DeviceInfo({required this.model, required this.firmware});
}

class AccelData {
  final double x;
  final double y;
  final double z;
  const AccelData({required this.x, required this.y, required this.z});
}

class HallEffectData {
  final int timestamp;
  final bool value;
  const HallEffectData({required this.timestamp, required this.value});
}

class CapUiStateData {
  final CapEnumUiState state;
  final CapPowerSavingMode powerSavingMode;
  const CapUiStateData({required this.state, required this.powerSavingMode});
}
