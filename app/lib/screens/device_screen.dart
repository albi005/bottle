import 'dart:async';
import 'package:flutter/material.dart';
import '../models/larq_protocol.dart';
import '../services/larq_ble_service.dart';
import '../services/health_connect_service.dart';
import 'hydration_screen.dart';

class DeviceScreen extends StatefulWidget {
  final LarqBleService bleService;

  const DeviceScreen({super.key, required this.bleService});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _healthService = HealthConnectService();
  StreamSubscription? _responseSubscription;
  StreamSubscription? _pollItemSubscription;

  String? _pollingItem;
  Duration _lastPollDuration = Duration.zero;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _responseSubscription = widget.bleService.responseStream.listen((_) {
      if (_mounted && mounted) setState(() {});
    });
    _pollItemSubscription = widget.bleService.pollingItemStream.listen((item) {
      if (_mounted && mounted) {
        setState(() {
          _pollingItem = item;
          if (item == null) {
            _lastPollDuration = widget.bleService.lastPollDuration;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _responseSubscription?.cancel();
    _pollItemSubscription?.cancel();
    super.dispose();
  }

  Future<void> _manualPoll() async {
    await widget.bleService.fetchAllData();
  }

  String _uiStateLabel(CapEnumUiState state) {
    return switch (state) {
      CapEnumUiState.on => 'Ready',
      CapEnumUiState.uvNormal => 'UV Normal',
      CapEnumUiState.uvAdventure => 'UV Adventure',
      CapEnumUiState.uvMaintenance => 'UV Maintenance',
      CapEnumUiState.uvInterlock => 'UV Interlock',
      CapEnumUiState.charging => 'Charging',
      CapEnumUiState.charged => 'Fully Charged',
      CapEnumUiState.batteryLow => 'Low Battery',
      CapEnumUiState.fault => 'Fault',
      CapEnumUiState.locked => 'Locked',
      CapEnumUiState.paired => 'Paired',
      CapEnumUiState.hydrationReminder => 'Hydration Reminder',
      CapEnumUiState.bottleCalibration => 'Calibrating',
      CapEnumUiState.tofMeasurement => 'Measuring',
      CapEnumUiState.turnOff => 'Turning Off',
      CapEnumUiState.factoryReset => 'Factory Reset',
      CapEnumUiState.allOff => 'Off',
      CapEnumUiState.qc => 'QC Mode',
      CapEnumUiState.last => 'Unknown',
    };
  }

  Color _statusColor(CapEnumUiState state) {
    return switch (state) {
      CapEnumUiState.on || CapEnumUiState.uvNormal => Colors.blue,
      CapEnumUiState.uvAdventure => Colors.purple,
      CapEnumUiState.uvMaintenance => Colors.orange,
      CapEnumUiState.charging || CapEnumUiState.charged => Colors.green,
      CapEnumUiState.batteryLow => Colors.red,
      CapEnumUiState.fault => Colors.red,
      CapEnumUiState.locked => Colors.grey,
      CapEnumUiState.paired || CapEnumUiState.hydrationReminder => Colors.teal,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.bleService.deviceInfo;
    final uiState = widget.bleService.uiState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LARQ PureVis 2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Manual refresh',
            onPressed: _manualPoll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PollStatusBar(
            polling: _pollingItem != null,
            fetchingItem: _pollingItem,
            pollDuration: _lastPollDuration,
          ),
          const SizedBox(height: 12),
          _StatusCard(
            uiState: uiState,
            statusColor: _statusColor(uiState),
            statusLabel: _uiStateLabel(uiState),
            loading: _pollingItem == 'UI State',
          ),
          const SizedBox(height: 12),
          _DeviceInfoCard(info: info),
          const SizedBox(height: 12),
          _SensorCard(
            ble: widget.bleService,
            fetchingItem: _pollingItem,
          ),
          const SizedBox(height: 12),
          _ControlsCard(
            ble: widget.bleService,
            health: _healthService,
            onNavigate: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HydrationScreen(
                    bleService: widget.bleService,
                    healthService: _healthService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PollStatusBar extends StatelessWidget {
  final bool polling;
  final String? fetchingItem;
  final Duration pollDuration;

  const _PollStatusBar({
    required this.polling,
    required this.fetchingItem,
    required this.pollDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (polling)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.check_circle, size: 16, color: Colors.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                polling
                    ? (fetchingItem != null
                        ? 'Refreshing: $fetchingItem'
                        : 'Refreshing...')
                    : 'Idle (background polling)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              pollDuration > Duration.zero
                  ? '${(pollDuration.inMilliseconds / 1000).toStringAsFixed(1)}s cycle'
                  : '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final CapEnumUiState uiState;
  final Color statusColor;
  final String statusLabel;
  final bool loading;

  const _StatusCard({
    required this.uiState,
    required this.statusColor,
    required this.statusLabel,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(statusLabel, style: Theme.of(context).textTheme.titleMedium),
            if (loading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final LarqDeviceInfo info;

  const _DeviceInfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Information',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            if (info.modelNumber.isNotEmpty)
              _InfoRow('Model', info.modelNumber),
            if (info.serialNumber.isNotEmpty)
              _InfoRow('Serial', info.serialNumber),
            if (info.firmwareRevision.isNotEmpty)
              _InfoRow('Firmware', info.firmwareRevision),
            if (info.hardwareRevision.isNotEmpty)
              _InfoRow('Hardware', info.hardwareRevision),
            if (info.softwareRevision.isNotEmpty)
              _InfoRow('Software', info.softwareRevision),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final LarqBleService ble;
  final String? fetchingItem;

  const _SensorCard({required this.ble, this.fetchingItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sensors', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            _SensorRow('Battery', '${ble.batteryLevel}%',
                loading: fetchingItem == 'Battery'),
            if (ble.bottleSensorState != null)
              _SensorRow(
                  'Bottle Sensor',
                  ble.bottleSensorState!.state ? 'Present' : 'Absent',
                  loading: fetchingItem == 'Bottle Sensor'),
            if (ble.sipSensorState != null)
              _SensorRow(
                  'SIP Sensor',
                  '${ble.sipSensorState!.value} (${ble.sipSensorState!.state ? "Active" : "Idle"})',
                  loading: fetchingItem == 'SIP Sensor'),
            if (ble.tofState != null)
              _SensorRow('ToF Distance',
                  '${ble.tofState!.distanceInMillimeter}mm',
                  loading: fetchingItem == 'ToF State'),
            if (ble.accelerometerState != null)
              _SensorRow(
                  'Accelerometer',
                  '${ble.accelerometerState!.x.toStringAsFixed(1)}, ${ble.accelerometerState!.y.toStringAsFixed(1)}, ${ble.accelerometerState!.z.toStringAsFixed(1)}',
                  loading: fetchingItem == 'Accelerometer'),
            if (ble.ambientLightState != null)
              _SensorRow('Ambient Light', '${ble.ambientLightState!.value} lux',
                  loading: fetchingItem == 'Ambient Light'),
            if (ble.hallEffectState != null)
              _SensorRow('Hall Effect',
                  ble.hallEffectState!.state ? 'Open' : 'Closed',
                  loading: fetchingItem == 'Hall Effect'),
            _SensorRow(
                'Power Saving',
                ble.powerSavingMode == CapPowerSavingMode.off ? 'Off' : 'On'),
          ],
        ),
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  final String label;
  final String value;
  final bool loading;

  const _SensorRow(this.label, this.value, {this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 130,
              child: Row(
                children: [
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ),
                  Flexible(
                    child: Text(label,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                ],
              )),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  final LarqBleService ble;
  final HealthConnectService health;
  final VoidCallback onNavigate;

  const _ControlsCard({
    required this.ble,
    required this.health,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controls', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ble.startPurification(),
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Start UV'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ble.stopPurification(),
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop UV'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.monitor_heart),
                label: const Text('Hydration Data & Health Connect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
