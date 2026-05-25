import 'package:flutter/material.dart';
import 'package:protobuf/protobuf.dart';

import 'package:bottle/state/bottle_controller.dart';
import 'package:bottle/db/log_repository.dart';
import 'package:bottle/protos/cap.pbenum.dart';

String _fmtTimestamp(dynamic ts) {
  final s = (ts is int) ? ts : int.tryParse(ts.toString()) ?? 0;
  if (s <= 0) return 'unknown';
  final dt =
      DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true).toLocal();
  return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
      '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _enumNameOrUnknown(dynamic value, List<ProtobufEnum> values) {
  final v = (value is int) ? value : int.tryParse(value.toString()) ?? -1;
  for (final e in values) {
    if (e.value == v) return e.name;
  }
  return '?($v)';
}

class LogListView extends StatefulWidget {
  final String table;
  final String label;
  final BottleController controller;
  final Widget Function(Map<String, dynamic>) entryBuilder;

  const LogListView({
    super.key,
    required this.table,
    required this.label,
    required this.controller,
    required this.entryBuilder,
  });

  @override
  State<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView> {
  final _scrollController = ScrollController();
  final _entries = <Map<String, dynamic>>[];
  bool _isLoading = false;
  bool _hasMore = true;
  int _syncedSetSize = 0;
  bool _alive = true;

  static const _pageSize = 30;

  String get _table => widget.table;
  String get _bottleName => widget.controller.name;
  String get _label => widget.label;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage();
  }

  @override
  void dispose() {
    _alive = false;
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final repo = await LogRepository.instance;
      final rows = await repo.getLogs(_table, _bottleName,
          limit: _pageSize, offset: _entries.length);
      if (!_alive || !mounted) return;
      setState(() {
        _entries.addAll(rows);
        _isLoading = false;
        _hasMore = rows.length == _pageSize;
      });
    } catch (_) {
      if (_alive && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _maybeRefresh() async {
    final synced = widget.controller.logTypesSynced.value;
    if (!synced.contains(_label)) return;
    if (synced.length == _syncedSetSize) return;
    _syncedSetSize = synced.length;

    final existingMaxTs =
        _entries.isEmpty ? 0 : (_entries.first['timestamp'] as int? ?? 0);
    try {
      final repo = await LogRepository.instance;
      final latest = await repo.getLogs(_table, _bottleName, limit: _pageSize);
      if (!_alive || !mounted) return;

      final newEntries = latest
          .where((e) => (e['timestamp'] as int) > existingMaxTs)
          .toList();
      if (newEntries.isNotEmpty) {
        setState(() => _entries.insertAll(0, newEntries));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefresh());

    if (_entries.isEmpty && !_isLoading) {
      return const Center(
          child: Text('No entries', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _entries.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _entries.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return widget.entryBuilder(_entries[index]);
      },
    );
  }
}

class TofLogView extends StatelessWidget {
  final BottleController controller;

  const TofLogView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LogListView(
      table: 'tof_logs',
      label: 'TOF Log',
      controller: controller,
      entryBuilder: (e) => _logCard([
        _fmtTimestamp(e['timestamp']),
        '${_enumNameOrUnknown(e['trigger_type'], CapEnumTofTriggerType.values)} '
            '| ${e['distance_mm']} mm '
            '| ${e['kcps']} kcps '
            '| UV ${e['uv_led_temp_ohm']} \u03a9',
      ]),
    );
  }
}

class ActivationLogView extends StatelessWidget {
  final BottleController controller;

  const ActivationLogView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LogListView(
      table: 'activation_logs',
      label: 'Activation Log',
      controller: controller,
      entryBuilder: (e) => _logCard([
        _fmtTimestamp(e['timestamp']),
        '${_enumNameOrUnknown(e['mode'], CapEnumUvActivationMode.values)} '
            '| ${e['battery_soc_percentage']}% SOC',
      ]),
    );
  }
}

class FaultLogView extends StatelessWidget {
  final BottleController controller;

  const FaultLogView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LogListView(
      table: 'fault_logs',
      label: 'Fault Log',
      controller: controller,
      entryBuilder: (e) => _logCard([
        _fmtTimestamp(e['timestamp']),
        _enumNameOrUnknown(e['type'], CapEnumFaultType.values),
      ]),
    );
  }
}

class StateLogView extends StatelessWidget {
  final BottleController controller;

  const StateLogView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LogListView(
      table: 'state_logs',
      label: 'State Log',
      controller: controller,
      entryBuilder: (e) {
        final hall = (e['hall'] as int?) == 1;
        final bottle = (e['bottle_detection'] as int?) == 1;
        final ambient = (e['ambient_light'] as int?) == 1;
        final sip = (e['sip_detection'] as int?) == 1;
        return _logCard([
          _fmtTimestamp(e['timestamp']),
          'Hall:${hall ? "closed" : "open"} '
              'Bottle:$bottle '
              'Ambient:$ambient '
              'Sip:$sip',
          'Cap: ${e['bottle_detection_cap_value']} '
              '/ ${e['ambient_light_sensor_value']} '
              '/ ${e['sip_detection_cap_sensor_value']}',
        ]);
      },
    );
  }
}

class ActivationAdcLogView extends StatelessWidget {
  final BottleController controller;

  const ActivationAdcLogView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LogListView(
      table: 'activation_adc_logs',
      label: 'Activation ADC Log',
      controller: controller,
      entryBuilder: _adcEntryBuilder,
    );
  }
}

class ChargingAdcLogView extends StatelessWidget {
  final BottleController controller;

  const ChargingAdcLogView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LogListView(
      table: 'charging_adc_logs',
      label: 'Charging ADC Log',
      controller: controller,
      entryBuilder: _adcEntryBuilder,
    );
  }
}

Widget _adcEntryBuilder(Map<String, dynamic> e) => _logCard([
      _fmtTimestamp(e['timestamp']),
      'Batt: ${e['battery_volt']}V ${e['battery_temp_ohm']}\u03a9 '
          '| UV: ${e['uv_led_volt']}V ${e['uv_led_current_ma']}mA '
          '${e['uv_led_temp_ohm']}\u03a9 '
          '| PCB: ${e['c_pcb_temp_ohm']}\u03a9',
    ]);

Widget _logCard(List<String> lines) => Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Text(line,
                  style: TextStyle(
                    fontSize: line == lines.first ? 11 : 13,
                    color: line == lines.first ? Colors.grey : null,
                  )),
          ],
        ),
      ),
    );
