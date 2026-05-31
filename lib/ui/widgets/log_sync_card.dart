import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/models/bottle_device.dart';

String _fmtTs(int ts) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

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
              const Text(
                'Log Sync',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              switch (phase) {
                LogSyncPhase.idle => Text(
                  'Idle',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                LogSyncPhase.syncing || LogSyncPhase.done => Column(
                  children: [
                    for (final t in _logTypeOrder)
                      _logTypeRow(
                        context: context,
                        label: t,
                        isCurrent:
                            t == currentType && phase == LogSyncPhase.syncing,
                        isDone:
                            synced.contains(t) || phase == LogSyncPhase.done,
                        cursor: t == currentType ? cursor : null,
                      ),
                  ],
                ),
                LogSyncPhase.error => Text(
                  'Error: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              },
              const Divider(),
              _healthStatus(context),
            ],
          ),
        ),
      );
    });
  }

  Widget _healthStatus(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Watch((_) {
      final available = controller.healthAvailable.value;
      final perms = controller.healthPermissionsGranted.value;
      final error = controller.healthSyncError.value;

      return InkWell(
        onTap: (available == true && perms == false)
            ? () => controller.openHealthSettings()
            : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.water_drop, size: 14),
              const SizedBox(width: 4),
              Text(
                'Health Connect',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: error != null ? cs.error : null,
                ),
              ),
              const Spacer(),
              if (error != null)
                Flexible(
                  child: Text(
                    'error',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.error),
                  ),
                )
              else if (available == null)
                Text(
                  '...',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                )
              else if (!available)
                Text(
                  'unavailable',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                )
              else if (perms == false)
                Text(
                  'denied \u2014 tap to open',
                  style: TextStyle(fontSize: 11, color: cs.tertiary),
                )
              else if (perms == true)
                Text(
                  'synced',
                  style: TextStyle(fontSize: 11, color: cs.primary),
                )
              else
                Text(
                  'checking',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _logTypeRow({
    required BuildContext context,
    required String label,
    required bool isCurrent,
    required bool isDone,
    int? cursor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (isCurrent)
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          else if (isDone)
            Icon(Icons.check, size: 14, color: cs.primary)
          else
            Icon(Icons.remove, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label),
          if (cursor != null) ...[
            const Spacer(),
            Text(
              _fmtTs(cursor),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
