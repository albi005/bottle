import 'package:flutter/material.dart';

import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/models/bottle_device.dart';
import 'package:bottle/ui/widgets/sensor_row.dart';

class SensorDashboard extends StatelessWidget {
  final BottleController controller;

  const SensorDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('Sensors',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        SensorRow<CapUiStateData>(
          label: 'UI State',
          signal: controller.uiState,
          formatter: (v) => '${v.state.name} / ${v.powerSavingMode.name}',
        ),
        SensorRow<int>(
          label: 'TOF Distance',
          signal: controller.tofDistance,
          formatter: (v) => '$v mm',
        ),
        SensorRow<int>(
          label: 'Sip Counter',
          signal: controller.sipCounter,
          formatter: (v) => '$v',
        ),
        SensorRow<HallEffectData>(
          label: 'Hall Effect',
          signal: controller.hallEffect,
          formatter: (v) => v.value ? 'Open' : 'Closed',
        ),
        SensorRow<bool>(
          label: 'Bottle Present',
          signal: controller.bottlePresent,
          formatter: (v) => v ? 'Yes' : 'No',
        ),
        SensorRow<double>(
          label: 'Ambient Light',
          signal: controller.ambientLight,
          formatter: (v) => '${v.toStringAsFixed(1)} lux',
        ),
        SensorRow<AccelData>(
          label: 'Accelerometer',
          signal: controller.accelerometer,
          formatter: (v) =>
              'x:${v.x.toStringAsFixed(1)} y:${v.y.toStringAsFixed(1)} z:${v.z.toStringAsFixed(1)}',
        ),
        SensorRow<int>(
          label: 'Battery',
          signal: controller.batteryLevel,
          formatter: (v) => '$v%',
        ),
        SensorRow<DeviceInfo>(
          label: 'Device Info',
          signal: controller.deviceInfo,
          formatter: (v) =>
              '${v.model.isNotEmpty ? v.model : '?'} / ${v.firmware.isNotEmpty ? v.firmware : '?'}',
        ),
      ],
    );
  }
}
