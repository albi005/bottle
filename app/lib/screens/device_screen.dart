import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/larq_protocol.dart';
import '../services/larq_ble_service.dart';
import '../services/health_connect_service.dart';

class DeviceScreen extends StatefulWidget {
  final LarqBleService bleService;

  const DeviceScreen({super.key, required this.bleService});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _healthService = HealthConnectService();
  StreamSubscription? _responseSub;
  StreamSubscription? _pollItemSub;

  String? _pollingItem;
  Duration _lastPollDuration = Duration.zero;
  bool _mounted = true;

  bool _healthAuthorized = false;
  bool _healthSyncing = false;
  int _healthSyncedCount = 0;
  double _todayWaterMl = 0;

  @override
  void initState() {
    super.initState();
    _responseSub = widget.bleService.responseStream.listen((_) {
      if (_mounted && mounted) setState(() {});
    });
    _pollItemSub = widget.bleService.pollingItemStream.listen((item) {
      if (_mounted && mounted) {
        setState(() {
          _pollingItem = item;
          if (item == null) {
            _lastPollDuration = widget.bleService.lastPollDuration;
          }
        });
      }
    });
    _checkHealthConnect();
  }

  Future<void> _checkHealthConnect() async {
    final authorized = await _healthService.authorize();
    if (mounted) setState(() => _healthAuthorized = authorized);
    if (authorized) {
      final ml = await _healthService.getTodayWaterIntake();
      if (mounted) setState(() => _todayWaterMl = ml);
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _responseSub?.cancel();
    _pollItemSub?.cancel();
    super.dispose();
  }

  Future<void> _manualPoll() async {
    await widget.bleService.fetchAllData();
  }

  Future<void> _syncToHealthConnect() async {
    setState(() => _healthSyncing = true);
    try {
      await widget.bleService.fetchAllData();
      final count = await _healthService.syncTofLogsToHealthConnect(
        widget.bleService.tofLogs,
      );
      if (mounted) {
        setState(() => _healthSyncedCount += count);
        final ml = await _healthService.getTodayWaterIntake();
        if (mounted) setState(() => _todayWaterMl = ml);
      }
    } finally {
      if (mounted) setState(() => _healthSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = widget.bleService;

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
        padding: const EdgeInsets.all(12),
        children: [
          _PollStatusBar(
            polling: _pollingItem != null,
            fetchingItem: _pollingItem,
            pollDuration: _lastPollDuration,
          ),
          const SizedBox(height: 8),
          _HeroCard(ble: ble),
          const SizedBox(height: 8),
          _DeviceInfoTile(info: ble.deviceInfo),
          const SizedBox(height: 8),
          _SensorsCard(ble: ble, fetchingItem: _pollingItem),
          const SizedBox(height: 8),
          _TofLogsCard(logs: ble.tofLogs, onLoadMore: ble.loadMoreTofLogs),
          const SizedBox(height: 8),
          _ActivationLogsCard(
            logs: ble.activationLogs,
            onLoadMore: ble.loadMoreActivationLogs,
          ),
          const SizedBox(height: 8),
          _AdcLogsCard(
            actLogs: ble.activationAdcLogs,
            chgLogs: ble.chargingAdcLogs,
            onLoadMoreAct: ble.loadMoreActivationAdcLogs,
            onLoadMoreChg: ble.loadMoreChargingAdcLogs,
          ),
          const SizedBox(height: 8),
          _FaultLogsCard(
            logs: ble.faultLogs,
            onLoadMore: ble.loadMoreFaultLogs,
          ),
          const SizedBox(height: 8),
          _ControlsCard(
            ble: ble,
            health: _healthService,
            healthAuthorized: _healthAuthorized,
            healthSyncing: _healthSyncing,
            healthSyncedCount: _healthSyncedCount,
            todayWaterMl: _todayWaterMl,
            onAuthorize: _checkHealthConnect,
            onSync: _syncToHealthConnect,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// --- Shared helpers ---

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

String _triggerLabel(CapEnumTofTriggerType type) {
  return switch (type) {
    CapEnumTofTriggerType.capOnFlapOpenSip => 'Sip Detected',
    CapEnumTofTriggerType.capOnFlap => 'Cap + Flap',
    CapEnumTofTriggerType.cap => 'Cap Removed',
    CapEnumTofTriggerType.interval => 'Interval',
    CapEnumTofTriggerType.request => 'Request',
  };
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

String _uvModeLabel(CapEnumUvActivationMode mode) {
  return switch (mode) {
    CapEnumUvActivationMode.standard => 'Standard',
    CapEnumUvActivationMode.adventure => 'Adventure',
    CapEnumUvActivationMode.maintenance => 'Maintenance',
    CapEnumUvActivationMode.stop => 'Stop',
  };
}

String _faultTypeLabel(CapEnumFaultType type) {
  return switch (type) {
    CapEnumFaultType.uvOvertemp => 'UV Over-temperature',
    CapEnumFaultType.uvLedShort => 'UV LED Short',
    CapEnumFaultType.uvLedOpen => 'UV LED Open',
    CapEnumFaultType.batteryTemp => 'Battery Temperature',
    CapEnumFaultType.batteryOpen => 'Battery Open',
    CapEnumFaultType.batteryShort => 'Battery Short',
    CapEnumFaultType.ambientLight => 'Ambient Light',
  };
}

// --- Widgets ---

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
            if (pollDuration > Duration.zero)
              Text(
                '${(pollDuration.inMilliseconds / 1000).toStringAsFixed(1)}s cycle',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final LarqBleService ble;

  const _HeroCard({required this.ble});

  @override
  Widget build(BuildContext context) {
    final uiState = ble.uiState;
    final battery = ble.batteryLevel;
    final info = ble.deviceInfo;
    final name = info.modelNumber.isNotEmpty
        ? info.modelNumber
        : 'LARQ PureVis 2';
    final mac = ble.lastRemoteId ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(uiState),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _uiStateLabel(uiState),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                if (info.firmwareRevision.isNotEmpty)
                  Text(
                    'FW ${info.firmwareRevision}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (battery >= 0) ...[
              Text(
                '$battery%',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Battery',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
            Text(name, style: Theme.of(context).textTheme.bodyMedium),
            if (mac.isNotEmpty)
              Text(
                mac,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceInfoTile extends StatelessWidget {
  final LarqDeviceInfo info;

  const _DeviceInfoTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final entries = <String, String>{
      if (info.modelNumber.isNotEmpty) 'Model': info.modelNumber,
      if (info.serialNumber.isNotEmpty) 'Serial': info.serialNumber,
      if (info.firmwareRevision.isNotEmpty) 'Firmware': info.firmwareRevision,
      if (info.hardwareRevision.isNotEmpty) 'Hardware': info.hardwareRevision,
      if (info.softwareRevision.isNotEmpty) 'Software': info.softwareRevision,
    };

    return Card(
      child: ExpansionTile(
        title: const Text('Device Information'),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(bottom: 12),
        children: [
          for (final e in entries.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      e.key,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(e.value, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SensorsCard extends StatelessWidget {
  final LarqBleService ble;
  final String? fetchingItem;

  const _SensorsCard({required this.ble, this.fetchingItem});

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
            _SensorRow(
              'Battery',
              '${ble.batteryLevel}%',
              loading: fetchingItem == 'Battery',
            ),
            if (ble.bottleSensorState != null)
              _SensorRow(
                'Bottle Sensor',
                ble.bottleSensorState!.state ? 'Present' : 'Absent',
                loading: fetchingItem == 'Bottle Sensor',
              ),
            if (ble.sipSensorState != null)
              _SensorRow(
                'SIP Sensor',
                '${ble.sipSensorState!.value} (${ble.sipSensorState!.state ? "Active" : "Idle"})',
                loading: fetchingItem == 'SIP Sensor',
              ),
            if (ble.tofState != null)
              _SensorRow(
                'ToF Distance',
                '${ble.tofState!.distanceInMillimeter}mm',
                loading: fetchingItem == 'ToF State',
              ),
            if (ble.accelerometerState != null)
              _SensorRow(
                'Accelerometer',
                '${ble.accelerometerState!.x.toStringAsFixed(1)}, '
                    '${ble.accelerometerState!.y.toStringAsFixed(1)}, '
                    '${ble.accelerometerState!.z.toStringAsFixed(1)}',
                loading: fetchingItem == 'Accelerometer',
              ),
            if (ble.ambientLightState != null)
              _SensorRow(
                'Ambient Light',
                '${ble.ambientLightState!.value} lux',
                loading: fetchingItem == 'Ambient Light',
              ),
            if (ble.hallEffectState != null)
              _SensorRow(
                'Hall Effect',
                ble.hallEffectState!.state ? 'Open' : 'Closed',
                loading: fetchingItem == 'Hall Effect',
              ),
            _SensorRow(
              'Power Saving',
              ble.powerSavingMode == CapPowerSavingMode.off ? 'Off' : 'On',
            ),
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
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _TofLogsCard extends StatefulWidget {
  final List<CapTofLog> logs;
  final Future<void> Function()? onLoadMore;

  const _TofLogsCard({required this.logs, this.onLoadMore});

  @override
  State<_TofLogsCard> createState() => _TofLogsCardState();
}

class _TofLogsCardState extends State<_TofLogsCard> {
  bool _loading = false;

  Future<void> _loadMore() async {
    if (_loading || widget.onLoadMore == null) return;
    setState(() => _loading = true);
    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;
    return Card(
      child: ExpansionTile(
        title: Text('ToF Logs (${logs.length})'),
        subtitle: logs.isNotEmpty
            ? Text(
                'Last: ${DateFormat.yMd().add_Hm().format(logs.last.dateTime.toLocal())} — '
                '${_triggerLabel(logs.last.triggerType)} '
                '${logs.last.distanceInMillimeter}mm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              )
            : null,
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(bottom: 12),
        children: [
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No ToF logs yet',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else ...[
            ...logs.reversed.take(50).map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        DateFormat(
                          'MM-dd HH:mm',
                        ).format(log.dateTime.toLocal()),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _triggerColor(log.triggerType),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _triggerLabel(log.triggerType),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${log.distanceInMillimeter}mm',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${log.kcps}kcps',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
            if (widget.onLoadMore != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _loadMore,
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load more entries'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

Color _uvColor(CapEnumUvActivationMode mode) => switch (mode) {
  CapEnumUvActivationMode.adventure => Colors.purple,
  CapEnumUvActivationMode.standard => Colors.blue,
  _ => Colors.grey,
};

class _ActivationLogsCard extends StatefulWidget {
  final List<CapActivationLog> logs;
  final Future<void> Function()? onLoadMore;

  const _ActivationLogsCard({required this.logs, this.onLoadMore});

  @override
  State<_ActivationLogsCard> createState() => _ActivationLogsCardState();
}

class _ActivationLogsCardState extends State<_ActivationLogsCard> {
  bool _loading = false;

  Future<void> _loadMore() async {
    if (_loading || widget.onLoadMore == null) return;
    setState(() => _loading = true);
    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;
    return Card(
      child: ExpansionTile(
        title: Text('UV Activations (${logs.length})'),
        subtitle: logs.isNotEmpty
            ? Text(
                'Last: ${DateFormat.yMd().add_Hm().format(logs.last.dateTime.toLocal())} — '
                '${_uvModeLabel(logs.last.mode)} (${logs.last.batterySocInPercentage}%)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              )
            : null,
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(bottom: 12),
        children: [
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No UV activations yet',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else ...[
            ...logs.reversed.take(30).map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        DateFormat(
                          'MM-dd HH:mm',
                        ).format(log.dateTime.toLocal()),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _uvColor(log.mode),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _uvModeLabel(log.mode),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${log.batterySocInPercentage}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
            if (widget.onLoadMore != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _loadMore,
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load more entries'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AdcLogsCard extends StatefulWidget {
  final List<CapAdcLog> actLogs;
  final List<CapAdcLog> chgLogs;
  final Future<void> Function()? onLoadMoreAct;
  final Future<void> Function()? onLoadMoreChg;

  const _AdcLogsCard({
    required this.actLogs,
    required this.chgLogs,
    this.onLoadMoreAct,
    this.onLoadMoreChg,
  });

  @override
  State<_AdcLogsCard> createState() => _AdcLogsCardState();
}

class _AdcLogsCardState extends State<_AdcLogsCard> {
  bool _loading = false;

  Future<void> _loadMore(Future<void> Function()? fn) async {
    if (_loading || fn == null) return;
    setState(() => _loading = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actLogs = widget.actLogs;
    final chgLogs = widget.chgLogs;
    final total = actLogs.length + chgLogs.length;

    return Card(
      child: ExpansionTile(
        title: Text('ADC Logs ($total)'),
        subtitle: total > 0
            ? Text(
                'Activation: ${actLogs.length}  Charging: ${chgLogs.length}',
                style: const TextStyle(fontSize: 12),
              )
            : null,
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(bottom: 12),
        children: [
          if (total == 0)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No ADC logs',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else ...[
            if (actLogs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Activation ADC (${actLogs.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...actLogs.reversed.take(20).map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          DateFormat('MM-dd HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              log.timestamp * 1000,
                            ).toLocal(),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'BAT ${log.batteryInVolt.toStringAsFixed(2)}V  '
                          'UV ${log.uvLedCurrentInMilliamps.toStringAsFixed(1)}mA',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (widget.onLoadMoreAct != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => _loadMore(widget.onLoadMoreAct),
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Load more activation ADC'),
                    ),
                  ),
                ),
            ],
            if (actLogs.isNotEmpty && chgLogs.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Divider(height: 1),
              const SizedBox(height: 4),
            ],
            if (chgLogs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Charging ADC (${chgLogs.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...chgLogs.reversed.take(20).map((log) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          DateFormat('MM-dd HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              log.timestamp * 1000,
                            ).toLocal(),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'BAT ${log.batteryInVolt.toStringAsFixed(2)}V  '
                          'UV ${log.uvLedCurrentInMilliamps.toStringAsFixed(1)}mA',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (widget.onLoadMoreChg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => _loadMore(widget.onLoadMoreChg),
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Load more charging ADC'),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FaultLogsCard extends StatefulWidget {
  final List<CapFaultLog> logs;
  final Future<void> Function()? onLoadMore;

  const _FaultLogsCard({required this.logs, this.onLoadMore});

  @override
  State<_FaultLogsCard> createState() => _FaultLogsCardState();
}

class _FaultLogsCardState extends State<_FaultLogsCard> {
  bool _loading = false;

  Future<void> _loadMore() async {
    if (_loading || widget.onLoadMore == null) return;
    setState(() => _loading = true);
    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;
    return Card(
      child: ExpansionTile(
        title: Text('Fault Logs (${logs.length})'),
        subtitle: logs.isNotEmpty
            ? Text(
                'Last: ${DateFormat.yMd().add_Hm().format(DateTime.fromMillisecondsSinceEpoch(logs.last.timestamp * 1000).toLocal())} — '
                '${_faultTypeLabel(logs.last.type)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              )
            : null,
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(bottom: 12),
        children: [
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No faults detected',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else ...[
            ...logs.reversed.take(20).map((log) {
              return ListTile(
                dense: true,
                leading: const Icon(
                  Icons.warning_amber,
                  color: Colors.red,
                  size: 20,
                ),
                title: Text(
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(
                    DateTime.fromMillisecondsSinceEpoch(
                      log.timestamp * 1000,
                    ).toLocal(),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  _faultTypeLabel(log.type),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
            if (widget.onLoadMore != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _loadMore,
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load more entries'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  final LarqBleService ble;
  final HealthConnectService health;
  final bool healthAuthorized;
  final bool healthSyncing;
  final int healthSyncedCount;
  final double todayWaterMl;
  final VoidCallback onAuthorize;
  final VoidCallback onSync;

  const _ControlsCard({
    required this.ble,
    required this.health,
    required this.healthAuthorized,
    required this.healthSyncing,
    required this.healthSyncedCount,
    required this.todayWaterMl,
    required this.onAuthorize,
    required this.onSync,
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
            const SizedBox(height: 4),
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
            const SizedBox(height: 20),
            Text(
              'Health Connect',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (!health.isSupported)
              const Text(
                'Not available on this platform',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              )
            else if (healthAuthorized) ...[
              Row(
                children: [
                  const Text(
                    'Today: ',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    '${todayWaterMl.toStringAsFixed(0)} ml',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (healthSyncedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$healthSyncedCount events synced',
                    style: const TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: healthSyncing ? null : onSync,
                  icon: healthSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(healthSyncing ? 'Syncing...' : 'Sync ToF Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onAuthorize,
                  child: const Text('Authorize Health Connect'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
