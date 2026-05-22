import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/larq_protocol.dart';
import '../services/larq_ble_service.dart';
import '../services/health_connect_service.dart';

class HydrationScreen extends StatefulWidget {
  final LarqBleService bleService;
  final HealthConnectService healthService;

  const HydrationScreen({
    super.key,
    required this.bleService,
    required this.healthService,
  });

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  bool _syncing = false;
  int _syncedCount = 0;
  double _todayWaterMl = 0;
  bool _healthAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkHealthConnect();
  }

  Future<void> _checkHealthConnect() async {
    final authorized = await widget.healthService.authorize();
    if (mounted) {
      setState(() => _healthAuthorized = authorized);
      if (authorized) {
        _fetchTodayWater();
      }
    }
  }

  Future<void> _fetchTodayWater() async {
    final ml = await widget.healthService.getTodayWaterIntake();
    if (mounted) setState(() => _todayWaterMl = ml);
  }

  Future<void> _syncToHealthConnect() async {
    setState(() => _syncing = true);
    try {
      await widget.bleService.fetchAllData();
      final logs = widget.bleService.tofLogs;
      final count = await widget.healthService.syncTofLogsToHealthConnect(logs);
      if (mounted) {
        setState(() => _syncedCount += count);
        _fetchTodayWater();
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Color _triggerColor(CapEnumTofTriggerType type) {
    return switch (type) {
      CapEnumTofTriggerType.capOnFlapOpenSip => Colors.green,
      CapEnumTofTriggerType.capOnFlap => Colors.blue,
      CapEnumTofTriggerType.cap => Colors.orange,
      CapEnumTofTriggerType.interval => Colors.grey,
      CapEnumTofTriggerType.request => Colors.grey,
    };
  }

  String _triggerLabel(CapEnumTofTriggerType type) {
    return switch (type) {
      CapEnumTofTriggerType.capOnFlapOpenSip => 'Sip Detected',
      CapEnumTofTriggerType.capOnFlap => 'Cap + Flap',
      CapEnumTofTriggerType.cap => 'Cap Removed',
      CapEnumTofTriggerType.interval => 'Interval',
      CapEnumTofTriggerType.request => 'Request',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tofLogs = widget.bleService.tofLogs;
    final activationLogs = widget.bleService.activationLogs;
    final faultLogs = widget.bleService.faultLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration & Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await widget.bleService.fetchAllData();
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Health Connect section
          Card(
            color: widget.healthService.isSupported
                ? Colors.teal.shade50
                : Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health Connect',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (!widget.healthService.isSupported)
                    const Text('Not available on this platform',
                        style: TextStyle(color: Colors.grey))
                  else if (_healthAuthorized)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Today\'s Intake: ${_todayWaterMl.toStringAsFixed(0)} ml',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 4),
                        const Text(
                            'Volume computed from ToF water level changes\n'
                            '(bottle cross-section: ~38.5 cm\u00B2)',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        if (_syncedCount > 0)
                          Text('$_syncedCount events synced',
                              style:
                                  const TextStyle(color: Colors.green)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _syncing ? null : _syncToHealthConnect,
                            icon: _syncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(
                                _syncing ? 'Syncing...' : 'Sync ToF Logs to Health Connect'),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        const Text('Health Connect not authorized'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _checkHealthConnect,
                          child: const Text('Authorize'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ToF Logs (drinking events)
          Text('ToF Sensor Logs (${tofLogs.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (tofLogs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No ToF logs available'),
              ),
            )
          else
            ...tofLogs.reversed.take(50).map((log) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _triggerColor(log.triggerType),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      DateFormat('HH:mm:ss').format(log.dateTime),
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${_triggerLabel(log.triggerType)} | ${log.distanceInMillimeter}mm | ${log.kcps} kcps',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )),

          const SizedBox(height: 16),

          // Activation Logs
          Text('UV Activations (${activationLogs.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (activationLogs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No activation logs'),
              ),
            )
          else
            ...activationLogs.reversed.take(20).map((log) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.water_drop,
                      color: log.mode == CapEnumUvActivationMode.adventure
                          ? Colors.purple
                          : Colors.blue,
                    ),
                    title: Text(
                      DateFormat('HH:mm:ss').format(log.dateTime),
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${log.mode.name} | Battery: ${log.batterySocInPercentage}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )),

          const SizedBox(height: 16),

          // Fault Logs
          Text('Fault Logs (${faultLogs.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (faultLogs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No faults detected'),
              ),
            )
          else
            ...faultLogs.reversed.take(20).map((log) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.warning, color: Colors.red),
                    title: Text(
                      DateFormat('HH:mm:ss')
                          .format(DateTime.fromMillisecondsSinceEpoch(
                              log.timestamp * 1000)),
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      log.type.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
