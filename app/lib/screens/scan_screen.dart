import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/larq_protocol.dart';
import '../services/larq_ble_service.dart';
import 'device_screen.dart';

enum _AutoState { scanning, connecting, wakeBottle, error, off }

class ScanScreen extends StatefulWidget {
  final LarqBleService bleService;

  const ScanScreen({super.key, required this.bleService});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  _AutoState _state = _AutoState.scanning;
  String _statusText = 'Searching for LARQ bottle...';
  int _retryCount = 0;

  List<ScanResult> _scanResults = [];
  StreamSubscription? _scanSubscription;
  Timer? _scanTimer;
  Timer? _retryTimer;

  bool _cancelled = false;

  static const _scanTimeout = Duration(seconds: 20);
  static const _retryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _startAutoConnect();
  }

  @override
  void dispose() {
    _cancelled = true;
    _stopScan();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _startAutoConnect() {
    if (_state == _AutoState.connecting && !_cancelled) return;
    _startScan();
  }

  void _stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
  }

  void _startScan() {
    if (_cancelled) return;
    _stopScan();
    setState(() {
      _state = _AutoState.scanning;
      _statusText = _retryCount > 0
          ? 'Retrying scan... (attempt ${_retryCount + 1})'
          : 'Searching for LARQ bottle...';
      _scanResults = [];
    });

    _scanSubscription = widget.bleService
        .scanForDevices(timeout: _scanTimeout)
        .listen((results) {
      if (_cancelled) return;
      if (mounted) {
        setState(() => _scanResults = List.from(results));
      }

      for (final result in results) {
        if (_isBottle(result)) {
          _onBottleFound(result);
          return;
        }
      }
    });

    _scanTimer = Timer(_scanTimeout, () {
      if (_cancelled) return;
      _stopScan();
      if (_state == _AutoState.scanning) {
        _retryCount++;
        setState(() {
          _state = _AutoState.wakeBottle;
          _statusText = 'Press the cap button to wake the bottle';
        });
        _retryTimer = Timer(_retryDelay, _startAutoConnect);
      }
    });
  }

  bool _isBottle(ScanResult result) {
    final remoteId = result.device.remoteId.toString().toUpperCase();
    final name = result.device.advName.isNotEmpty
        ? result.device.advName
        : result.device.platformName;

    if (remoteId == LarqBleUuids.knownBottleRemoteId.toUpperCase()) return true;

    final nameLower = name.toLowerCase();
    return nameLower.startsWith('larq_') ||
        nameLower.contains('purevis') ||
        nameLower == 'larq' ||
        nameLower == 'pv';
  }

  Future<void> _onBottleFound(ScanResult result) async {
    if (_state == _AutoState.connecting || _cancelled) return;
    _stopScan();
    _retryTimer?.cancel();

    final name = result.device.advName.isNotEmpty
        ? result.device.advName
        : result.device.platformName;
    setState(() {
      _state = _AutoState.connecting;
      _statusText = 'Found $name — Connecting...';
    });

    final connectResult =
        await widget.bleService.connectWithResult(result.device);

    if (_cancelled || !mounted) return;
    if (connectResult.success) {
      setState(() => _state = _AutoState.off);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DeviceScreen(bleService: widget.bleService),
        ),
      );
    } else {
      _retryCount++;
      setState(() {
        _state = _AutoState.error;
        _statusText = 'Connection failed: ${connectResult.error}\n'
            'Retrying in ${_retryDelay.inSeconds}s...';
      });
      _retryTimer = Timer(_retryDelay, _startAutoConnect);
    }
  }

  void _cancelAutoConnect() {
    _stopScan();
    _retryTimer?.cancel();
    _cancelled = true;
    setState(() {
      _state = _AutoState.off;
      _statusText = 'Auto-connect stopped. Use manual scan below.';
    });
  }

  // --- Manual fallback scan ---
  String? _manualConnectingId;

  void _manualStartScan() {
    _stopScan();
    _retryTimer?.cancel();
    _cancelled = true;
    setState(() {
      _state = _AutoState.scanning;
      _statusText = 'Manual scan — looking for devices...';
      _scanResults = [];
    });

    _scanSubscription = widget.bleService
        .scanForDevices(timeout: _scanTimeout)
        .listen((results) {
      if (mounted) {
        setState(() => _scanResults = List.from(results));
      }
    });

    _scanTimer = Timer(_scanTimeout, () {
      _stopScan();
      if (mounted) {
        setState(() => _statusText = 'Scan complete. Found ${_scanResults.length} devices.');
      }
    });
  }

  Future<void> _manualConnect(BluetoothDevice device) async {
    _stopScan();
    _retryTimer?.cancel();
    setState(() => _manualConnectingId = device.remoteId.toString());

    final result = await widget.bleService.connectWithResult(device);

    if (mounted) {
      setState(() => _manualConnectingId = null);
      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DeviceScreen(bleService: widget.bleService),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: ${result.error}'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LARQ Bridge')),
      body: Column(
        children: [
          _AutoConnectHeader(
            state: _state,
            statusText: _statusText,
            onCancel: _state != _AutoState.off ? _cancelAutoConnect : null,
          ),
          const Divider(),
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
                    child: Text(
                      _state == _AutoState.off
                          ? 'Scan stopped. Use the button below to restart.'
                          : 'No BLE devices found nearby.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) {
                      final result = _scanResults[index];
                      final device = result.device;
                      final name = device.advName.isNotEmpty
                          ? device.advName
                          : (device.platformName.isNotEmpty
                              ? device.platformName
                              : 'Unknown');
                      final isLarq = _isBottle(result);
                      final isConnecting =
                          _manualConnectingId == device.remoteId.toString();
                      return Card(
                        color: isLarq ? Colors.teal.shade50 : null,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: ListTile(
                          leading: Icon(
                            isLarq ? Icons.water_drop : Icons.bluetooth,
                            size: 36,
                            color: isLarq ? Colors.teal : Colors.grey,
                          ),
                          title: Text(name),
                          subtitle:
                              Text('${device.remoteId}\nRSSI: ${result.rssi} dBm'),
                          trailing: isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : ElevatedButton(
                                  onPressed: () => _manualConnect(device),
                                  child: const Text('Connect'),
                                ),
                        ),
                      );
                    },
                  ),
          ),
          // Manual scan button bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _manualStartScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Manual Scan'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoConnectHeader extends StatelessWidget {
  final _AutoState state;
  final String statusText;
  final VoidCallback? onCancel;

  const _AutoConnectHeader({
    required this.state,
    required this.statusText,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _StatusIcon(state: state),
          const SizedBox(height: 12),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onCancel,
              child: const Text('Stop auto-connect'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final _AutoState state;

  const _StatusIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _AutoState.scanning:
        return const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case _AutoState.connecting:
        return const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.teal),
        );
      case _AutoState.wakeBottle:
        return const Icon(Icons.coffee, size: 48, color: Colors.orange);
      case _AutoState.error:
        return const Icon(Icons.error_outline, size: 48, color: Colors.red);
      case _AutoState.off:
        return const Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey);
    }
  }
}
