import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'package:bottle/models/sensor_data.dart';

class SensorRow<T> extends StatelessWidget {
  final String label;
  final Signal<SensorValue<T>> signal;
  final String Function(T) formatter;

  const SensorRow({
    super.key,
    required this.label,
    required this.signal,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final value = signal.value;
      return Row(children: [
        SizedBox(width: 130, child: Text(label)),
        Expanded(
            child: switch (value) {
          SensorNotQueried() =>
            const Text('\u2014', style: TextStyle(color: Colors.grey)),
          SensorLoading() => const Row(children: [
            SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('loading...', style: TextStyle(color: Colors.grey)),
          ]),
          SensorData(value: final v, refreshing: final refreshing) => Row(
              children: [
                Flexible(child: Text(formatter(v))),
                if (refreshing) ...[
                  const SizedBox(width: 8),
                  const SizedBox.square(
                      dimension: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5)),
                ],
              ]),
          SensorError(message: final msg) =>
            Flexible(child: Text('Error: $msg', style: const TextStyle(color: Colors.red))),
        }),
      ]);
    });
  }
}
