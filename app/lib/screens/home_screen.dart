import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/larq_ble_service.dart';
import '../services/bottle_session.dart';
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

  final Map<String, BottleSession> _sessions = {};
  final Map<String, ScanResult> _latestScan = {};
  final Set<String> _connectingIds = {};

  static const _scanDuration = Duration(seconds: 25);
  static const _scanRestartDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Recover stale connections in parallel with scanning.
    // If recovery succeeds at reconnecting, scan will just see
    // the bottle as already connected and skip it.
    // widget.bleService.recoverStaleConnections();
    _startScanning();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[HOME] lifecycle: $state');
    if (state == AppLifecycleState.detached) {
      print('[HOME] app detached, disconnecting all sessions...');
      widget.bleService.disconnectAll().then((_) {
        print('[HOME] all sessions disconnected');
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
    if (_sessions.isNotEmpty) {
      print('[HOME] dispose, disconnecting all sessions');
      widget.bleService.disconnectAll();
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
        .listen(_onScanResults);

  }

  void _stopScan() {
    _scanning = false;
    _scanResultsSub?.cancel();
    _scanResultsSub = null;
    _scanRefreshTimer?.cancel();
    _scanTimeoutTimer?.cancel();
    _scanRestartTimer?.cancel();
    try {
      FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  void _onScanResults(List<ScanResult> results) {
    if (!_mounted || !_scanning) return;
    _scanDevicesSeen = results.length;

    for (final r in results) {
      if (!_isBottle(r)) continue;
      final remoteId = r.device.remoteId.toString();

      // Update latest scan info for display
      _latestScan[remoteId] = r;

      // RSSI 0 = ghost entry — disconnect + remove bond
      if (r.rssi == 0) {
        print('[HOME]   rssi=0 ghost: ${r.device.advName} ($remoteId) — disconnecting via FBP...');
        widget.bleService.disconnectGhost(r.device);
        continue;
      }

      // Already connected (managed session) — nothing to do
      if (_sessions.containsKey(remoteId) && _sessions[remoteId]!.isConnected) {
        continue;
      }

      // Auto-connect (non-blocking — scan continues while connecting)
      _connectToBottle(r);
    }

    if (mounted) setState(() {});
  }

  bool _isBottle(ScanResult result) {
    final name = result.device.advName.isNotEmpty
        ? result.device.advName
        : result.device.platformName;
    return name.toLowerCase().startsWith('larq_');
  }

  Future<void> _connectToBottle(ScanResult bottle) async {
    final remoteId = bottle.device.remoteId.toString();
    if (_sessions.containsKey(remoteId) || _connectingIds.contains(remoteId)) {
      return;
    }

    print('[HOME] _connectToBottle: ${bottle.device.advName} ($remoteId)');
    _connectingIds.add(remoteId);
    if (mounted) setState(() {});

    final result = await widget.bleService.connectToBottle(bottle.device);
    _connectingIds.remove(remoteId);

    if (!_mounted) return;

    if (result.success) {
      final session = widget.bleService.getSession(remoteId);
      if (session != null) {
        _sessions[remoteId] = session;
        session.connectionStream.listen((connected) {
          if (!connected) {
            print('[HOME] session $remoteId disconnected');
            _sessions.remove(remoteId);
            _latestScan.remove(remoteId);
            if (mounted) setState(() {});
          }
        });
      }
    } else {
      print('[HOME] connect failed for $remoteId: ${result.error}');
    }
    if (mounted) setState(() {});
  }

  void _openDevice(BottleSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceScreen(session: session),
      ),
    );
  }

  void _disconnectDevice(BottleSession session) {
    final id = session.lastRemoteId;
    if (id != null) {
      widget.bleService.disconnectBottle(id);
      _sessions.remove(id);
      _latestScan.remove(id);
      if (mounted) setState(() {});
    }
  }

  String get _scanElapsed {
    if (!_scanning) return '';
    final elapsed = DateTime.now().difference(_scanStartedAt);
    return '${elapsed.inSeconds}s';
  }

  String _bottleName(String remoteId) {
    final r = _latestScan[remoteId];
    if (r != null) {
      final name = r.device.advName.isNotEmpty
          ? r.device.advName
          : r.device.platformName;
      if (name.isNotEmpty) return name;
    }
    return 'LARQ Bottle';
  }

  @override
  Widget build(BuildContext context) {
    final connectedSessions =
        _sessions.values.where((s) => s.isConnected).toList();

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
          if (connectedSessions.isEmpty) ...[
            if (_scanning)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scanning for LARQ bottles...',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bluetooth_searching,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No bottles connected',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: (){},
                      icon: const Icon(Icons.refresh),
                      label: const Text('Start Scan'),
                    ),
                  ],
                ),
              ),
          ] else ...[
            for (final session in connectedSessions)
              _BottleCard(
                name: session.deviceInfo.modelNumber.isNotEmpty
                    ? session.deviceInfo.modelNumber
                    : _bottleName(session.lastRemoteId ?? ''),
                mac: session.lastRemoteId ?? '',
                rssi: _latestScan[session.lastRemoteId]?.rssi,
                connected: true,
                battery: session.batteryLevel,
                firmware: session.deviceInfo.firmwareRevision,
                onTap: () => _openDevice(session),
              ),
          ],
          // Show placeholders for connecting sessions
          for (final id in _connectingIds)
            _BottleCard(
              name: _bottleName(id),
              mac: id,
              rssi: _latestScan[id]?.rssi,
              connecting: true,
              connected: false,
              battery: -1,
              firmware: '',
              onTap: null,
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
              width: 16,
              height: 16,
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
  final int battery;
  final String firmware;
  final VoidCallback? onTap;

  const _BottleCard({
    required this.name,
    required this.mac,
    this.rssi,
    this.connecting = false,
    this.connected = false,
    required this.battery,
    required this.firmware,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      mac,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (connecting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (connected)
                Row(
                  children: [
                    if (battery >= 0)
                      Text(
                        '$battery%',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    if (firmware.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        'FW $firmware',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                )
              else
                Text(
                  rssi != null ? '${rssi} dBm' : '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
