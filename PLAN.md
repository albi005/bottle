# Phase 1 Implementation Plan — BLE Scanning, Sensor Reading & Log Syncing

> Plan for the first phase: connect to bottles, read live sensor values,
> sync logs to SQLite, and display everything with real-time state visibility.
> Supports **multiple bottles simultaneously**.

---

## 1. Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                           UI Layer                                     │
│  ┌───────────────┐  ┌──────────────────┐  ┌──────────────────────┐   │
│  │ BottleList    │  │ BottleDetail     │  │ BottleDetail         │   │
│  │  - LARQ_A     │  │  - SensorCard(s) │  │  (another bottle)    │   │
│  │  - LARQ_B     │  │  - LogSyncProg   │  │                      │   │
│  │  - ...        │  │                  │  │                      │   │
│  └───────┬───────┘  └────────┬─────────┘  └──────────┬───────────┘   │
│          │                   │                        │               │
├──────────┼───────────────────┼────────────────────────┼───────────────┤
│          │           State Layer (signals)             │               │
│  ┌───────┴───────────────────┴────────────────────────┴──────────┐    │
│  │  activeBottles: ListSignal<BottleController>                   │    │
│  │  selectedBottleIndex: Signal<int?>                             │    │
│  │                                                                │    │
│  │  BottleController (one per bottle):                            │    │
│  │    name        connectionPhase   rssi     connectionError      │    │
│  │    sensorValues  logSyncPhase    logSyncProgress  refreshPhase │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│       Service Layer (per-bottle instances created by BottleController)  │
│                                                                        │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐               │
│  │ BleScanner   │   │BottleController│  │BottleController│  ...        │
│  │ (singleton)  │   │               │   │               │             │
│  │              │   │  Connection   │   │  Connection   │             │
│  │ scan()       │   │  Service      │   │  Service      │             │
│  │ onScanResults│──▶│  SensorSvc    │   │  SensorSvc    │             │
│  │ stopScan()   │   │  LogService   │   │  LogService   │             │
│  └──────────────┘   │  RefreshLoop  │   │  RefreshLoop  │             │
│                     └──────┬───────┘   └──────┬───────┘             │
│                            │                   │                     │
│                     FlutterBluePlus    FlutterBluePlus               │
│                       (per device)       (per device)                │
│                            │                   │                     │
│                       ┌────┴────┐        ┌────┴────┐                │
│                       │ LARQ_A  │        │ LARQ_B  │                │
│                       └─────────┘        └─────────┘                │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐    │
│  │  SQLite (LogRepository) — one DB, bottle_name column on logs │    │
│  └──────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2. State Model

### 2.1 BottleController — Per-Bottle State & Lifecycle

Each visible/connected bottle is represented by a `BottleController`.
It **owns** all signals for that bottle and creates its own service instances.

```dart
class BottleController {
  // ── Identity ──
  final String name;  // from device.platformName (e.g. "LARQ_0jMdSZS8blV")
  final String remoteId; // for device.fromId() persistence

  // ── Connection ──
  final connectionPhase = signal<ConnectionPhase>(ConnectionPhase.visible);
  final connectionError = signal<String?>(null);
  final rssi           = signal<int?>(null);
  final scanResult     = signal<ScanResult?>(null);

  // ── Sensor Values ──
  final uiState          = signal<SensorValue<CapUiStateData>>(SensorNotQueried());
  final tofDistance      = signal<SensorValue<int>>(SensorNotQueried());
  final sipCounter       = signal<SensorValue<int>>(SensorNotQueried());
  final hallEffect       = signal<SensorValue<HallEffectData>>(SensorNotQueried());
  final bottlePresent    = signal<SensorValue<bool>>(SensorNotQueried());
  final ambientLight     = signal<SensorValue<double>>(SensorNotQueried());
  final accelerometer    = signal<SensorValue<AccelData>>(SensorNotQueried());
  final batteryLevel     = signal<SensorValue<int>>(SensorNotQueried());
  final deviceInfo       = signal<SensorValue<DeviceInfo>>(SensorNotQueried());

  // ── Log Sync ──
  final logSyncPhase    = signal<LogSyncPhase>(LogSyncPhase.idle);
  final logSyncProgress = signal<(String logType, int cursor)>(('', 0));
  final logTypesSynced  = setSignal<String>({});   // log types that have finished syncing
  final logSyncError    = signal<String?>(null);

  // ── Refresh Loop ──
  final refreshPhase     = signal<RefreshPhase>(RefreshPhase.idle);
  final lastRefreshTime  = signal<DateTime?>(null);

  // ── Internal services (null until connected) ──
  BottleConnection? _connection;
  BottleService? _bottleService;
  SensorService? _sensorService;
  LogService? _logService;
  RefreshLoop? _refreshLoop;

  // ── Methods ──
  Future<void> connect(ScanResult result) async { ... }
  Future<void> disconnect() async { ... }
  void updateScan(ScanResult result) { ... }
}
```

**Connection phases** (per-bottle):

```
             scan finds LARQ_A
  ┌──────────┐                  ┌─────────┐
  │ notFound │ ───────────────→ │ visible │
  └──────────┘                  └────┬────┘
                                     │ user taps Connect / auto-connect
                                ┌────┴───────┐
                                │ connecting │
                                └────┬───────┘
                      ┌──────────────┼──────────────┐
                      │ success      │ failure       │
                 ┌────┴────────┐ ┌──┴──────────┐    │
                 │ discovering │ │   failed     ├────┘
                 └────┬───────┘ │  (error msg) │
                      │         └──────────────┘
                 ┌────┴────┐
                 │  ready  │──── start RefreshLoop
                 └────┬────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
 refreshSensors  syncLogs     disconnect
```

```dart
enum ConnectionPhase {
  notFound,      // bottle not visible in scan
  visible,       // found in scan results, not yet connecting
  connecting,    // device.connect() in progress
  discovering,   // discoverServices() in progress
  ready,         // connected, services discovered, idle
  failed,        // connection or discovery threw an error
}
```

### 2.2 Per-Sensor State (inside BottleController)

```dart
sealed class SensorValue<T> {
  const SensorValue();
}
class SensorNotQueried<T> extends SensorValue<T> {}
class SensorLoading<T> extends SensorValue<T> {}
class SensorData<T> extends SensorValue<T> {
  final T value;
  final bool refreshing; // true while a new value is being fetched
  const SensorData(this.value, {this.refreshing = false});
}
class SensorError<T> extends SensorValue<T> {
  final String message;
  const SensorError(this.message);
}
```

**Refresh strategy:** On each cycle, sensors that already have a `SensorData`
value are updated to `SensorData(oldValue, refreshing: true)` — the old value
**stays visible** but gets a subtle spinner next to it. As each getter returns,
its signal transitions to `SensorData(newValue, refreshing: false)`. Sensors
that have never been queried go through `SensorLoading` as before.

Only the currently-in-flight sensor shows a spinner; all others show their
last-known value with no spinner.

### 2.3 Log Sync State (inside BottleController)

```dart
enum LogSyncPhase { idle, syncing, done, error }
```

### 2.4 Global (App-Level) Signals

```dart
// All active bottle controllers (visible, connecting, connected)
final activeBottles = listSignal<BottleController>([]);

// Which bottle the user is currently viewing in the detail pane
final selectedBottleIndex = signal<int?>(null);

// Bluetooth adapter state
final bluetoothAdapterState = signal<BluetoothAdapterState>(BluetoothAdapterState.unknown);
final isScanning = signal<bool>(false);
```

The scanner creates/updates `BottleController` instances in `activeBottles`.
When a bottle disappears from scan results, its `connectionPhase` moves to
`notFound` but the controller stays in the list (so the user can see history).
Controllers can be removed manually.

---

## 3. Implementation Steps

### Step 0 — Dependencies & Project Setup

**Add to `pubspec.yaml`:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_blue_plus: ^2.2.0
  signals: ^6.3.0
  protobuf: ^3.1.0
  sqflite: ^2.3.0
  path: ^1.9.0
  path_provider: ^2.1.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

**Android permissions** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-feature android:name="android.hardware.bluetooth_le" android:required="false" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="28" />
```

Set `android { defaultConfig { minSdk = 21 } }` in `android/app/build.gradle.kts`.

**iOS permissions** (`ios/Runner/Info.plist`):

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to communicate with your LARQ bottle.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

**Protobuf compilation:**

Copy the `.proto` files describing the bottle's protocol into a `protos/` directory at the
project root.  Compile to Dart via:

```bash
protoc --dart_out=lib/protos protos/*.proto
```

---

### Step 1 — Protobuf Models

Compile the bottle's `.proto` files into Dart classes.  The generated files live in
`lib/protos/` and provide every message type needed to speak the bottle's protocol:

- **Envelope:** `CapBleRequest` (with `requestId` and `body` `Any`), `CapBleResponse` (with `requestId`, `code`, `body` `Any`)
- **Sensor getter request/response pairs:** `RequestGetCapUiState` / `ResponseGetCapUiState`, `RequestGetCapTofState` / `ResponseGetCapTofState`, `RequestGetCapSipSensorState` / `ResponseGetCapSipSensorState`, `RequestGetCapHallEffectSensorState` / `ResponseGetCapHallEffectSensorState`, `RequestGetCapBottleSensorState` / `ResponseGetCapBottleSensorState`, `RequestGetCapAmbientLightSensorState` / `ResponseGetCapAmbientLightSensorState`, `RequestGetCapAccelerometerState` / `ResponseGetCapAccelerometerState`
- **Log query types:** `CapLogQuery` (with `fromTimestamp`, `limit`, `algo`), `CapEnumLogQuerySearchAlgo`, plus the six log request/response pairs: `RequestGetCapTofLog` / `ResponseGetCapTofLog`, `RequestGetCapStateLog` / `ResponseGetCapStateLog`, `RequestGetCapActivationLog` / `ResponseGetCapActivationLog`, `RequestGetCapFaultLog` / `ResponseGetCapFaultLog`, `RequestGetActivationCapAdcLog` / `ResponseGetActivationCapAdcLog`, `RequestGetChargingCapAdcLog` / `ResponseGetChargingCapAdcLog`
- **Sensor state types:** `CapUiState`, `CapTofState`, `CapSipSensorState`, `CapHallEffectSensorState`, `CapBottleSensorState`, `CapAmbientLightSensorState`, `CapAccelerometerState`, `CapPowerSavingMode`, `CapEnumUiState`
- **Log entry types:** `CapTofLog`, `CapActivationLog`, `CapFaultLog`, `CapStateLog`, `CapAdcLog`
- **Enums:** `CapEnumResponseCode` (FAIL=0, SUCCESS=1, NOT_SUPPORTED=2), `CapEnumTofTriggerType`, `CapEnumUvActivationMode`, `CapEnumFaultType`, `CapEnumLogQuerySearchAlgo`

---

### Step 2 — BLE Scanner Service (Singleton)

**File:** `lib/services/ble_scanner.dart`

**Responsibilities:**
- Start/stop BLE scanning
- Filter scan results by NUS service UUID + `LARQ_*` name
- Create/update/remove `BottleController` instances in `activeBottles`
- Update RSSI on existing controllers

**Pseudo-code:**

```dart
class BleScanner {
  static const nusServiceUuid = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  StreamSubscription? _scanSubscription;

  void startScanning() {
    isScanning.value = true;

    FlutterBluePlus.startScan(
      withServices: [nusServiceUuid],
    );

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      final larqBottles = results.where(
        (r) => r.device.platformName.startsWith('LARQ_'),
      );

      // Track which bottles were seen in this scan batch
      final seenNames = <String>{};

      for (final result in larqBottles) {
        final name = result.device.platformName;
        seenNames.add(name);

        // Find existing controller or create new one
        final existing = activeBottles.value.cast<BottleController?>()
            .firstWhere((b) => b?.name == name, orElse: () => null);

        if (existing != null) {
          // Update RSSI/scan for an already-tracked bottle
          existing.updateScan(result);
        } else {
          // New bottle discovered — create controller
          final controller = BottleController(
            name: name,
            remoteId: result.device.remoteId.toString(),
          )..updateScan(result);

          activeBottles.add(controller);

          // Auto-select if no bottle is currently selected
          if (selectedBottleIndex.value == null) {
            selectedBottleIndex.value = activeBottles.length - 1;
          }
        }
      }

      // Mark bottles that disappeared from scan as notFound
      for (final controller in activeBottles) {
        if (!seenNames.contains(controller.name)) {
          if (controller.connectionPhase.value == ConnectionPhase.visible ||
              controller.connectionPhase.value == ConnectionPhase.connecting ||
              controller.connectionPhase.value == ConnectionPhase.failed) {
            controller.rssi.value = null;
            // Keep controller in list; just mark as not currently visible
            // Don't change connectionPhase if connecting/connected
          }
        }
      }
    });
  }

  void stopScanning() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    isScanning.value = false;
  }
}
```

**Adapter state listener** (in `app.dart`):

```dart
FlutterBluePlus.adapterState.listen((state) {
  bluetoothAdapterState.value = state;
  if (state == BluetoothAdapterState.on) {
    bleScanner.startScanning();
  } else {
    bleScanner.stopScanning();
  }
});
```

---

### Step 3 — BottleController Lifecycle

**File:** `lib/state/bottle_controller.dart`

**Pseudo-code:**

```dart
class BottleController {
  // ... signal fields (see 2.1) ...

  BottleController({required this.name, required this.remoteId});

  /// Update scan metadata (RSSI) without changing connection state.
  void updateScan(ScanResult result) {
    scanResult.value = result;
    rssi.value = result.rssi;
    if (connectionPhase.value == ConnectionPhase.notFound) {
      connectionPhase.value = ConnectionPhase.visible;
    }
  }

  /// Connect to this bottle. Called when user taps "Connect".
  Future<void> connect(ScanResult result) async {
    updateScan(result);

    _connection = BottleConnection();
    connectionPhase.value = ConnectionPhase.connecting;
    connectionError.value = null;

    try {
      await _connection!.connect(result.device);

      connectionPhase.value = ConnectionPhase.discovering;
      await _connection!.discoverServices();

      // Create per-bottle services
      _bottleService = BottleService(_connection!);
      _sensorService = SensorService(_bottleService!);
      _logService = LogService(_bottleService!, LogRepository.instance);

      // Subscribe to RX for this bottle
      await _connection!.subscribeToRx(_bottleService!._onResponse);

      connectionPhase.value = ConnectionPhase.ready;

      // Start the refresh loop
      _refreshLoop = RefreshLoop(_sensorService!, _logService!, this);
      _refreshLoop!.start();

    } catch (e) {
      connectionPhase.value = ConnectionPhase.failed;
      connectionError.value = e.toString();
    }
  }

  /// Disconnect from this bottle.
  Future<void> disconnect() async {
    _refreshLoop?.stop();
    _connection?.disconnect();
    connectionPhase.value = ConnectionPhase.notFound;
    rssi.value = null;
  }

  /// Called by BottleConnection when the device disconnects unexpectedly.
  void onDisconnected() {
    _refreshLoop?.stop();
    connectionPhase.value = ConnectionPhase.notFound;
    rssi.value = null;
  }
}
```

---

### Step 4 — BottleConnection (Per-Device, Instantiable)

**File:** `lib/services/bottle_connection.dart`

Same UUID constants and characteristic caching as before, but now **instantiated
per bottle** and no longer references global signals directly.

```dart
class BottleConnection {
  static const txUuid   = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const rxUuid   = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  static const battChar = Guid('00002a19');
  static const modelChar = Guid('00002a24');
  static const firmwareChar = Guid('00002a26');

  BluetoothDevice? device;
  BluetoothCharacteristic? txChar;
  BluetoothCharacteristic? rxChar;
  BluetoothCharacteristic? batteryChar;
  BluetoothCharacteristic? modelNumberChar;
  BluetoothCharacteristic? firmwareChar;
  StreamSubscription<List<int>>? _rxSubscription;

  Future<void> connect(BluetoothDevice dev) async {
    device = dev;
    await device!.connect(
      autoConnect: true,
      mtu: null,
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> discoverServices() async {
    await device!.discoverServices();
    for (final svc in device!.servicesList) {
      for (final c in svc.characteristics) {
        final u = c.uuid.toString();
        if (u == txUuid) txChar = c;
        if (u == rxUuid) rxChar = c;
        if (u == '00002a19') batteryChar = c;
        if (u == '00002a24') modelNumberChar = c;
        if (u == '00002a26') firmwareChar = c;
      }
    }
  }

  Future<void> subscribeToRx(void Function(List<int>) onData) async {
    await rxChar!.setNotifyValue(true);
    _rxSubscription = rxChar!.onValueReceived.listen(onData);
  }

  Future<void> disconnect() async {
    _rxSubscription?.cancel();
    await device?.disconnect();
  }
}
```

---

### Step 5 — BottleService (Request/Response Protocol, Per-Bottle)

**File:** `lib/services/bottle_service.dart`

Each `BottleController` creates its own `BottleService` instance.  The service
encodes/decodes protobuf messages and correlates requests to responses using the
`requestId` field that the bottle echoes back.

```dart
class BottleService {
  final BottleConnection _connection;
  int _nextRequestId = 0;
  final _pending = <int, Completer<CapBleResponse>>{};

  // ── Called by BottleConnection when data arrives on RX ──

  void onResponse(List<int> data) {
    final response = CapBleResponse.fromBuffer(data);
    final completer = _pending.remove(response.requestId);
    if (completer == null) return; // unsolicited (shouldn't happen)
    completer.complete(response);
  }

  // ── Send a serialised request and wait for the response ──

  Future<CapBleResponse> _sendRequest(Uint8List writtenBytes) async {
    final requestId = _nextRequestId++;

    // The first field of CapBleRequest is fixed32 requestId (tag = 0x0d).
    // Replace the four bytes after the tag with the new requestId.
    final bytes = Uint8List(writtenBytes.length);
    bytes.setAll(0, writtenBytes);
    bytes[1] = (requestId >> 0)  & 0xFF;
    bytes[2] = (requestId >> 8)  & 0xFF;
    bytes[3] = (requestId >> 16) & 0xFF;
    bytes[4] = (requestId >> 24) & 0xFF;

    final completer = Completer<CapBleResponse>();
    _pending[requestId] = completer;

    await _connection.txChar!.write(bytes, withoutResponse: false);

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Request $requestId timed out'),
    );
  }

  // ── Encode a request body, send, decode the response ──

  Future<T> _sendGetter<T>({
    required String typeUrl,
    required Uint8List body,
    required T Function(CapBleResponse) decoder,
  }) async {
    final request = CapBleRequest()
      ..body = (Any()
        ..typeUrl = typeUrl
        ..value = body);

    final response = await _sendRequest(
      Uint8List.fromList(request.writeToBuffer()));

    if (response.code != CapEnumResponseCode.SUCCESS) {
      throw Exception(
        'Request failed: code=${response.code} typeUrl=$typeUrl');
    }

    return decoder(response);
  }

  // ── Sensor getters ──

  Future<CapUiStateData> getUiState() async {
    final req = RequestGetCapUiState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapUiState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapUiState.fromBuffer(r.body.value);
        return CapUiStateData(
          state: data.state.value,
          powerSavingMode: data.powerSavingMode.value,
        );
      },
    );
  }

  Future<int> getTofDistance() async {
    final req = RequestGetCapTofState();
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapTofState',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapTofState.fromBuffer(r.body.value);
        return data.distanceInMillimeter;
      },
    );
  }

  Future<int> getSipCounter() async { /* same pattern: RequestGetCapSipSensorState */ }
  Future<HallEffectData> getHallEffect() async { /* RequestGetCapHallEffectSensorState */ }
  Future<bool> getBottlePresent() async { /* RequestGetCapBottleSensorState */ }
  Future<double> getAmbientLight() async { /* RequestGetCapAmbientLightSensorState */ }
  Future<AccelData> getAccelerometer() async { /* RequestGetCapAccelerometerState */ }

  // ── Standard GATT reads (not protobuf) ──

  Future<int> getBatteryLevel() async {
    final raw = await _connection.batteryChar!.read();
    return raw[0]; // single byte, 0-100
  }

  Future<DeviceInfo> getDeviceInfo() async {
    final model = String.fromCharCodes(
      await _connection.modelNumberChar!.read());
    final fw = String.fromCharCodes(
      await _connection.firmwareChar!.read());
    return DeviceInfo(model: model, firmware: fw);
  }

  // ── Log queries ──

  Future<List<CapTofLog>> getTofLogPage({
    required int fromTimestamp, int limit = 8,
  }) async {
    final query = CapLogQuery()
      ..fromTimestamp = Int64(fromTimestamp)
      ..limit = limit
      ..algo = CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP;

    final req = RequestGetCapTofLog()..query = query;
    return _sendGetter(
      typeUrl: 'type.googleapis.com/RequestGetCapTofLog',
      body: Uint8List.fromList(req.writeToBuffer()),
      decoder: (r) {
        final data = ResponseGetCapTofLog.fromBuffer(r.body.value);
        return data.entries
            .where((e) => e.timestamp.toInt() >= 1000) // filter epoch-0 dummy
            .toList();
      },
    );
  }

  // Same pattern for the other five log types:
  // getActivationLogPage(), getFaultLogPage(), getStateLogPage(),
  // getActivationAdcLogPage(), getChargingAdcLogPage()
}
```

---

### Step 6 — SensorService (Per-Bottle)

**File:** `lib/services/sensor_service.dart`

Receives a `BottleController` to update its signals.  Sensors are queried
**sequentially**, one at a time.  Only the currently-in-flight sensor shows a
spinner — values that have already been refreshed (or not yet reached) show their
last-known value with no indicator.

```dart
class SensorService {
  final BottleService _bottleService;
  final BottleController _controller;

  Future<void> refreshAllSensors() async {
    // Each _queryOne call: mark as loading/refreshing → fetch → write result.
    // Only one sensor has a spinner at any moment.
    await _queryOne(
      _controller.uiState,
      () => _bottleService.getUiState(),
    );
    await _queryOne(
      _controller.tofDistance,
      () => _bottleService.getTofDistance(),
    );
    await _queryOne(
      _controller.sipCounter,
      () => _bottleService.getSipCounter(),
    );
    await _queryOne(
      _controller.hallEffect,
      () => _bottleService.getHallEffect(),
    );
    await _queryOne(
      _controller.bottlePresent,
      () => _bottleService.getBottlePresent(),
    );
    await _queryOne(
      _controller.ambientLight,
      () => _bottleService.getAmbientLight(),
    );
    await _queryOne(
      _controller.accelerometer,
      () => _bottleService.getAccelerometer(),
    );
    await _queryOne(
      _controller.batteryLevel,
      () => _bottleService.getBatteryLevel(),
    );
  }

  /// Mark the signal as refreshing (keeping old value visible), run the
  /// fetch, then write the result.  On error the refreshing flag is cleared
  /// so the old value is shown without a spinner.
  Future<void> _queryOne<T>(
    Signal<SensorValue<T>> target,
    Future<T> Function() fetch,
  ) async {
    // Capture the current value before changing it.
    final previous = target.peek();

    // Step 1: set to loading/refreshing — only THIS sensor shows a spinner.
    if (previous is SensorData<T>) {
      target.value = SensorData<T>(previous.value, refreshing: true);
    } else {
      target.value = SensorLoading<T>();
    }

    // Step 2: fetch.
    try {
      final result = await fetch();
      target.value = SensorData<T>(result);
    } catch (e) {
      // Step 3: on failure, restore the previous state without a spinner.
      if (previous is SensorData<T>) {
        target.value = SensorData<T>(previous.value, refreshing: false);
      } else if (previous is SensorError<T>) {
        target.value = previous;
      } else {
        target.value = SensorError<T>(e.toString());
      }
      print('Sensor query failed: $e');
    }
  }
}
```

**Why sequential?** The bottle processes requests one at a time (no parallelism
benefit).  Sequential execution naturally gives per-sensor loading states — only
the sensor currently being fetched shows a spinner, while the rest display their
last-known value undisturbed.

---

### Step 7 — SQLite Database (Multi-Bottle)

#### 7a — Database Schema

**File:** `lib/db/database.dart`

Each log table now includes a `bottle_name` column to partition logs per bottle:

```dart
await db.execute('''
  CREATE TABLE tof_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bottle_name TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    trigger_type INTEGER NOT NULL,
    distance_mm INTEGER NOT NULL,
    kcps INTEGER NOT NULL,
    uv_led_temp_ohm REAL NOT NULL,
    UNIQUE(bottle_name, timestamp)
  )
''');
```

Same pattern for `activation_logs`, `fault_logs`, `state_logs`, `activation_adc_logs`,
`charging_adc_logs` — each gets a `bottle_name TEXT NOT NULL` column and
`UNIQUE(bottle_name, timestamp)` constraint.

#### 7b — LogRepository (Multi-Bottle)

**File:** `lib/db/log_repository.dart`

All methods now take `bottleName`:

```dart
class LogRepository {
  final Database _db;
  LogRepository(this._db);

  /// Latest timestamp for a bottle's log type (= cursor for incremental sync)
  Future<int> getLatestTimestamp(String table, String bottleName) async {
    final result = await _db.rawQuery(
      'SELECT MAX(timestamp) FROM $table WHERE bottle_name = ?',
      [bottleName],
    );
    final max = result.first.values.first;
    return max != null ? (max as int) + 1 : 0; // +1 = exclusive cursor
  }

  /// Insert, ignoring duplicates (idempotent)
  Future<int> insertTofLogs(String bottleName, List<CapTofLog> entries) async {
    final batch = _db.batch();
    for (final e in entries) {
      batch.insert('tof_logs', {
        'bottle_name': bottleName,
        'timestamp': e.timestamp.toInt(),
        'trigger_type': e.triggerType.value,
        'distance_mm': e.distanceInMillimeter,
        'kcps': e.kcps,
        'uv_led_temp_ohm': e.uvLedTempInOhm,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    return entries.length;
  }

  // … insertActivationLogs, insertFaultLogs, insertStateLogs etc. …
}
```

#### 7c — LogService (Per-Bottle)

**File:** `lib/services/log_service.dart`

Receives a `BottleController` to update log sync signals:

```dart
class LogService {
  final BottleService _bottleService;
  final LogRepository _repo;
  final BottleController _controller;

  Future<void> syncAllLogTypes() async {
    _controller.logSyncPhase.value = LogSyncPhase.syncing;
    _controller.logSyncError.value = null;
    _controller.logTypesSynced.clear();

    final name = _controller.name;

    await _syncLogType(
      name: 'TOF Log', table: 'tof_logs',
      fetcher: (ts) => _bottleService.getTofLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertTofLogs(name, es as List<CapTofLog>),
      entryTs: (e) => (e as CapTofLog).timestamp.toInt(),
    );

    await _syncLogType(
      name: 'Activation Log', table: 'activation_logs',
      fetcher: (ts) => _bottleService.getActivationLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertActivationLogs(name, es),
      entryTs: (e) => (e as CapActivationLog).timestamp.toInt(),
    );

    await _syncLogType(
      name: 'Fault Log', table: 'fault_logs',
      fetcher: (ts) => _bottleService.getFaultLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertFaultLogs(name, es),
      entryTs: (e) => (e as CapFaultLog).timestamp.toInt(),
    );

    await _syncLogType(
      name: 'State Log', table: 'state_logs',
      fetcher: (ts) => _bottleService.getStateLogPage(fromTimestamp: ts),
      inserter: (es) => _repo.insertStateLogs(name, es),
      entryTs: (e) => (e as CapStateLog).timestamp.toInt(),
    );

    _controller.logSyncPhase.value = LogSyncPhase.done;
  }

  Future<void> _syncLogType<T>({
    required String name, required String table,
    required Future<List<T>> Function(int) fetcher,
    required Future<int> Function(List<T>) inserter,
    required int Function(T) entryTs,
  }) async {
    int cursor = await _repo.getLatestTimestamp(table, _controller.name);

    while (true) {
      if (_controller.connectionPhase.value != ConnectionPhase.ready) {
        _controller.logSyncError.value = 'Disconnected during $name sync';
        _controller.logSyncPhase.value = LogSyncPhase.error;
        return;
      }

      _controller.logSyncProgress.value = (name, cursor);

      final entries = await fetcher(cursor);
      if (entries.isEmpty) break;

      await inserter(entries);

      if (entries.length < 8) break; // last page

      cursor = entries.map(entryTs).reduce(max) + 1;
    }

    // This log type is fully synced; mark it done.
    _controller.logTypesSynced.add(name);
  }
}
```

---

### Step 8 — RefreshLoop (Per-Bottle)

**File:** `lib/services/refresh_loop.dart`

Each `BottleController` owns its own loop. Multiple loops run concurrently
when multiple bottles are connected.

```dart
class RefreshLoop {
  final SensorService _sensorService;
  final LogService _logService;
  final BottleController _controller;
  Timer? _timer;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _runCycle();
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _runCycle() async {
    if (!_running) return;
    if (_controller.connectionPhase.value != ConnectionPhase.ready) return;

    try {
      _controller.refreshPhase.value = RefreshPhase.refreshingSensors;
      await _sensorService.refreshAllSensors();

      _controller.refreshPhase.value = RefreshPhase.syncingLogs;
      await _logService.syncAllLogTypes();

      _controller.refreshPhase.value = RefreshPhase.idle;
      _controller.lastRefreshTime.value = DateTime.now();
    } catch (e) {
      _controller.refreshPhase.value = RefreshPhase.error;
    }

    if (_running && _controller.connectionPhase.value == ConnectionPhase.ready) {
      _timer = Timer(const Duration(seconds: 10), _runCycle);
    }
  }
}

enum RefreshPhase { idle, refreshingSensors, syncingLogs, error }
```

**Concurrency note:** Multiple bottles refresh independently in their own async
loops. Each bottle's TX/RX characteristics are separate, so there's no
cross-bottle interference. FlutterBluePlus uses per-device operation queues
(`OperationQueueMode.perDevice`, the default).

---

### Step 9 — UI Components

#### 9a — Main Page Layout (Multi-Bottle)

**File:** `lib/ui/pages/home_page.dart`

Two-pane layout on wide screens, single-pane on narrow:

```
Wide (>600dp)                          Narrow (<600dp)
┌─────────┬──────────────────┐        ┌──────────────────┐
│ Bottle  │  Bottle Detail   │        │   Bottle List    │
│  List   │                  │        │                  │
│ ┌──────┐ │  ┌────────────┐ │        │  LARQ_A  ready   │
│ │LARQ_A│ │  │ Sensors    │ │        │  LARQ_B  visible │
│ │ready │ │  │            │ │        │  LARQ_C  syncing │
│ └──────┘ │  │ TOF: 42mm  │ │        │                  │
│ ┌──────┐ │  │ Bat: 85%   │ │        │  Tap a bottle →  │
│ │LARQ_B│ │  │ ...        │ │        │  push detail     │
│ │ vis. │ │  └────────────┘ │        │                  │
│ └──────┘ │  ┌────────────┐ │        └──────────────────┘
│ ┌──────┐ │  │ Log Sync   │ │
│ │LARQ_C│ │  │            │ │
│ │sync. │ │  │ TOF: 1234  │ │
│ └──────┘ │  │ Act: 12    │ │
│          │  └────────────┘ │
└──────────┴─────────────────┘
```

Narrow layout uses `Navigator.push` to a detail page. Wide layout uses a
`Row` with list on the left and detail on the right.

**Pseudo-code:**

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LARQ Bottles')),
      body: Watch((context) {
        final bottles = activeBottles.value;
        final selectedIdx = selectedBottleIndex.value;
        final isWide = MediaQuery.of(context).size.width > 600;

        if (bottles.isEmpty) {
          return ScanningPlaceholder();
        }

        if (isWide) {
          return Row(children: [
            SizedBox(width: 250, child: BottleListWidget(
              bottles: bottles,
              selectedIndex: selectedIdx,
              onSelect: (i) => selectedBottleIndex.value = i,
            )),
            VerticalDivider(),
            Expanded(child: selectedIdx != null
              ? BottleDetailWidget(controller: bottles[selectedIdx])
              : Text('Select a bottle'),
            ),
          ]);
        } else {
          return BottleListWidget(
            bottles: bottles,
            selectedIndex: selectedIdx,
            onSelect: (i) {
              selectedBottleIndex.value = i;
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BottleDetailPage(controller: bottles[i]),
              ));
            },
          );
        }
      }),
    );
  }
}
```

#### 9b — BottleListTile Widget

Shows one bottle row with its connection phase and RSSI:

```dart
class BottleListTile extends StatelessWidget {
  final BottleController controller;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final phase = controller.connectionPhase.value;
      final rssi = controller.rssi.value;
      final refresh = controller.refreshPhase.value;
      final error = controller.connectionError.value;

      return ListTile(
        selected: selected,
        title: Text(controller.name),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _phaseIcon(phase),
            SizedBox(width: 4),
            Text(phase.name),
            if (rssi != null) Text('  RSSI: $rssi dBm'),
          ]),
          if (error != null) Text('Error: $error',
            style: TextStyle(color: Colors.red, fontSize: 12)),
          if (phase == ConnectionPhase.ready) Text(
            switch (refresh) {
              RefreshPhase.refreshingSensors => 'Refreshing sensors...',
              RefreshPhase.syncingLogs => 'Syncing logs...',
              RefreshPhase.error => 'Refresh error',
              _ => 'Idle',
            },
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ]),
        trailing: switch (phase) {
          ConnectionPhase.connecting || ConnectionPhase.discovering =>
            SizedBox.square(dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          ConnectionPhase.ready =>
            IconButton(icon: Icon(Icons.link_off), onPressed: controller.disconnect),
          ConnectionPhase.visible =>
            IconButton(icon: Icon(Icons.bluetooth), onPressed: () {
              final sr = controller.scanResult.value;
              if (sr != null) controller.connect(sr);
            }),
          _ => null,
        },
        onTap: onTap,
      );
    });
  }

  Widget _phaseIcon(ConnectionPhase phase) => Icon(switch (phase) {
    ConnectionPhase.visible     => Icons.bluetooth_searching,
    ConnectionPhase.connecting  || ConnectionPhase.discovering
                               => Icons.bluetooth_connected,
    ConnectionPhase.ready       => Icons.check_circle,
    ConnectionPhase.failed      => Icons.error,
    ConnectionPhase.notFound    => Icons.bluetooth_disabled,
  }, size: 16);
}
```

#### 9c — BottleDetailWidget

Shows sensor dashboard + log sync for the selected bottle:

```dart
class BottleDetailWidget extends StatelessWidget {
  final BottleController controller;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final phase = controller.connectionPhase.value;

      if (phase != ConnectionPhase.ready) {
        return Center(child: Text('Bottle is ${phase.name}'));
      }

      return Column(children: [
        SensorDashboard(controller: controller),
        Divider(),
        LogSyncCard(controller: controller),
      ]);
    });
  }
}
```

#### 9d — SensorRow Widget

Each sensor uses its own `Watch` widget, independently showing its current state:

```dart
class SensorRow<T> extends StatelessWidget {
  final String label;
  final Signal<SensorValue<T>> signal;
  final String Function(T) formatter;

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final value = signal.value;
      return Row(children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(child: switch (value) {
          SensorNotQueried() => Text('—', style: TextStyle(color: Colors.grey)),
          SensorLoading() => Row(children: [
            SizedBox.square(dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('loading...', style: TextStyle(color: Colors.grey)),
          ]),
          SensorData(:final v, :final refreshing) => Row(children: [
            Text(formatter(v)),
            if (refreshing) ...[
              SizedBox(width: 8),
              SizedBox.square(dimension: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5)),
            ],
          ]),
          SensorError(:final msg) =>
            Text('Error: $msg', style: TextStyle(color: Colors.red)),
        }),
      ]);
    });
  }
}
```

**Behavior:**
- Never queried (first ever refresh): `SensorLoading` → full text "loading..." + spinner
- Already has data, refreshing: `SensorData(42, refreshing: true)` → shows "42 mm" + tiny spinner
- Already has data, refresh complete: `SensorData(42)` → shows "42 mm", no spinner

Usage (in `SensorDashboard`):

```dart
SensorRow(label: 'UI State',  signal: controller.uiState,  formatter: (v) => v.state.name),
SensorRow(label: 'TOF Dist.', signal: controller.tofDistance, formatter: (v) => '$v mm'),
SensorRow(label: 'Sips',      signal: controller.sipCounter, formatter: (v) => '$v'),
SensorRow(label: 'Battery',   signal: controller.batteryLevel, formatter: (v) => '$v%'),
// … etc …
```

#### 9e — LogSyncCard Widget

Shows per-log-type status: spinner for the type currently being synced, checkmark
for completed types, dash for pending ones.

```dart
class LogSyncCard extends StatelessWidget {
  final BottleController controller;

  static const _logTypeOrder = [
    'TOF Log',
    'Activation Log',
    'Fault Log',
    'State Log',
  ];

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final phase = controller.logSyncPhase.value;
      final (currentType, cursor) = controller.logSyncProgress.value;
      final synced = controller.logTypesSynced.value;
      final error = controller.logSyncError.value;

      return Card(child: Padding(padding: EdgeInsets.all(12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log Sync', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          switch (phase) {
            LogSyncPhase.idle => Text('Idle', style: TextStyle(color: Colors.grey)),
            LogSyncPhase.syncing || LogSyncPhase.done => Column(children: [
              for (final t in _logTypeOrder)
                _logTypeRow(
                  label: t,
                  isCurrent: t == currentType && phase == LogSyncPhase.syncing,
                  isDone: synced.contains(t) || phase == LogSyncPhase.done,
                  cursor: t == currentType ? cursor : null,
                ),
            ]),
            LogSyncPhase.error => Text('Error: $error',
              style: TextStyle(color: Colors.red)),
          },
        ],
      )));
    });
  }

  Widget _logTypeRow({
    required String label,
    required bool isCurrent,
    required bool isDone,
    int? cursor,
  }) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 2), child: Row(children: [
      if (isCurrent)
        SizedBox.square(dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5))
      else if (isDone)
        Icon(Icons.check, size: 14, color: Colors.green)
      else
        Icon(Icons.remove, size: 14, color: Colors.grey),
      SizedBox(width: 8),
      Text(label),
      if (cursor != null) ...[
        const Spacer(),
        Text('${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
          style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    ]));
  }
}
```

**Behavior:**
- `LogSyncPhase.idle` → single "Idle" label
- `LogSyncPhase.syncing` → one row per log type: current type shows spinner +
  cursor position; completed types show a checkmark; pending types show a dash
- `LogSyncPhase.done` → all types show a checkmark
- `LogSyncPhase.error` → error message

---

## 4. Complete Data Flow (Multi-Bottle)

```
App Start
  │
  ▼
  Check Bluetooth adapter state
  │
  └─ on → BleScanner.startScanning()
         │
         ▼
  onScanResults → filter LARQ_* → for each bottle name:
    │
    ├─ already in activeBottles? → updateScan(RSSI, scanResult)
    │
    └─ new bottle? → create BottleController → add to activeBottles
                       │
                       ▼ (user taps Connect on bottle's list tile)
           BottleController.connect(scanResult)
                       │
              ┌────────┼────────┐
              ▼        ▼        ▼
         BottleConnection  BottleService(connection, controller)
         BottleService     SensorService(bottleService, controller)
              │            LogService(bottleService, repo, controller)
              │            RefreshLoop(sensorService, logService, controller)
              ▼
         connectionPhase → ready
              │
              ▼
         RefreshLoop.start()
              │
         ┌────┴────┐
         ▼         ▼
    refreshAllSensors()   syncAllLogTypes()
    (per-bottle seq.)     (per-bottle, per log type)
         │                      │
         ▼                      ▼
    update sensor         insert into SQLite
    signals per bottle    (bottle_name column)
         │                      │
         └──────────┬───────────┘
                    ▼
            idle for 10 seconds
                    │
                    └─→ repeat (concurrent with other bottles' loops)

  Disconnect:
    BottleController.disconnect()
    → RefreshLoop.stop() → BottleConnection.disconnect()
    → connectionPhase → notFound
    → controller stays in activeBottles (history visible)
```

---

## 5. File Structure

```
lib/
├── main.dart                             # runApp(BottleApp())
├── app.dart                              # MaterialApp, adapter state listener
│
├── protos/
│   ├── cap.pb.dart                       # generated: all protobuf message classes
│   └── cap.pbenum.dart                   # generated: all protobuf enum classes
│
├── models/
│   ├── bottle_device.dart                # Identity + scan metadata model
│   └── sensor_data.dart                  # SensorValue<T> sealed class + typed wrappers
│
├── state/
│   ├── bottle_controller.dart            # BottleController: per-bottle signals + lifecycle
│   └── app_state.dart                    # Global signals: activeBottles, selectedIndex, etc.
│
├── services/
│   ├── ble_scanner.dart                  # Singleton: scan, create/update BottleControllers
│   ├── bottle_connection.dart            # Per-bottle: connect, discover, char cache
│   ├── bottle_service.dart               # Per-bottle: request/response, all getter methods
│   ├── sensor_service.dart               # Per-bottle: sequential sensor refresh
│   ├── log_service.dart                  # Per-bottle: log pagination + sync orchestration
│   └── refresh_loop.dart                 # Per-bottle: 10s cycle: sensors → logs → idle
│
├── db/
│   ├── database.dart                     # SQLite setup + table creation (bottle_name col)
│   └── log_repository.dart               # CRUD per bottle: insert, getLatestTimestamp
│
└── ui/
    ├── pages/
    │   ├── home_page.dart                # Main scaffold: bottle list + detail pane
    │   └── bottle_detail_page.dart       # Full-page detail for narrow screens
    └── widgets/
        ├── bottle_list_tile.dart          # Single bottle row with phase icon + RSSI + action
        ├── sensor_row.dart                # Single sensor: label + value + spinner
        ├── sensor_dashboard.dart          # All sensor rows grouped
        ├── log_sync_card.dart             # Log sync progress + per-type status
        ├── bottle_detail_widget.dart      # SensorDashboard + LogSyncCard
        └── error_banner.dart              # Dismissible error display
```

---

## 6. Periodic Refresh Loop — Per-Bottle State Diagram

```
  ┌───────────┐
  │ connected │
  │   (ready) │
  └─────┬─────┘
        │
        ▼
  ┌──────────────────┐
  │ refreshingSensors│ ← each sensor signal: loading → data
  └────────┬─────────┘
           │
           ▼
  ┌──────────────┐
  │ syncingLogs  │ ← log types one by one, pages from DB cursor
  └──────┬───────┘
         │
         ▼
  ┌──────────┐
  │   idle   │ ← wait 10 seconds
  └────┬─────┘
       │
       └────────→ back to refreshingSensors

  ┌──────────┐
  │  error   │ ← any step fails → log, wait, retry next cycle
  └──────────┘

Multiple bottles cycle independently. Connection loss during refresh → loop stops.
```

---

## 7. Key Design Decisions

1. **Multi-bottle via per-bottle `BottleController` instances.** Each bottle
   gets its own set of signals, service instances, and refresh loop. The scanner
   manages a `ListSignal<BottleController>` of all known bottles. No global
   state per bottle — everything is scoped to the controller.

2. **One SQLite database, `bottle_name` column on all log tables.** Shared DB
   simplifies backups and queries. The `bottle_name` column partitions data
   per bottle. `UNIQUE(bottle_name, timestamp)` ensures idempotent inserts
   across bottles independently.

3. **Separate `requestId` field for request/response correlation.** The bottle
   echoes the `requestId` back in responses (proto field 1). We use a
   `Map<int, Completer>` per `BottleService` instance to match responses to
   pending requests.

4. **Sequential sensor queries** (not parallel) because:
   - The bottle processes requests one at a time (no parallelism benefit)
   - Sequential naturally gives per-sensor loading states in the UI
   - Simpler error handling — one error doesn't confuse subsequent queries

5. **Forward-only log paging** because:
   - Backward paging is unreliable per RESEARCH.md
   - `fromTimestamp = 0` → oldest first, `fromTimestamp = lastSeen + 1` → next page
   - Each page is at most 8 entries (MTU-limited)
   - Epoch-0 dummy entry (ts < 1000) must be filtered

6. **Module-level `activeBottles` list + per-bottle controller signals** (not
   Provider/InheritedWidget) because:
   - State is global application state, not widget-scoped
   - `Watch` widget gives surgical rebuilding without context boilerplate
   - `BottleController` signals are accessed through the controller reference,
     not via context

7. **SQLite for log persistence** because:
   - Browsable offline when bottle is disconnected
   - Incremental sync via `MAX(timestamp) WHERE bottle_name = ?` query
   - `UNIQUE(bottle_name, timestamp)` constraint for idempotent inserts
   - Simple, no ORM needed for Phase 1

8. **10-second refresh cycle** is the hard-coded interval. The LARQ app itself
   polls periodically (not real-time). 10s provides a good balance of
   responsiveness and battery life. Each bottle's cycle is independent.

9. **Concurrent refresh across bottles:** Each `BottleController`'s refresh
   loop runs in its own async context. FlutterBluePlus uses per-device
   operation queues by default, so BLE commands to different bottles don't
   interfere with each other.

    errors. Errors are displayed in the UI but don't interrupt the user.

---

## 8. Implementation Todo List

### 0 — Dependencies & Project Setup

- [x] 0.1 Add dependencies to `pubspec.yaml`: `flutter_blue_plus: ^2.2.0`, `signals: ^6.3.0`, `protobuf: ^3.1.0`, `sqflite: ^2.3.0`, `path: ^1.9.0`, `path_provider: ^2.1.0`, `collection: ^1.18.0`
- [x] 0.2 Run `flutter pub get`
- [x] 0.3 Add BLE permissions to `android/app/src/main/AndroidManifest.xml` (BLUETOOTH_SCAN, BLUETOOTH_CONNECT, BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, and the `uses-feature` for `hardware.bluetooth_le`)
- [x] 0.4 Set `minSdk = 21` in `android/app/build.gradle.kts` (`defaultConfig { minSdk = 21 }`)
- [x] 0.5 Add Bluetooth usage descriptions to `ios/Runner/Info.plist` (`NSBluetoothAlwaysUsageDescription`) and background mode (`bluetooth-central`)
- [x] 0.6 Create `protos/` directory at project root and copy the `.proto` files into it
- [x] 0.7 Compile `.proto` files to Dart via `protoc --dart_out=lib/protos protos/*.proto` and verify `lib/protos/` contains `cap.pb.dart` and `cap.pbenum.dart`

### 1 — Models

- [x] 1.1 Create `lib/models/sensor_data.dart`
  - [x] 1.1.1 `sealed class SensorValue<T>` with constructors
  - [x] 1.1.2 `SensorNotQueried<T>`
  - [x] 1.1.3 `SensorLoading<T>`
  - [x] 1.1.4 `SensorData<T>` with `final T value` and `final bool refreshing`
  - [x] 1.1.5 `SensorError<T>` with `final String message`
- [x] 1.2 Create `lib/models/bottle_device.dart`
  - [x] 1.2.1 `DeviceInfo` data class (`model`, `firmware`)
  - [x] 1.2.2 `AccelData` data class (`x`, `y`, `z`)
  - [x] 1.2.3 `HallEffectData` data class (`timestamp`, `value`)
  - [x] 1.2.4 `CapUiStateData` data class (`state`, `powerSavingMode`)

### 2 — Global App State

- [x] 2.1 Create `lib/state/app_state.dart`
  - [x] 2.1.1 `activeBottles = listSignal<BottleController>([])`
  - [x] 2.1.2 `selectedBottleIndex = signal<int?>(null)`
  - [x] 2.1.3 `bluetoothAdapterState = signal<BluetoothAdapterState>(BluetoothAdapterState.unknown)`
  - [x] 2.1.4 `isScanning = signal<bool>(false)`
  - [x] 2.1.5 `bleScanner` singleton instantiation

### 3 — BottleController

- [x] 3.1 Create `lib/state/bottle_controller.dart`
  - [x] 3.1.1 `enum ConnectionPhase { notFound, visible, connecting, discovering, ready, failed }`
  - [x] 3.1.2 `enum LogSyncPhase { idle, syncing, done, error }`
  - [x] 3.1.3 `enum RefreshPhase { idle, refreshingSensors, syncingLogs, error }`
  - [x] 3.1.4 `class BottleController` with constructor `({required name, required remoteId})`
  - [x] 3.1.5 Identity fields: `name`, `remoteId`
  - [x] 3.1.6 Connection signals: `connectionPhase`, `connectionError`, `rssi`, `scanResult`
  - [x] 3.1.7 Sensor signals: `uiState`, `tofDistance`, `sipCounter`, `hallEffect`, `bottlePresent`, `ambientLight`, `accelerometer`, `batteryLevel`, `deviceInfo`
  - [x] 3.1.8 Log sync signals: `logSyncPhase`, `logSyncProgress`, `logTypesSynced` (setSignal), `logSyncError`
  - [x] 3.1.9 Refresh signals: `refreshPhase`, `lastRefreshTime`
  - [x] 3.1.10 Internal service fields: `_connection`, `_bottleService`, `_sensorService`, `_logService`, `_refreshLoop` (null until connected)
  - [x] 3.1.11 `updateScan(ScanResult)` — update scanResult, rssi; promote notFound → visible
  - [x] 3.1.12 `connect(ScanResult)` — create BottleConnection, connect, discoverServices, create services, subscribeToRx, start RefreshLoop; set connectionPhase transitions
  - [x] 3.1.13 `disconnect()` — stop RefreshLoop, disconnect BottleConnection, reset phase
  - [x] 3.1.14 `onDisconnected()` — stop RefreshLoop, set phase to notFound

### 4 — BottleConnection (Per-Bottle BLE)

- [x] 4.1 Create `lib/services/bottle_connection.dart`
  - [x] 4.1.1 UUID constants: `txUuid`, `rxUuid`, `battChar`, `modelChar`, `firmwareChar`
  - [x] 4.1.2 Fields: `device`, `txChar`, `rxChar`, `batteryChar`, `modelNumberChar`, `firmwareChar`, `_rxSubscription`
  - [x] 4.1.3 `connect(BluetoothDevice)` — `device.connect(autoConnect: true, mtu: null, timeout: Duration(seconds: 15))`
  - [x] 4.1.4 `discoverServices()` — iterate services/characteristics and cache TX, RX, battery, model, firmware chars by UUID
  - [x] 4.1.5 `subscribeToRx(void Function(List<int>) onData)` — `rxChar!.setNotifyValue(true)`, listen to `onValueReceived`
  - [x] 4.1.6 `disconnect()` — cancel rx subscription, disconnect device

### 5 — BottleService (Request/Response Protocol)

- [x] 5.1 Create `lib/services/bottle_service.dart`
  - [x] 5.1.1 Import generated protobuf classes from `lib/protos/`
  - [x] 5.1.2 Constructor takes `BottleConnection`
  - [x] 5.1.3 `_nextRequestId` counter and `Map<int, Completer<CapBleResponse>> _pending`
  - [x] 5.1.4 `onResponse(List<int> data)` — decode `CapBleResponse`, resolve matching completer, remove from pending
  - [x] 5.1.5 `_sendRequest(Uint8List writtenBytes)` — patch `requestId` into bytes 1-4 (tag 0x0d), write to TX, return completer.future with 10s timeout
  - [x] 5.1.6 `_sendGetter<T>({typeUrl, body, decoder})` — encode `CapBleRequest` with `Any` body, send, decode response, check SUCCESS code
  - [x] 5.1.7 `getUiState()` → `CapUiStateData`
  - [x] 5.1.8 `getTofDistance()` → `int`
  - [x] 5.1.9 `getSipCounter()` → `int`
  - [x] 5.1.10 `getHallEffect()` → `HallEffectData`
  - [x] 5.1.11 `getBottlePresent()` → `bool`
  - [x] 5.1.12 `getAmbientLight()` → `double`
  - [x] 5.1.13 `getAccelerometer()` → `AccelData`
  - [x] 5.1.14 `getBatteryLevel()` → `int` (GATT read from batteryChar, first byte)
  - [x] 5.1.15 `getDeviceInfo()` → `DeviceInfo` (GATT reads from model + firmware chars)
  - [x] 5.1.16 `getTofLogPage({fromTimestamp, limit})` → `List<CapTofLog>` with epoch-0 filter (timestamp >= 1000)
  - [x] 5.1.17 `getActivationLogPage({fromTimestamp, limit})` → `List<CapActivationLog>`
  - [x] 5.1.18 `getFaultLogPage({fromTimestamp, limit})` → `List<CapFaultLog>`
  - [x] 5.1.19 `getStateLogPage({fromTimestamp, limit})` → `List<CapStateLog>`
  - [x] 5.1.20 `getActivationAdcLogPage({fromTimestamp, limit})` → `List<CapAdcLog>`
  - [x] 5.1.21 `getChargingAdcLogPage({fromTimestamp, limit})` → `List<CapAdcLog>`

### 6 — SensorService (Per-Bottle Sequential Refresh)

- [x] 6.1 Create `lib/services/sensor_service.dart`
  - [x] 6.1.1 Constructor takes `BottleService`, `BottleController`
  - [x] 6.1.2 `refreshAllSensors()` — await each `_queryOne` call in sequence (uiState → tofDistance → sipCounter → hallEffect → bottlePresent → ambientLight → accelerometer → batteryLevel)
  - [x] 6.1.3 `_queryOne<T>(Signal<SensorValue<T>>, fetch)` — peek current value, mark refreshing (or loading if no prior data), fetch, write result or restore previous on error

### 7 — SQLite Database

- [x] 7.1 Create `lib/db/database.dart`
  - [x] 7.1.1 `Database? _db` field and `Future<Database> get database` singleton getter
  - [x] 7.1.2 `_onCreate(Database db, int version)` — create all 6 log tables (`tof_logs`, `activation_logs`, `fault_logs`, `state_logs`, `activation_adc_logs`, `charging_adc_logs`) with `bottle_name TEXT NOT NULL`, `timestamp INTEGER NOT NULL`, type-specific columns, and `UNIQUE(bottle_name, timestamp)`
- [x] 7.2 Create `lib/db/log_repository.dart`
  - [x] 7.2.1 `getLatestTimestamp(String table, String bottleName)` → `Future<int>` — `SELECT MAX(timestamp)`, return 0 if null
  - [x] 7.2.2 `insertTofLogs(String bottleName, List<CapTofLog>)` — batch insert with `conflictAlgorithm: ConflictAlgorithm.ignore`
  - [x] 7.2.3 `insertActivationLogs(String bottleName, List<CapActivationLog>)`
  - [x] 7.2.4 `insertFaultLogs(String bottleName, List<CapFaultLog>)`
  - [x] 7.2.5 `insertStateLogs(String bottleName, List<CapStateLog>)`
  - [x] 7.2.6 `insertActivationAdcLogs(String bottleName, List<CapAdcLog>)`
  - [x] 7.2.7 `insertChargingAdcLogs(String bottleName, List<CapAdcLog>)`

### 8 — LogService (Per-Bottle Log Sync)

- [x] 8.1 Create `lib/services/log_service.dart`
  - [x] 8.1.1 Constructor takes `BottleService`, `LogRepository`, `BottleController`
  - [x] 8.1.2 `syncAllLogTypes()` — set phase to syncing, clear errors and typesSynced, call `_syncLogType` for each of the 6 log types sequentially, then set phase to done
  - [x] 8.1.3 `_syncLogType<T>({name, table, fetcher, inserter, entryTs})` — get cursor from DB, page forward 8 entries at a time, insert each page, stop when empty or < 8, update `logSyncProgress` and `logTypesSynced` signals during sync, check connectionPhase before each page

### 9 — RefreshLoop (Per-Bottle 10s Cycle)

- [x] 9.1 Create `lib/services/refresh_loop.dart`
  - [x] 9.1.1 Constructor takes `SensorService`, `LogService`, `BottleController`
  - [x] 9.1.2 `start()` — guard against double-start, set `_running = true`, call `_runCycle()`
  - [x] 9.1.3 `stop()` — set `_running = false`, cancel timer
  - [x] 9.1.4 `_runCycle()` — check running + ready, set refreshPhase to refreshingSensors → refreshAllSensors, set to syncingLogs → syncAllLogTypes, set to idle, schedule next cycle in 10s, catch errors → set refreshPhase error

### 10 — BleScanner

- [x] 10.1 Create `lib/services/ble_scanner.dart`
  - [x] 10.1.1 `nusServiceUuid` constant (`Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e')`)
  - [x] 10.1.2 `_scanSubscription` field
  - [x] 10.1.3 `startScanning()` — set `isScanning = true`, call `FlutterBluePlus.startScan(withServices: [nusServiceUuid])` (no timeout), subscribe to `onScanResults`
  - [x] 10.1.4 Scan results handler — filter by `platformName.startsWith('LARQ_')`, track seen names, create new `BottleController` or call `updateScan` on existing, auto-select first bottle if none selected, mark unseen controllers as notFound (if not currently connecting/connected)
  - [x] 10.1.5 `stopScanning()` — cancel subscription, `FlutterBluePlus.stopScan()`, set `isScanning = false`

### 11 — App Entry Point

- [x] 11.1 Create `lib/app.dart`
  - [x] 11.1.1 `BottleApp` StatelessWidget — `MaterialApp(title: 'LARQ Bottles', home: HomePage())`
  - [x] 11.1.2 Listen to `FlutterBluePlus.adapterState` and start/stop scanner when adapter turns on/off
  - [x] 11.1.3 Handle adapter state changes: on → `bleScanner.startScanning()`, off/unauthorized → `bleScanner.stopScanning()`
- [x] 11.2 Rewrite `lib/main.dart`
  - [x] 11.2.1 Initialize database before `runApp`
  - [x] 11.2.2 `runApp(const BottleApp())`

### 12 — UI Pages

- [x] 12.1 Create `lib/ui/pages/home_page.dart`
  - [x] 12.1.1 `HomePage` StatelessWidget with `Watch` wrapping the body
  - [x] 12.1.2 Empty state: `ScanningPlaceholder` when `activeBottles` is empty
  - [x] 12.1.3 Wide layout (\(>600\)dp): `Row` with 250px `BottleListWidget` + `VerticalDivider` + `Expanded` `BottleDetailWidget`
  - [x] 12.1.4 Narrow layout: full-width `BottleListWidget`, tapping a bottle pushes `BottleDetailPage` via `Navigator`
  - [x] 12.1.5 `ScanningPlaceholder` widget — spinner + "Scanning for bottles..."
- [x] 12.2 Create `lib/ui/pages/bottle_detail_page.dart`
  - [x] 12.2.1 `BottleDetailPage` StatelessWidget taking `BottleController`
  - [x] 12.2.2 AppBar with bottle name, scaffold body with `BottleDetailWidget`

### 13 — UI Widgets

- [x] 13.1 Create `lib/ui/widgets/bottle_list_tile.dart`
  - [x] 13.1.1 `BottleListTile` StatelessWidget (props: controller, selected, onTap)
  - [x] 13.1.2 Watch on connectionPhase, rssi, refreshPhase, connectionError
  - [x] 13.1.3 `_phaseIcon(ConnectionPhase)` helper returning 16px icon per phase
  - [x] 13.1.4 Title: controller.name; subtitle: phase icon + phase name + RSSI + error text + refresh sub-status
  - [x] 13.1.5 Trailing: spinner for connecting/discovering, disconnect button for ready, connect button for visible
- [x] 13.2 Create `lib/ui/widgets/sensor_row.dart`
  - [x] 13.2.1 `SensorRow<T>` StatelessWidget (props: label, signal, formatter)
  - [x] 13.2.2 Watch on signal value, pattern match: notQueried → dash, loading → spinner + "loading...", data → formatted value + tiny spinner if refreshing, error → red error text
- [x] 13.3 Create `lib/ui/widgets/sensor_dashboard.dart`
  - [x] 13.3.1 `SensorDashboard` StatelessWidget taking `BottleController`
  - [x] 13.3.2 Render `SensorRow` for each sensor: uiState, tofDistance, sipCounter, hallEffect, bottlePresent, ambientLight, accelerometer, batteryLevel, deviceInfo
  - [x] 13.3.3 Section header "Sensors"
- [x] 13.4 Create `lib/ui/widgets/log_sync_card.dart`
  - [x] 13.4.1 `LogSyncCard` StatelessWidget taking `BottleController`
  - [x] 13.4.2 `_logTypeOrder` const list: TOF Log, Activation Log, Fault Log, State Log, Activation ADC Log, Charging ADC Log
  - [x] 13.4.3 Watch on logSyncPhase, logSyncProgress, logTypesSynced, logSyncError
  - [x] 13.4.4 Pattern match: idle → "Idle", syncing/done → render rows, error → error message
  - [x] 13.4.5 `_logTypeRow` — spinner (if current type), checkmark (if done), dash (if pending); cursor value for current type
- [x] 13.5 Create `lib/ui/widgets/bottle_detail_widget.dart`
  - [x] 13.5.1 `BottleDetailWidget` StatelessWidget taking `BottleController`
  - [x] 13.5.2 Watch on connectionPhase: not ready → "Bottle is ${phase.name}", ready → Column with SensorDashboard + Divider + LogSyncCard
- [x] 13.6 Create `lib/ui/widgets/error_banner.dart`
  - [x] 13.6.1 `ErrorBanner` StatelessWidget taking `message` and `onDismiss`
  - [x] 13.6.2 Red MaterialBanner with dismiss action

### 14 — Verify

- [x] 14.1 Run `dart analyze` on the project, fix any errors or warnings
- [x] 14.2 Verify all imports resolve correctly
- [x] 14.3 Verify .proto files are in place and compiled
