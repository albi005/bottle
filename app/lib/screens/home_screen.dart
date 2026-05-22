import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/larq_protocol.dart';
import '../services/larq_ble_service.dart';
import 'device_screen.dart';

class HomeScreen extends StatefulWidget {
  final LarqBleService bleService;

  const HomeScreen({super.key, required this.bleService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _scanning = false;
  int _scanDevicesSeen = 0;
  DateTime _scanStartedAt = DateTime.now();
  Timer? _scanRefreshTimer;
  Timer? _scanTimeoutTimer;
  Timer? _scanRestartTimer;
  StreamSubscription? _scanResultsSub;
  bool _mounted = true;

  ScanResult? _bottleResult;
  bool _connecting = false;
  String _connError = '';

  StreamSubscription? _responseSub;
  StreamSubscription? _pollItemSub;
  String? _pollingItem;

  static const _scanDuration = Duration(seconds: 25);
  static const _scanRestartDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _responseSub = widget.bleService.responseStream.listen((_) {
      if (_mounted && mounted) setState(() {});
    });
    _pollItemSub = widget.bleService.pollingItemStream.listen((item) {
      if (_mounted && mounted) setState(() => _pollingItem = item);
    });

    widget.bleService.connectionStream.listen((connected) {
      if (!_mounted) return;
      if (!connected && !_connecting && !widget.bleService.isConnected) {
        print('[HOME] connection dropped, restarting scan');
        if (mounted) setState(() {});
        _startScanning();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _startScanning();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[HOME] lifecycle: $state');
    if (state == AppLifecycleState.detached) {
      print('[HOME] app detached, starting disconnect...');
      // Fire-and-forget: the process may exit before this completes,
      // but we must try so the bottle gets a clean BLE disconnection.
      widget.bleService.disconnect(intentional: true).then((_) {
        print('[HOME] disconnect completed before exit');
      }).catchError((e) {
        print('[HOME] disconnect error: $e');
      });
    }
  }

  @override
  void dispose() {
    _mounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _stopScan();
    _scanRefreshTimer?.cancel();
    _responseSub?.cancel();
    _pollItemSub?.cancel();
    // Attempt clean BLE disconnect on dispose, even though the process
    // may be killed before it completes. The WidgetsBindingObserver.detached
    // callback is more reliable, but on Linux it may not fire.
    if (widget.bleService.isConnected) {
      print('[HOME] dispose, attempting disconnect');
      widget.bleService.disconnect(intentional: true);
    }
    super.dispose();
  }

  void _startScanning() {
    if (!_mounted) return;
    if (_scanning) return;
    _stopScan();

    _scanning = true;
    _scanDevicesSeen = 0;
    _scanStartedAt = DateTime.now();

    print('[HOME] starting scan');
    if (mounted) setState(() {});

    _scanRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_mounted && mounted && _scanning) setState(() {});
    });

    _scanResultsSub = widget.bleService
        .scanForDevices(timeout: _scanDuration)
        .listen((results) {
      if (!_mounted || !_scanning) return;

      _scanDevicesSeen = results.length;

      final bottle = results.cast<ScanResult?>().firstWhere(
        (r) => _isBottle(r!),
        orElse: () => null,
      );

      if (bottle != null &&
          _bottleResult?.device.remoteId != bottle.device.remoteId) {
        _bottleResult = bottle;
        print('[HOME] bottle seen: ${_bottleResult!.device.remoteId} rssi=${_bottleResult!.rssi}');
        if (mounted) setState(() {});

        // Skip RSSI 0 (BlueZ cached/ghost entries) — wait for a real signal
        if (bottle.rssi == 0) {
          print('[HOME]   rssi=0, ignoring (ghost entry)');
        } else if (!_connecting && !widget.bleService.isConnected) {
          _connectToBottle(bottle);
        }
      } else if (bottle != null) {
        _bottleResult = bottle;
        if (mounted) setState(() {});
      }
    });

    _scanTimeoutTimer = Timer(_scanDuration + const Duration(seconds: 1), () {
      if (!_mounted || !_scanning) return;
      _scanning = false;
      _scanResultsSub?.cancel();
      _scanRefreshTimer?.cancel();
      print('[HOME] scan timeout, restarting in ${_scanRestartDelay.inSeconds}s');
      if (mounted) setState(() {});

      _scanRestartTimer = Timer(_scanRestartDelay, () {
        if (!_mounted) return;
        if (!widget.bleService.isConnected && !_connecting) {
          _bottleResult = null;
        }
        _startScanning();
      });
    });
  }

  void _stopScan() {
    _scanning = false;
    _scanResultsSub?.cancel();
    _scanResultsSub = null;
    _scanRefreshTimer?.cancel();
    _scanTimeoutTimer?.cancel();
    _scanRestartTimer?.cancel();
    try { FlutterBluePlus.stopScan(); } catch (_) {}
  }

  bool _isBottle(ScanResult result) {
    final name = result.device.advName.isNotEmpty
        ? result.device.advName
        : result.device.platformName;
    return name.toLowerCase().startsWith('larq_');
  }

  Future<void> _connectToBottle(ScanResult bottle) async {
    if (_connecting || widget.bleService.isConnected) return;
    print('[HOME] _connectToBottle');
    _connecting = true;
    _connError = '';
    _bottleResult = bottle;
    _stopScan();
    if (mounted) setState(() {});

    await Future.delayed(const Duration(seconds: 2));

    print('[HOME] calling connectWithResult...');
    final result = await widget.bleService.connectWithResult(bottle.device);
    print('[HOME] connectWithResult success=${result.success} error=${result.error}');

    if (!_mounted) return;
    _connecting = false;

    if (result.success) {
      if (mounted) setState(() {});
    } else {
      _connError = result.error;
      if (mounted) setState(() {});
      Future.delayed(const Duration(seconds: 2), () {
        if (_mounted) _startScanning();
      });
    }
  }

  void _openDevice() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceScreen(bleService: widget.bleService),
      ),
    );
  }

  String get _scanElapsed {
    if (!_scanning) return '';
    final elapsed = DateTime.now().difference(_scanStartedAt);
    return '${elapsed.inSeconds}s';
  }

  bool get _isConnected => widget.bleService.isConnected && !_connecting;

  String get _bottleName {
    final r = _bottleResult;
    if (r == null) return '';
    return r.device.advName.isNotEmpty
        ? r.device.advName
        : (r.device.platformName.isNotEmpty ? r.device.platformName : 'LARQ Bottle');
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

  Color _uiStateColor(CapEnumUiState state) {
    return switch (state) {
      CapEnumUiState.on || CapEnumUiState.uvNormal => Colors.blue,
      CapEnumUiState.uvAdventure => Colors.purple,
      CapEnumUiState.uvMaintenance => Colors.orange,
      CapEnumUiState.charging || CapEnumUiState.charged => Colors.green,
      CapEnumUiState.batteryLow || CapEnumUiState.fault => Colors.red,
      CapEnumUiState.locked => Colors.grey,
      CapEnumUiState.paired || CapEnumUiState.hydrationReminder => Colors.teal,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ble = widget.bleService;
    final showBottle = _bottleResult != null || _isConnected;

    return Scaffold(
      appBar: AppBar(title: const Text('LARQ Bridge')),
      body: ListView(
        children: [
          _ScanStatusBar(
            scanning: _scanning,
            elapsed: _scanElapsed,
            devicesSeen: _scanDevicesSeen,
          ),
          const Divider(height: 1),
          if (showBottle)
            _BottleCard(
              name: _isConnected
                  ? (ble.deviceInfo.modelNumber.isNotEmpty
                      ? ble.deviceInfo.modelNumber
                      : 'LARQ Bottle')
                  : _bottleName,
              mac: _bottleResult?.device.remoteId.toString() ?? '',
              rssi: _bottleResult?.rssi,
              connecting: _connecting,
              connected: _isConnected,
              connError: _connError,
              battery: ble.batteryLevel,
              uiState: ble.uiState,
              uiStateLabel: _uiStateLabel(ble.uiState),
              uiStateColor: _uiStateColor(ble.uiState),
              firmware: ble.deviceInfo.firmwareRevision,
              pollingItem: _pollingItem,
              onTap: _isConnected ? _openDevice : null,
            ),
          if (!showBottle && !_scanning)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Ready to scan',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _startScanning,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Start Scan'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanStatusBar extends StatelessWidget {
  final bool scanning;
  final String elapsed;
  final int devicesSeen;

  const _ScanStatusBar({
    required this.scanning,
    required this.elapsed,
    required this.devicesSeen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (scanning)
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(Icons.bluetooth, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              scanning
                  ? 'Scanning — ${elapsed} — $devicesSeen device${devicesSeen == 1 ? '' : 's'} seen'
                  : 'Not scanning',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleCard extends StatelessWidget {
  final String name;
  final String mac;
  final int? rssi;
  final bool connecting;
  final bool connected;
  final String connError;
  final int battery;
  final CapEnumUiState uiState;
  final String uiStateLabel;
  final Color uiStateColor;
  final String firmware;
  final String? pollingItem;
  final VoidCallback? onTap;

  const _BottleCard({
    required this.name,
    required this.mac,
    this.rssi,
    required this.connecting,
    required this.connected,
    required this.connError,
    required this.battery,
    required this.uiState,
    required this.uiStateLabel,
    required this.uiStateColor,
    required this.firmware,
    this.pollingItem,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    connected ? Icons.water_drop : Icons.bluetooth,
                    color: connected ? Colors.teal : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleMedium),
                        Text(mac, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (connecting)
                    const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  else if (connected)
                    Row(
                      children: [
                        if (pollingItem == 'Battery')
                          const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5))
                        else if (battery >= 0)
                          Text('$battery%',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        if (battery >= 0) const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    )
                  else
                    Text(
                      rssi != null ? '${rssi} dBm' : '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
              if (connecting) ...[
                const SizedBox(height: 8),
                Text('Connecting...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.teal)),
              ],
              if (connError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(connError,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red)),
              ],
              if (connected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: uiStateColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(uiStateLabel, style: Theme.of(context).textTheme.bodySmall),
                    if (firmware.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text('FW $firmware',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ],
                ),
              ],
              if (!connected && !connecting && connError.isEmpty) ...[
                const SizedBox(height: 8),
                Text('Waiting for connection...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
