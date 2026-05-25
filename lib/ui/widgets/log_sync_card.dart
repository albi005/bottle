import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/models/bottle_device.dart';

class LogSyncCard extends StatelessWidget {
  final BottleController controller;

  const LogSyncCard({super.key, required this.controller});

  static const _logTypeOrder = [
    'TOF Log',
    'Activation Log',
    'Fault Log',
    'State Log',
    'Activation ADC Log',
    'Charging ADC Log',
  ];

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final phase = controller.logSyncPhase.value;
      final (currentType, cursor) = controller.logSyncProgress.value;
      final synced = controller.logTypesSynced.value;
      final error = controller.logSyncError.value;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log Sync',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              switch (phase) {
                LogSyncPhase.idle => const Text('Idle',
                    style: TextStyle(color: Colors.grey)),
                LogSyncPhase.syncing ||
                LogSyncPhase.done =>
                  Column(children: [
                    for (final t in _logTypeOrder)
                      _logTypeRow(
                        label: t,
                        isCurrent:
                            t == currentType && phase == LogSyncPhase.syncing,
                        isDone: synced.contains(t) ||
                            phase == LogSyncPhase.done,
                        cursor: t == currentType ? cursor : null,
                      ),
                  ]),
                LogSyncPhase.error => Text('Error: $error',
                    style: const TextStyle(color: Colors.red)),
              },
              const Divider(),
              _healthStatus(),
            ],
          ),
        ),
      );
    });
  }

  Widget _healthStatus() {
    return Watch((_) {
      final available = controller.healthAvailable.value;
      final perms = controller.healthPermissionsGranted.value;
      final error = controller.healthSyncError.value;

      return Row(children: [
        const Icon(Icons.water_drop, size: 14),
        const SizedBox(width: 4),
        Text('Health Connect',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: error != null ? Colors.red : null,
            )),
        const Spacer(),
        if (error != null)
          Flexible(
            child: Text('error',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.red)),
          )
        else if (available == null)
          const Text('...', style: TextStyle(fontSize: 11, color: Colors.grey))
        else if (!available)
          const Text('unavailable',
              style: TextStyle(fontSize: 11, color: Colors.grey))
        else if (perms == false)
          const Text('denied',
              style: TextStyle(fontSize: 11, color: Colors.orange))
        else if (perms == true)
          const Text('synced',
              style: TextStyle(fontSize: 11, color: Colors.green))
        else
          const Text('checking',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
      ]);
    });
  }

  Widget _logTypeRow({
    required String label,
    required bool isCurrent,
    required bool isDone,
    int? cursor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        if (isCurrent)
          const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5))
        else if (isDone)
          const Icon(Icons.check, size: 14, color: Colors.green)
        else
          const Icon(Icons.remove, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label),
        if (cursor != null) ...[
          const Spacer(),
          Text('cursor: $cursor',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ]),
    );
  }
}
