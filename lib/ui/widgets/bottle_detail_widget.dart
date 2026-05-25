import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/models/bottle_device.dart';
import 'package:bottle/ui/widgets/sensor_dashboard.dart';
import 'package:bottle/ui/widgets/log_sync_card.dart';
import 'package:bottle/ui/widgets/log_viewer.dart';

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

      return Column(children: [
        Flexible(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(children: [
              SensorDashboard(controller: controller),
              const Divider(),
              LogSyncCard(controller: controller),
            ]),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 6,
          child: DefaultTabController(
            length: 6,
            child: Column(children: [
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'TOF'),
                  Tab(text: 'Activ.'),
                  Tab(text: 'Fault'),
                  Tab(text: 'State'),
                  Tab(text: 'ADC Act'),
                  Tab(text: 'ADC Chg'),
                ],
              ),
              Expanded(
                child: TabBarView(children: [
                  TofLogView(controller: controller),
                  ActivationLogView(controller: controller),
                  FaultLogView(controller: controller),
                  StateLogView(controller: controller),
                  ActivationAdcLogView(controller: controller),
                  ChargingAdcLogView(controller: controller),
                ]),
              ),
            ]),
          ),
        ),
      ]);
    });
  }
}
