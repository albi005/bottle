# Library Research — FlutterBluePlus & signals

> Research report on the two core libraries for the LARQ Bottle Flutter app:
> **FlutterBluePlus** for BLE communication and **signals** for state management.

---

## 1. FlutterBluePlus

**Package:** `flutter_blue_plus` v2.3.3  
**pub.dev:** https://pub.dev/packages/flutter_blue_plus  
**GitHub:** https://github.com/chipweinberger/flutter_blue_plus  
**License:** Free for personal/nonprofit/educational use. Commercial license required for for-profit use.  
**Platforms:** Android, iOS, macOS, Linux, Web (plus Windows via `flutter_blue_plus_winrt`)  
**Downloads:** ~200k | **Likes:** ~1.2k

### 1.1 Overview

FlutterBluePlus is the dominant BLE plugin for Flutter, a continuation of the original
FlutterBlue. It supports BLE Central Role only (scanning, connecting, reading/writing
characteristics, subscribing to notifications). This is exactly what the bottle requires —
the phone acts as a BLE Central, writing commands and receiving responses.

Key architectural properties:

- **No dependencies** beyond Flutter + platform SDKs — very stable.
- **Federated plugin** — each platform has its own implementation package.
- **Per-device operation queue** (`OperationQueueMode.perDevice`) allows concurrent
  communication with multiple devices.
- **Streams never emit errors or close** (except `scanResults` which can error). This
  simplifies error handling significantly — no `onError`/`onDone` handlers needed on
  `onValueReceived`, `connectionState`, etc.

### 1.2 Core API Surface

#### Adapter Lifecycle

```dart
// Check support
FlutterBluePlus.isSupported  // Future<bool>

// Bluetooth on/off state
FlutterBluePlus.adapterState     // Stream<BluetoothAdapterState>
FlutterBluePlus.adapterStateNow  // BluetoothAdapterState (sync)

// Turn Bluetooth on (Android only)
FlutterBluePlus.turnOn()   // Future<void>

// BluetothAdapterState values:
//   on, off, turningOn, turningOff, unknown, unauthorized, unavailable
```

**iOS caveat:** `adapterState` always starts as `BluetoothAdapterState.unknown` and
needs a short delay to initialize. `unauthorized` means permissions not granted.

#### Scanning

```dart
// Start scan with filters
FlutterBluePlus.startScan(
  withServices: [Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e")],  // filter by service UUIDs
  withNames: ["LARQ_*"],                                         // filter by name (Android only)
  timeout: Duration(seconds: 15),
  // androidUsesFineLocation: false,  // use neverForLocation flag
);

// Stop scan
FlutterBluePlus.stopScan();

// Stream of scan results
FlutterBluePlus.onScanResults.listen((results) { ... }, onError: (e) => ...);
FlutterBluePlus.scanResults      // Stream<List<ScanResult>> — doesn't clear between scans
FlutterBluePlus.lastScanResults  // List<ScanResult> (sync) — most recent results
FlutterBluePlus.isScanning       // Stream<bool>
FlutterBluePlus.isScanningNow    // bool (sync)

// Auto-cancel subscription when scan stops
FlutterBluePlus.cancelWhenScanComplete(subscription);
```

**Bottle-relevant:** The bottle advertises the NUS service UUID
`6e400001-b5a3-f393-e0a9-e50e24dcca9e`. We can scan with that service filter.
The bottle should also be identified by advertised name matching `LARQ_*` (per RESEARCH.md
on MAC rotation — bottles use Resolvable Private Addresses). Use `device.platformName`
to get the device name — `advertisementData.advName` is usually empty.

**Android scan limits:** Max 5 `startScan` calls per 30 seconds (platform restriction).

#### Connection Management

```dart
BluetoothDevice device;

// Connect
await device.connect(
  autoConnect: false,       // default: false. When true, reconnects automatically
  mtu: 512,                 // default: 512 on Android. Ignored when autoConnect=true
);
await device.connect(autoConnect: true, mtu: null);  // autoConnect requires mtu: null

// Connection state
device.connectionState       // Stream<BluetoothConnectionState>
device.isConnected           // bool (sync)
device.isDisconnected        // bool (sync)

// Disconnect
await device.disconnect();
device.disconnectReason      // DisconnectReason? — contains .code and .description

// Bonding (Android only)
await device.createBond();
await device.removeBond();

// MTU
device.mtu                   // Stream<int> — current MTU + changes
device.mtuNow                // int (sync) — current MTU
await device.requestMtu(512);  // Android only

// Persist device across app restarts
BluetoothDevice.fromId(remoteId);  // remoteId from scan/advertisement

// Cancellation helpers
device.cancelWhenDisconnected(subscription, delayed: true, next: true);
```

**Bottle-relevant:** The bottle negotiates MTU 247. On Android, FBP requests MTU 512
by default on connect. On iOS/macOS, MTU is auto-negotiated (typically 135-255).

For device persistence, store `device.remoteId` (note: differs between Android and iOS —
Android uses MAC, iOS uses random UUID). Since the bottle uses RPA (MAC rotation),
we should identify bottles by name (`LARQ_*`, via `device.platformName`) on each scan rather than persisting remoteId.

#### Service Discovery

```dart
// Must be called after every re-connection!
List<BluetoothService> services = await device.discoverServices();

// Sync access to already-discovered services
device.servicesList  // List<BluetoothService>

// Services changed notification (GATT 0x2A05)
device.onServicesReset.listen(() async {
  await device.discoverServices();  // re-discover
});
```

After discovery, iterate `servicesList` to find characteristics by UUID.

#### Characteristic Operations

```dart
BluetoothCharacteristic c;

// Read
List<int> value = await c.read();

// Write
await c.write([0x12, 0x34]);
await c.write(data, withoutResponse: true);  // for characteristics that don't require response

// Large writes
await c.write(data, allowLongWrite: true);  // up to 512 bytes, with response, slow

// Split write for unlimited data
extension splitWrite on BluetoothCharacteristic {
  Future<void> splitWrite(List<int> value, {int timeout = 15}) async {
    int chunk = min(device.mtuNow - 3, 512);
    for (int i = 0; i < value.length; i += chunk) {
      await write(value.sublist(i, min(i + chunk, value.length)),
        withoutResponse: false, timeout: timeout);
    }
  }
}

// Subscribe to notifications/indications
await c.setNotifyValue(true);
c.isNotifying              // bool (sync)

// Data streams
c.onValueReceived      // Stream<List<int>> — read() results + notifications
c.lastValueStream      // Stream<List<int>> — onValueReceived + writes
c.lastValue            // List<int> (sync) — most recent value
```

**Bottle-relevant:** The bottle uses two NUS characteristics:
- **TX (phone → bottle):** UUID `6e400002-...` — Write / Write Without Response
- **RX (bottle → phone):** UUID `6e400003-...` — Notify

All communication follows a request→response protocol:
1. Phone encodes a `CapBleRequest` protobuf, writes to TX
2. Bottle processes and sends `CapBleResponse` protobuf as a notification on RX

We also read standard GATT characteristics:
- Device Info (0x180A): Model, Serial, Firmware, Hardware, Software, Manufacturer
- Battery Level (0x180F / 0x2A19): Read + Notify

#### Logging

```dart
FlutterBluePlus.setLogLevel(LogLevel.verbose, color: false);
// LogLevel values: none, error, warning, info, debug, verbose

FlutterBluePlus.logs.listen((String s) { ... });
```

`LogLevel.verbose` shows all BLE traffic — essential during development.

#### Global Events API

```dart
// Monitor all devices at once
FlutterBluePlus.events.onConnectionStateChanged.listen((event) { ... });
FlutterBluePlus.events.onMtuChanged.listen((event) { ... });
FlutterBluePlus.events.onCharacteristicReceived.listen((event) { ... });
FlutterBluePlus.events.onCharacteristicWritten.listen((event) { ... });
// ... and more
```

Useful for debugging or centralized logging, but per-device streams are simpler for app logic.

### 1.3 Platform-Specific Notes

| Feature | Android | iOS/macOS | Linux | Web |
|---------|---------|-----------|-------|-----|
| `turnOn`/`turnOff` | ✓ | ✗ | ✓ | ✗ |
| `requestMtu` | ✓ | ✗ | ✗ | ✗ |
| `createBond`/`removeBond` | ✓ | ✗ | ✗ | ✗ |
| `setOptions(restoreState:)` | ✓ | ✓ | ✗ | ✗ |
| Background BLE | Foreground service | `bluetooth-central` bg mode | — | — |
| `remoteId` format | MAC address | Random UUID | D-Bus path | Web Bluetooth ID |

### 1.4 Architecture Pattern for Bottle BLE

The recommended pattern for our app:

```
┌─────────────────────────────────────────────────────┐
│                  BottleConnection                     │
│                                                      │
│  ┌──────────┐   write(TX)   ┌─────────────┐         │
│  │   App    │ ───────────── │   LARQ      │         │
│  │ (Central)│               │  PureVis 2  │         │
│  │          │ ◀───────────── │ (Peripheral)│         │
│  └──────────┘   notify(RX)  └─────────────┘         │
│                                                      │
│  TX: 6e400002-... (Write)                            │
│  RX: 6e400003-... (Notify → onValueReceived)         │
│                                                      │
│  Request→Response pattern:                           │
│    1. write(CapBleRequest bytes) to TX               │
│    2. listen for CapBleResponse bytes on RX          │
│    3. Match by requestId                             │
└─────────────────────────────────────────────────────┘
```

Key design decisions:
- Use **per-device operation queue** for future multi-bottle support.
- Use `onValueReceived` on RX characteristic to receive responses.
- Use `ConnectionState` stream to track connection lifecycle.
- Store bottle identity by advertised name (`device.platformName`), not remoteId (due to MAC rotation).
- Use `autoConnect: true` for persistent reconnection.

---

## 2. signals (dartsignals.dev)

**Package:** `signals` v6.3.1  
**pub.dev:** https://pub.dev/packages/signals  
**Website:** https://dartsignals.dev/  
**GitHub:** https://github.com/rodydavis/signals.dart  
**License:** Apache-2.0  
**Platforms:** All Dart platforms (Flutter, CLI, Server, Web, VM)  
**Downloads:** ~13k (main package), ~17k (signals_flutter) | **Likes:** ~676

### 2.1 Overview

Signals is a fine-grained reactive state management library based on Preact Signals.
It provides `signal()`, `computed()`, and `effect()` as the core primitives, plus
Flutter-specific widgets for surgical (minimal) UI rebuilding.

Key architectural properties:
- **Fine-grained reactivity:** Only widgets/widget-parts that read a changed signal
  are rebuilt — not entire widget subtrees.
- **Lazy evaluation:** Computed signals only re-execute when they have active
  subscribers (effects or watched widgets).
- **Automatic dependency tracking:** Any signal read inside a computed/effect/Watch
  callback is automatically tracked as a dependency.
- **Glitch-free:** Updates are synchronous and consistent within a batch.
- **DevTools extension:** Visualize signal dependency graphs.

### 2.2 Core Primitives

#### `signal(initialValue)`

Creates a mutable reactive value container. Reading `.value` subscribes to it.
Writing `.value` triggers all dependents synchronously.

```dart
import 'package:signals/signals.dart';

final counter = signal(0);
print(counter.value);  // 0
counter.value = 1;     // sync update, triggers dependents
counter.peek();        // read WITHOUT subscribing (rare — use in effects that write signals)
```

#### `computed(fn)`

Creates a read-only derived signal. The callback is lazily evaluated — it only runs
when the computed has subscribers AND a dependency changed. The result is cached.

```dart
final name = signal("Jane");
final surname = signal("Doe");
final fullName = computed(() => "${name.value} ${surname.value}");
// fullName.value == "Jane Doe"
```

A computed only re-evaluates if it has subscribers (an effect, a Watch widget, or
another computed that itself has subscribers).

**Selectors:** For filtered/targeted subscriptions:

```dart
final user = signal((name: "Jane", age: 25));
final userAge = user.select((s) => s.value.age);
// userAge only updates when age changes; name changes are ignored
```

#### `effect(fn)`

Runs a side effect whenever its dependencies change. Returns a dispose function.

```dart
final name = signal("Jane");
final dispose = effect(() {
  print("Name changed to: ${name.value}");
});
name.value = "John";  // prints: "Name changed to: John"
dispose();            // unsubscribes, cleanup

// WARNING: Mutating inside effect without untracked() causes cycles:
effect(() {
  counter.value = counter.value + 1;  // THROWS cycle error
});
```

#### `batch(fn)`

Combines multiple signal writes into one update. Useful when setting multiple
related values that should trigger a single UI rebuild.

```dart
batch(() {
  bottleName.value = "LARQ_XYZ";
  batteryLevel.value = 85;
  waterLevelMm.value = 42;
});
// effect / Watch subscribers fire exactly once after batch completes
```

Nestable — updates flush when the outermost batch completes.

#### `untracked(fn)`

Runs a callback without tracking signal reads. Used inside effects when you need
to read a signal without subscribing to it.

```dart
effect(() {
  print(counter.value);
  otherCounter.value = untracked(() => otherCounter.peek() + 1);
});
```

### 2.3 Flutter Integration (`signals_flutter`)

Import: `import 'package:signals/signals_flutter.dart';`

#### `Watch` Widget — Surgical Rebuilding

```dart
// Only rebuilds the Text, not the entire widget
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      Watch((context) => Text('$counter')),  // only this rebuilds
      const Text('Static content'),
      ElevatedButton(
        onPressed: () => counter.value++,
        child: const Text('Increment'),
      ),
    ],
  );
}
```

`Watch` automatically subscribes to signals read during the builder callback
and unsubscribes when disposed.

**Drop-in replacement for `Builder`:**

```dart
Watch.builder(builder: (context) => Text('$counter'));

// With child optimization:
WatchBuilder(
  builder: (context, child) => Row(children: [Text('$counter'), child!]),
  child: const Icon(Icons.add),
);
```

#### `.watch(context)` Extension

For inline signal access — primarily for widget properties:

```dart
Text('Counter: ${counter.watch(context)}');
Text('Hello', style: TextStyle(fontSize: fontSize.watch(context)));
```

Returns the signal value and subscribes the widget to changes.

#### `SignalsMixin` — Auto-Dispose Signals

Used in `StatefulWidget` state classes. Signals created with `createSignal`
and `createComputed` are automatically disposed when the widget is removed.

```dart
class CounterPage extends StatefulWidget {
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> with SignalsMixin {
  late final counter = createSignal(0);
  late final isEven = createComputed(() => counter.value.isEven);

  @override
  Widget build(BuildContext context) {
    return Watch((context) => Text('Counter: $counter'));
  }
}
```

The `$counter` interpolation works because signals override `toString()` to return
the current value.

#### `SignalProvider` — Global/Scoped Access

Provides signals through the widget tree without `InheritedWidget` boilerplate:

```dart
// At the top of the widget tree
SignalProvider(overrides: [
  counterProvider.overrideWith((ref) => createSignal(0)),
], child: MyApp());

// Access in any descendant
final counter = counterProvider.of(context);
```

**Alternative — module-level signals:** For this app, we will likely use
module-level (top-level) signals in service classes, as the bottle connection
and sensor state are global application state, not widget-scoped.

### 2.4 Async Support

#### `AsyncState<T>`

The standard async value wrapper used by `FutureSignal`:

```dart
// States: AsyncIdle, AsyncLoading, AsyncData(value), AsyncError(error, stackTrace)
```

```dart
final future = futureSignal(() async { ... });

// Pattern matching in Watch
Watch((context) {
  return switch (future.value) {
    AsyncError(:final error) => Text('Error: $error'),
    AsyncLoading() => const CircularProgressIndicator(),
    AsyncData(:final value) => Text('Data: $value'),
    _ => const SizedBox(), // AsyncIdle
  };
});
```

#### `futureSignal(fn)`

```dart
final s = futureSignal(() async => fetchData());

s.value    // AsyncState<T>
s.refresh();  // set isLoading=true, maintain current value
s.reload();   // discard current value, go to AsyncLoading
s.reset();    // go back to AsyncIdle
```

Auto-tracking dependencies: if the factory function reads signals, it will re-fetch
when those signals change. Use `dependencies: [signalA, signalB]` for signals read
across async gaps.

### 2.5 Collection Signals

For list/map/set state with efficient mutation:

```dart
final list = listSignal([1, 2, 3]);
list.add(4);
list.removeAt(0);

final map = mapSignal({'key': 'value'});
final set = setSignal({1, 2, 3});
```

Useful for lists of log entries, scanned devices, etc.

### 2.6 `StreamSignal` / `StreamSignalMixin`

For bridging Dart `Stream` into the signals reactive system:

```dart
final streamSignal = StreamSignal(stream);
// or via extension:
final signal = stream.toSignal();
```

This is directly relevant — BLE streams (scan results, connection state, notifications)
can be bridged into signals for reactive UI binding.

### 2.7 Persisted Signals

For signals that survive app restarts (via shared_preferences or similar):

```dart
final theme = signal('dark', autoDispose: false);
// Use with SignalPersist for disk persistence
```

Relevant for persisting known bottle names, last sync timestamps, etc.

---

## 3. How They Work Together — Architecture Patterns

### 3.1 Scan-to-Connection Flow

```
FlutterBluePlus.onScanResults ──Stream──▶ scannedDevices (ListSignal<ScanResult>)
                                                   │
                                          Watch(ScanResultListTile)
                                                   │ tap
                                                   ▼
                                    BottleService.connect(device)
                                                   │
                     device.connectionState ──StreamSignal──▶ connectionSignal
                                                   │
                                          Watch(buildConnectedUI)
```

### 3.2 BLE Request/Response to Reactive State

```
BottleService
  │
  ├─ write(requestBytes) to TX characteristic
  │
  └─ rxChar.onValueReceived.listen((responseBytes) {
       final response = decodeResponse(responseBytes);
       // Update signals
       batch(() {
         uiState.value = response.state;        // sensor value
         batteryLevel.value = response.battery; // sensor value
         lastError.value = null;
       });
     })
```

### 3.3 UI Binding Pattern

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fine-grained: only the value text rebuilds
        Watch((_) => Text('Battery: ${batteryService.level}%')),
        Watch((_) => Text('Water: ${tofService.distanceMm}mm')),

        // Entire card rebuilds when any signal in computed changes
        Watch((_) => WaterIntakeCard(
          volume: waterService.volumeToday.value,
          goal:    waterService.dailyGoal.value,
        )),
      ],
    );
  }
}
```

### 3.4 Service Layer Pattern

We'll follow a service-oriented architecture with signals as the state layer:

```
lib/
  services/
    bottle_service.dart      # BLE connection, request/response orchestration
    sensor_service.dart      # Live sensor reads, polling
    log_service.dart         # Log retrieval, paging, incremental sync
    battery_service.dart     # Battery GATT reads

  state/
    bottle_state.dart        # signals for each sensor value, connection state
    log_state.dart           # signals for log entries, sync progress

  ui/
    dashboard/
    sensors/
    logs/
```

Each service class owns the signals for its domain and exposes them as getters.
Services are instantiated once (singleton or top-level) and signals are module-level
for simple access from any widget without Provider/InheritedWidget ceremony.

Example:

```dart
// state/bottle_state.dart
import 'package:signals/signals.dart';
import 'package:signals/signals_flutter.dart';

final connectionState = signal<BottleConnectionState>(BottleConnectionState.disconnected);
final uiState = signal<CapUiState>(CapUiState.off);
final tofDistanceMm = signal<int>(0);
final batteryPercent = signal<int>(0);
final isScanning = signal<bool>(false);
final foundDevices = listSignal<ScanResult>([]);
```

### 3.5 Log Syncing Pattern

```dart
// Incremental sync with reactive progress
final syncProgress = signal<double>(0);  // 0.0 to 1.0
final logEntries = listSignal<CapTofLogEntry>([]);
final isSyncing = signal<bool>(false);

Future<void> syncLogs() async {
  isSyncing.value = true;
  int cursor = 0;
  while (true) {
    final response = await requestLogPage(cursor);
    if (response.entries.isEmpty) break;
    batch(() {
      logEntries.addAll(response.entries);
      cursor = max(response.entries.map((e) => e.timestamp)) + 1;
      syncProgress.value = min(logEntries.length / estimatedTotal, 1.0);
    });
  }
  isSyncing.value = false;
}
```

### 3.6 Error Handling

```dart
// Connection errors propagate through signals
final connectionError = signal<String?>(null);
final requestError = signal<String?>(null);

// In service:
try {
  await device.connect();
  connectionState.value = BottleConnectionState.connected;
} catch (e) {
  connectionError.value = e.toString();
  connectionState.value = BottleConnectionState.error;
}

// In UI:
Watch((_) {
  final error = connectionError.value;
  if (error != null) return ErrorBanner(message: error);
  return const SizedBox.shrink();
});
```

### 3.7 Android Permissions Setup (from FlutterBluePlus docs)

In `android/app/src/main/AndroidManifest.xml`:

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

In `android/app/build.gradle.kts`: `minSdkVersion = 21`

### 3.8 iOS Permissions Setup

In `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to communicate with your LARQ bottle.</string>
```

For background operation:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

---

## 4. Summary of Key APIs We'll Use

### FlutterBluePlus

| API | Purpose |
|-----|---------|
| `FlutterBluePlus.adapterState` | Monitor Bluetooth on/off |
| `FlutterBluePlus.startScan(withServices:[NUS_UUID])` | Find nearby bottles |
| `FlutterBluePlus.onScanResults` | Get scan results |
| `device.connect(autoConnect: true)` | Connect to bottle |
| `device.connectionState` | Track connection lifecycle |
| `device.discoverServices()` | Discover NUS, Device Info, Battery services |
| `txCharacteristic.write(bytes)` | Send protobuf commands to bottle |
| `rxCharacteristic.setNotifyValue(true)` | Subscribe to bottle responses |
| `rxCharacteristic.onValueReceived` | Receive protobuf responses |
| `batteryCharacteristic.read()` | Read battery level |
| `deviceInfoCharacteristic.read()` | Read device info |

### signals

| API | Purpose |
|-----|---------|
| `signal(initial)` | Mutable reactive state (connection status, sensor values) |
| `computed(fn)` | Derived reactive state (water intake, battery status text) |
| `effect(fn)` | Side effects (logging, analytics, persistence) |
| `batch(fn)` | Atomic multi-signal updates |
| `Watch(fn)` | Widget that rebuilds when signals change |
| `Watch.builder(builder:)` | Drop-in for `Builder` with signal tracking |
| `SignalsMixin` | Auto-dispose signals with widget lifecycle |
| `futureSignal(fn)` | Async operations as reactive state |
| `listSignal(items)` | Reactive list of devices, log entries |
| `AsyncState` | Pattern-match loading/error/data states |
| `signal.select(fn)` | Partial subscription to signal fields |
| `stream.toSignal()` | Bridge BLE streams into signals |

---

## 5. Next Steps — Architecture Guidelines

Based on this research, the architecture for Phase 1 (read-only operations) should follow
these guidelines:

1. **Service classes** encapsulate BLE logic. State is exposed as module-level signals.
2. **Signals + Watch** provide fine-grained UI updates — only the specific widget that
   displays a changing value rebuilds.
3. **Protobuf encoding/decoding** lives in a separate codec layer, producing typed
   Dart objects that feed into signals.
4. **Request/response correlation** uses a `Completer`-based mechanism keyed by
   `requestId`, not a raw stream listener per widget.
5. **Connection state** is modeled as a signal of an enum/sealed class:
   `disconnected → scanning → connecting → connected → disconnecting`.
6. **Log syncing** uses incremental forward paging (per RESEARCH.md findings) with
   a progress signal for UI feedback.
