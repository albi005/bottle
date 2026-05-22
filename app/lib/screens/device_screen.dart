import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/larq_protocol.dart';
import '../services/larq_ble_service.dart';
import '../services/health_connect_service.dart';
import 'hydration_screen.dart';
import 'scan_screen.dart';

class DeviceScreen extends StatefulWidget {
  final LarqBleService bleService;

  const DeviceScreen({super.key, required this.bleService});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _healthService = HealthConnectService();
  StreamSubscription? _responseSubscription;
  StreamSubscription? _connectionSubscription;
  bool _disconnecting = false;

  bool _reconnecting = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  StreamSubscription? _reconnectScanSub;
  bool _mounted = true;

  // Poll loop state
  bool _polling = false;
  String? _fetchingItem;
  Duration _lastPollDuration = Duration.zero;
  Timer? _pollTimer;
  DateTime _pollStartedAt = DateTime.now();
  int _pollSeq = 0;

  @override
  void initState() {
    super.initState();
    _responseSubscription = widget.bleService.responseStream.listen((_) {
      if (mounted) setState(() {});
    });

    _connectionSubscription =
        widget.bleService.connectionStream.listen((connected) {
      if (!connected && !widget.bleService.intentionalDisconnect && _mounted) {
        _startReconnect();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _poll();
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _responseSubscription?.cancel();
    _connectionSubscription?.cancel();
    _reconnectTimer?.cancel();
    _reconnectScanSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // --- Poll loop ---

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    _pollSeq++;
    final seq = _pollSeq;
    _pollStartedAt = DateTime.now();
    if (mounted) setState(() {});

    try {
      await _fetchItem('ToF Log', () => widget.bleService.getTofLog());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem('ToF State', () => widget.bleService.getTofState());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem('Bottle Sensor',
          () => widget.bleService.getBottleSensorState());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem('UI State', () => widget.bleService.getUiState());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem('SIP Sensor', () => widget.bleService.getSipSensorState());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem(
          'Accelerometer', () => widget.bleService.getAccelerometerState());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem('Ambient Light',
          () => widget.bleService.getAmbientLightSensorState());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem(
          'Hall Effect', () => widget.bleService.getHallEffectSensorState());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem(
          'Activation Log', () => widget.bleService.getActivationLog());
      if (seq != _pollSeq || !_mounted) return;
      await _fetchItem('Fault Log', () => widget.bleService.getFaultLog());
    } catch (_) {}

    _lastPollDuration = DateTime.now().difference(_pollStartedAt);
    _polling = false;
    _fetchingItem = null;
    if (mounted) setState(() {});

    _scheduleNextPoll();
  }

  Future<void> _fetchItem(
      String label, Future<void> Function() fetch) async {
    _fetchingItem = label;
    if (mounted) setState(() {});
    await fetch();
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    final delay = _lastPollDuration * 2;
    if (delay < const Duration(seconds: 1)) {
      _pollTimer = Timer(const Duration(seconds: 1), _poll);
    } else {
      _pollTimer = Timer(delay, _poll);
    }
  }

  // --- Reconnect logic ---

  void _startReconnect() {
    if (_reconnecting) return;
    _pollTimer?.cancel();
    _polling = false;
    _fetchingItem = null;
    _reconnecting = true;
    _reconnectAttempt = 1;
    if (mounted) setState(() {});
    _tryReconnect();
  }

  void _tryReconnect() {
    if (!_mounted || !_reconnecting) return;
    if (mounted) setState(() {});

    _reconnectScanSub?.cancel();
    FlutterBluePlus.stopScan();

    final remoteId =
        widget.bleService.lastRemoteId ?? LarqBleUuids.knownBottleRemoteId;

    _reconnectScanSub = widget.bleService
        .scanForDevices(timeout: const Duration(seconds: 15))
        .listen((results) {
      if (!_mounted || !_reconnecting) return;
      for (final r in results) {
        final rid = r.device.remoteId.toString().toUpperCase();
        if (rid == remoteId.toUpperCase()) {
          _onReconnectFound(r);
          return;
        }
      }
    });

    _reconnectTimer = Timer(const Duration(seconds: 15), () {
      if (!_mounted || !_reconnecting) return;
      _reconnectAttempt++;
      _tryReconnect();
    });
  }

  Future<void> _onReconnectFound(ScanResult result) async {
    _reconnectTimer?.cancel();
    _reconnectScanSub?.cancel();
    FlutterBluePlus.stopScan();

    widget.bleService.resetState();
    final connectResult =
        await widget.bleService.connectWithResult(result.device);

    if (!_mounted) return;
    if (connectResult.success) {
      _reconnecting = false;
      _reconnectAttempt = 0;
      setState(() {});
      _poll();
    } else {
      _reconnectAttempt++;
      _tryReconnect();
    }
  }

  void _dismissReconnect() {
    _reconnecting = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectScanSub?.cancel();
    FlutterBluePlus.stopScan();
    widget.bleService.disconnect(intentional: true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // --- Disconnect ---

  Future<void> _disconnect() async {
    if (_disconnecting) return;
    setState(() => _disconnecting = true);
    _reconnecting = false;
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectScanSub?.cancel();
    _responseSubscription?.cancel();
    _connectionSubscription?.cancel();
    await widget.bleService.disconnect(intentional: true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => ScanScreen(bleService: widget.bleService)),
      (_) => false,
    );
  }

  String _nextPollText() {
    if (_pollTimer == null || !_pollTimer!.isActive) return '';
    final remaining = _lastPollDuration * 2;
    final s = remaining.inSeconds;
    if (s >= 60) return 'Next poll in ${s ~/ 60}m ${s % 60}s';
    return 'Next poll in ${s}s';
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
            onPressed: (_polling || _disconnecting || _reconnecting)
                ? null
                : _poll,
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: _disconnecting ? null : _disconnect,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PollStatusBar(
                polling: _polling,
                fetchingItem: _fetchingItem,
                pollDuration: _lastPollDuration,
                nextPollText: _pollTimer?.isActive == true ? _nextPollText() : '',
              ),
              const SizedBox(height: 12),
              _StatusCard(
                  uiState: uiState,
                  statusColor: _statusColor(uiState),
                  statusLabel: _uiStateLabel(uiState),
                  loading: _fetchingItem == 'UI State'),
              const SizedBox(height: 12),
              _DeviceInfoCard(info: info),
              const SizedBox(height: 12),
              _SensorCard(ble: widget.bleService, fetchingItem: _fetchingItem),
              const SizedBox(height: 12),
              _ControlsCard(
                ble: widget.bleService,
                health: _healthService,
                onFetch: _poll,
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
          if (_reconnecting)
            _ReconnectOverlay(
              attempt: _reconnectAttempt,
              onDismiss: _dismissReconnect,
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
  final String nextPollText;

  const _PollStatusBar({
    required this.polling,
    required this.fetchingItem,
    required this.pollDuration,
    required this.nextPollText,
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
                    : nextPollText.isNotEmpty
                        ? 'Idle — $nextPollText'
                        : 'Idle',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              '${(pollDuration.inMilliseconds / 1000).toStringAsFixed(1)}s cycle',
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

class _ReconnectOverlay extends StatelessWidget {
  final int attempt;
  final VoidCallback onDismiss;

  const _ReconnectOverlay({required this.attempt, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.coffee, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Bottle disconnected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Press the cap button to wake it.\nReconnect attempt $attempt...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Give up'),
                ),
              ],
            ),
          ),
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
  final VoidCallback onFetch;
  final VoidCallback onNavigate;

  const _ControlsCard({
    required this.ble,
    required this.health,
    required this.onFetch,
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
                    onPressed: () =>
                        ble.startPurification().then((_) => onFetch()),
                    icon: const Icon(Icons.water_drop),
                    label: const Text('Start UV'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ble.stopPurification().then((_) => onFetch()),
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
