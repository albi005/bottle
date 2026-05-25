import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/models/bottle_device.dart';
import 'package:bottle/ui/widgets/sensor_dashboard.dart';
import 'package:bottle/ui/widgets/log_sync_card.dart';

class BottleDetailWidget extends StatelessWidget {
  final BottleController controller;

  const BottleDetailWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final phase = controller.connectionPhase.value;

      if (phase != ConnectionPhase.ready) {
        return Center(child: Text('Bottle is ${phase.name}'));
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          SensorDashboard(controller: controller),
          const Divider(),
          LogSyncCard(controller: controller),
        ]),
      );
    });
  }
}
