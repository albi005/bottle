import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/models/bottle_device.dart';

class BottleListTile extends StatelessWidget {
  final BottleController controller;
  final bool selected;
  final VoidCallback onTap;

  const BottleListTile({
    super.key,
    required this.controller,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final phase = controller.connectionPhase.value;
      final rssi = controller.rssi.value;
      final refresh = controller.refreshPhase.value;
      final error = controller.connectionError.value;

      return ListTile(
        selected: selected,
        title: Text(controller.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _phaseIcon(phase),
              const SizedBox(width: 4),
              Text(phase.name),
              if (rssi != null) Text('  RSSI: $rssi dBm'),
            ]),
            if (error != null)
              Text('Error: $error',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            if (phase == ConnectionPhase.ready)
              Text(
                switch (refresh) {
                  RefreshPhase.refreshingSensors => 'Refreshing sensors...',
                  RefreshPhase.syncingLogs => 'Syncing logs...',
                  RefreshPhase.error => 'Refresh error',
                  _ => 'Idle',
                },
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: switch (phase) {
          ConnectionPhase.connecting || ConnectionPhase.discovering =>
            const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ConnectionPhase.ready => IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: () => controller.disconnect()),
          ConnectionPhase.visible || ConnectionPhase.failed => IconButton(
              icon: Icon(phase == ConnectionPhase.failed
                  ? Icons.refresh
                  : Icons.bluetooth),
              onPressed: () {
                final sr = controller.scanResult.value;
                if (sr != null) controller.connect(sr);
              }),
          _ => null,
        },
        onTap: onTap,
      );
    });
  }

  Widget _phaseIcon(ConnectionPhase phase) => Icon(
        switch (phase) {
          ConnectionPhase.visible => Icons.bluetooth_searching,
          ConnectionPhase.connecting ||
          ConnectionPhase.discovering =>
            Icons.bluetooth_connected,
          ConnectionPhase.ready => Icons.check_circle,
          ConnectionPhase.failed => Icons.error,
          ConnectionPhase.notFound => Icons.bluetooth_disabled,
        },
        size: 16,
      );
}
