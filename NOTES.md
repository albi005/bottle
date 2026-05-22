# LARQ PureVis 2 Protocol Notes

Reverse-engineered from LARQ Android app v1.6.1 (build 71), package `com.larq.live`.

## BLE Communication

### Service & Characteristics

The bottle uses the **Nordic UART Service (NUS)** pattern:

| UUID | Role | Direction |
|------|------|-----------|
| `0000FE59-0000-1000-8000-00805F9B34FB` | UART Service | - |
| `6e400001-b5a3-f393-e0a9-e50e24dcca9e` | TX Characteristic | Device → Phone (Notify) |
| `6e400002-b5a3-f393-e0a9-e50e24dcca9e` | RX Characteristic | Phone → Device (Write) |
| `6e400003-b5a3-f393-e0a9-e50e24dcca9e` | Flow Control | Optional |

### Standard BLE Services

- **Battery Service** (`0x180F`): Battery Level (`0x2A19`)
- **Device Information Service** (`0x180A`):
  - Model Number (`0x2A24`)
  - Serial Number (`0x2A25`)
  - Firmware Revision (`0x2A26`)
  - Hardware Revision (`0x2A27`)
  - Software Revision (`0x2A28`)

### DFU Service

- Service UUID: `0000FE59-0000-1000-8000-00805F9B34FB`
- DFU Control Point: `8EC90003-F315-4F60-9FB8-838830DAEA50`

## Protocol Encoding

All bottle communication uses **Protocol Buffers** (protobuf) over the UART service.

### Wrapper Messages

```protobuf
message CapBleRequest {
  int32 requestId = 1;
  google.protobuf.Any body = 2;
}

message CapBleResponse {
  int32 requestId = 1;
  CapEnumResponseCode code = 2;
  google.protobuf.Any body = 3;
}
```

The `body` field wraps a typed request/response message using `google.protobuf.Any` (with `type_url` like `type.googleapis.com/cap_ble.RequestGetCapTofLog`).

### Communication Pattern

1. Encode a request (e.g., `RequestGetCapTofLog`) as protobuf
2. Wrap in `google.protobuf.Any` with appropriate `type_url`
3. Wrap in `CapBleRequest` with a unique `requestId`
4. Write to RX characteristic (`6e400002`)
5. Read response from TX characteristic (`6e400001`) - device notifies
6. Parse `CapBleResponse`, extract response message from `Any`

### Response Codes

| Code | Value | Meaning |
|------|-------|---------|
| `RESPONSE_CODE_FAIL` | 0 | Request failed |
| `RESPONSE_CODE_SUCCESS` | 1 | Request succeeded |
| `RESPONSE_CODE_NOT_SUPPORTED` | 2 | Request type not supported |

## Message Types

### GET Requests (read device state)

All GET requests are **empty messages** (no fields) - they just query the device:

- `RequestGetCapBottleSensorState` - Bottle presence sensor
- `RequestGetCapUvConfig` - UV purification config
- `RequestGetCapTofLog` - Time-of-flight event log
- `RequestGetCapTofSettings` - ToF sensor settings
- `RequestGetCapTofState` - Current ToF sensor state
- `RequestGetCapTimeSettings` - Device clock settings
- `RequestGetCapLowBatterySettings` - Low battery behavior settings
- `RequestGetCapHydroReminderSettings` - Hydration reminder settings
- `RequestGetCapDoNotDisturbSettings` - DND mode settings
- `RequestGetCapAdcProtectionSettings` - ADC protection settings
- `RequestGetCapCalibrationSettings` - Capacitive calibration settings
- `RequestGetCapStateThresholdSettings` - State detection thresholds
- `RequestGetCapAccelerometerState` - Accelerometer readings (x, y, z)
- `RequestGetCapAmbientLightSensorState` - Ambient light sensor
- `RequestGetCapHallEffectSensorState` - Hall effect (lid magnet) sensor
- `RequestGetCapSipSensorState` - SIP (drinking) sensor
- `RequestGetCapFaultLog` - Fault event log
- `RequestGetCapStateLog` - State change log
- `RequestGetCapActivationLog` - UV activation event log
- `RequestGetActivationCapAdcLog` - ADC readings during activation
- `RequestGetChargingCapAdcLog` - ADC readings during charging
- `RequestGetCapUiState` - UI/bottle state

### Response Types

#### `ResponseGetCapTofLog`
```protobuf
message ResponseGetCapTofLog {
  repeated CapTofLog items = 1;
}
```

#### `CapTofLog`
```protobuf
message CapTofLog {
  int64 timestamp = 1;
  CapEnumTofTriggerType triggerType = 2;
  int32 distanceInMillimeter = 3;
  int32 kcps = 4;
  float uvLedTempInOhm = 5;
}
```

#### `ResponseGetCapTofState`
```protobuf
message ResponseGetCapTofState {
  CapTofState state = 1;
}
message CapTofState {
  int32 distanceInMillimeter = 1;
  int32 kcps = 2;
}
```

#### `ResponseGetCapBottleSensorState` / `ResponseGetCapSipSensorState`
```protobuf
message CapBottleSensorState {
  int32 value = 1;
  bool state = 2;
}
```

#### `ResponseGetCapAccelerometerState`
```protobuf
message CapAccelerometerState {
  float x = 1;
  float y = 2;
  float z = 3;
}
```

#### `ResponseGetCapUiState`
```protobuf
message ResponseGetCapUiState {
  CapEnumUiState state = 1;
  CapPowerSavingMode powerSavingMode = 2;
}
```

#### `ResponseGetCapActivationLog`
```protobuf
message ResponseGetCapActivationLog {
  repeated CapActivationLog items = 1;
}
message CapActivationLog {
  int64 timestamp = 1;
  CapEnumUvActivationMode mode = 2;
  int32 batterySocInPercentage = 3;
}
```

#### `ResponseGetCapFaultLog`
```protobuf
message ResponseGetCapFaultLog {
  repeated CapFaultLog items = 1;
}
message CapFaultLog {
  int64 timestamp = 1;
  CapEnumFaultType type = 2;
}
```

### SET Requests (write device state)

- `RequestSetCapBottleSensorState` - Set bottle detection state
- `RequestSetCapUvConfig` - Set UV configuration
- `RequestSetCapUvActivate` - Start/stop UV purification
- `RequestSetCapTofSettings` - Set ToF settings
- `RequestSetCapTimeSettings` - Sync time
- `RequestSetCapLowBatterySettings` - Set low battery settings
- `RequestSetCapHydroReminderSettings` - Set hydration reminders
- `RequestSetCapDoNotDisturbSettings` - Set DND
- `RequestSetCapAdcProtectionSettings` - Set ADC protection
- `RequestSetCapCalibrationSettings` - Set calibration
- `RequestSetCapStateThresholdSettings` - Set thresholds
- `RequestSetCapPowerSavingMode` - Set power saving mode

### Commands

- `RequestCapEnterDfuMode` - Enter DFU bootloader
- `RequestCapEnterLowBatteryMode` - Enter low battery mode
- `RequestCapFactoryReset` - Factory reset
- `RequestCapStartCapCalibration` - Start capacitive calibration
- `RequestCapStopCapCalibration` - Stop capacitive calibration

## Enum Values

### CapEnumUvActivationMode
| Value | Name |
|-------|------|
| 0 | `UV_ACTIVATION_MAINTENANCE` |
| 1 | `UV_ACTIVATION_STANDARD` |
| 2 | `UV_ACTIVATION_ADVENTURE` |
| 3 | `UV_ACTIVATION_STOP` |

### CapEnumUiState
| Value | Name |
|-------|------|
| 0 | `UI_STATE_ON` |
| 1 | `UI_STATE_FAULT` |
| 2 | `UI_STATE_UV_MAINTENANCE` |
| 3 | `UI_STATE_UV_NORMAL` |
| 4 | `UI_STATE_UV_ADVENTURE` |
| 5 | `UI_STATE_PAIRED` |
| 6 | `UI_STATE_HYDRATION_REMINDER` |
| 7 | `UI_STATE_BATTERY_LOW` |
| 8 | `UI_STATE_CHARGING` |
| 9 | `UI_STATE_CHARGED` |
| 10 | `UI_STATE_UV_INTERLOCK` |
| 11 | `UI_STATE_BOTTLE_CALIBRATION` |
| 12 | `UI_STATE_TOF_MEASUREMENT` |
| 13 | `UI_STATE_TURN_OFF` |
| 14 | `UI_STATE_FACTORY_RESET` |
| 15 | `UI_STATE_ALL_OFF` |
| 16 | `UI_STATE_LOCKED` |
| 17 | `UI_STATE_QC` |
| 18 | `UI_STATE_LAST` |

### CapEnumTofTriggerType
| Value | Name | Description |
|-------|------|-------------|
| 0 | `TYPE_REQUEST` | Manual request |
| 1 | `TYPE_INTERVAL` | Periodic sampling |
| 2 | `TYPE_CAP` | Cap removed event |
| 3 | `TYPE_CAP_ON_FLAP` | Cap on flap event |
| 4 | `TYPE_CAP_ON_FLAP_OPEN_SIP` | **Drink sip detected** |

### CapEnumFaultType
| Value | Name |
|-------|------|
| 0 | `TYPE_UV_OVERTEMP` |
| 1 | `TYPE_UV_LED_SHORT` |
| 2 | `TYPE_UV_LED_OPEN` |
| 3 | `TYPE_BATTERY_TEMP` |
| 4 | `TYPE_BATTERY_OPEN` |
| 5 | `TYPE_BATTERY_SHORT` |
| 6 | `TYPE_AMBIENT_LIGHT` |

### CapEnumHydroReminderState
| Value | Name |
|-------|------|
| 0 | `REMINDER_STATE_OFF` |
| 1 | `REMINDER_STATE_INTERVAL_FIXED` |
| 2 | `REMINDER_STATE_INTERVAL_ADAPTIVE` |

## Hydration Tracking

The bottle uses a **Time-of-Flight (ToF)** sensor to detect drinking events:

1. The ToF sensor measures distance to the water surface
2. Trigger types indicate how the measurement was initiated
3. `TYPE_CAP_ON_FLAP_OPEN_SIP` (4) explicitly marks a detected sip
4. `TYPE_CAP` and `TYPE_CAP_ON_FLAP` with short distances also indicate drinking

For Health Connect sync, we estimate ~30ml per sip event.

## Connection Details

- BLE connection: `autoConnect=false`, transport `LE_1M | LE_2M`
- Scan filter: advertise with UART service UUID `0000FE59`
- MTU negotiation supported
- Write type: `WRITE_TYPE_DEFAULT` (with response) for protocol requests

## ELP (Event Log Processing)

The original app uses a complex Event Log Processing (ELP) v3 system to efficiently pull event logs from the bottle. The demo app uses direct polling instead.

## App Architecture

The original app uses:
- **Kotlin** with **Jetpack Compose** + **Material 3**
- **Firebase** backend
- **Hilt/Dagger** DI
- **Realm** local database
- **Ktor** HTTP client
- **Braze** push notifications

API base URL: `https://api.livelarq.com/api/v2/`

---

# Flutter App Development Notes

## Goal

Build a Flutter Linux app that communicates with a LARQ PureVis 2 bottle over BLE and syncs hydration data to Health Connect.

## Environment

- **OS:** NixOS (Linux), no Android SDK
- **Flutter target:** `flutter run -d linux`
- **BLE backend:** `flutter_blue_plus` on Linux (BlueZ/D-Bus `bluetoothd`)
- **Bottle tested:** `LARQ_0jMdSZS8blV`, MAC `4F:56:90:5B:A8:F7`, firmware `00000101`, battery 86%
- **Reference implementation:** Python client at `~/larq_client.py` using `bleak` + compiled protobuf at `/tmp/opencode/larq_proto_py/`
- **Reverse-engineered from:** APK at `./tmp/com.larq.live.zip` (v1.6.1 build 71)

## BLE UUID Corrections

The initial UUID assignments were wrong. Fixed after comparing against the working Python client:

| Service / Characteristic | UUID | Role |
|--------------------------|------|------|
| NUS Service | `6e400001-b5a3-f393-e0a9-e50e24dcca9e` | Nordic UART Service |
| TX (Notify, bottle→phone) | `6e400003-b5a3-f393-e0a9-e50e24dcca9e` | Notifications |
| RX (Write, phone→bottle) | `6e400002-b5a3-f393-e0a9-e50e24dcca9e` | Write without response |

Key insight: TX characteristic (phone writes to, bottle reads from) is `6e400002`, **not** `6e400003`. The labeled "TX" in NUS is the device's TX, which is the phone's RX. The scanning service UUID is `0000FE59` but the bottle does **not** advertise it — it only advertises Device Info Service (`0x180A`), so scan filters must be removed.

## Protobuf Codec (Manual Implementation)

Rather than depending on `protoc` for Dart codegen, built a manual protobuf wire-format codec based on `cap_ble.proto` v1.12 (at `/tmp/opencode/larq_apk/protos/cap_ble.proto`). Critical gotchas found and fixed:

1. **`requestId` encoding:** Proto field 1 in `CapBleRequest` is `fixed32`, not `int32`. Wire type is `5` (4 bytes LE), not `0` (varint). Was initially encoding as varint, producing wrong bytes.

2. **`sint32` fields:** Proto uses zigzag encoding for negative numbers. Fields like `kcps` (`CapTofState.kcps`) were being read as plain varint, producing wrong values. Must use zigzag decode.

3. **Type URLs never included `cap_ble.` package prefix:** The `.proto` file has no `package` declaration, so type URLs use the bare root namespace, e.g. `type.googleapis.com/ResponseGetCapTofLog` (NOT `cap_ble.ResponseGetCapTofLog`).

4. **`CapPowerSavingMode` enum:** ON=0, OFF=1 (was initially reversed).

5. **Log requests require embedded `CapLogQuery`:** `getTofLog`, `getActivationLog`, and `getFaultLog` need a `CapLogQuery` payload inside the `Any` body, not an empty message. Without it, the bottle responds with `RESPONSE_CODE_NOT_SUPPORTED` (2).

All 10 GET request types now return `RESPONSE_CODE_SUCCESS` (1) from the bottle.

## Request Types Implemented

| # | Request Type | Response | Status |
|---|-------------|----------|--------|
| 1 | `getCapTofLog` | ToF event log entries | ✅ Working |
| 2 | `getCapTofState` | Distance, kcps | ✅ Working |
| 3 | `getCapBottleSensorState` | Presence, value | ✅ Working |
| 4 | `getCapUiState` | UI state, power mode | ✅ Working |
| 5 | `getCapSipSensorState` | Sip detection state | ✅ Working |
| 6 | `getCapAccelerometerState` | X, Y, Z acceleration | ✅ Working |
| 7 | `getCapAmbientLightSensorState` | Light level | ✅ Working |
| 8 | `getCapHallEffectSensorState` | Lid magnet detection | ✅ Working |
| 9 | `getCapActivationLog` | UV activation history | ✅ Working |
| 10 | `getCapFaultLog` | Fault event history | ✅ Working |

## App Architecture

```
app/
├── lib/
│   ├── main.dart                          # App entry, singleton LarqBleService
│   ├── models/
│   │   └── larq_protocol.dart             # BLE UUIDs, enums, request type URLs
│   ├── services/
│   │   ├── protobuf_codec.dart            # Manual protobuf wire-format enc/dec
│   │   ├── larq_ble_service.dart          # BLE scan, connect, UART RX/TX, request dispatch
│   │   └── health_connect_service.dart    # Health Connect auth + volume estimation
│   └── screens/
│       ├── scan_screen.dart               # BLE device scan UI
│       ├── device_screen.dart             # Device info, sensor data, refresh, disconnect
│       └── hydration_screen.dart          # ToF/activation/fault log viewer + Health Connect sync
└── pubspec.yaml
```

## Key Decisions & Troubleshooting

### Singleton Service (critical fix)
`main.dart` was creating `LarqBleService()` inside `build()`:
```dart
home: ScanScreen(bleService: LarqBleService()),  // BAD: new instance every rebuild
```
Every Flutter rebuild created a new service instance, causing conflicts with `FlutterBluePlus` singleton. Fixed by hoisting:
```dart
final bleService = LarqBleService();
// ...
home: ScanScreen(bleService: bleService),
```

### Infinite Refresh Loop (fixed)
`IconButton.onPressed: _fetchData` was re-triggered by `setState(() => _loading = false)` because the button was rebuilt. Fixed with a version counter:
```dart
int _fetchVersion = 0;

Future<void> _fetchData() async {
  final version = ++_fetchVersion;
  // ... fetch ...
  await Future.delayed(const Duration(milliseconds: 300));
  if (_fetchVersion != version || !mounted) return;
  setState(() => _loading = false);
}
```
This cancels any stale debounce timer when a new fetch starts or disconnect occurs.

### Disconnect Freeze (in progress)
- App freezes during back navigation after disconnect
- BLE disconnect (`_device?.disconnect()`) completes cleanly
- Likely cause: stale `setState` from cooldown timer firing during pop transition
- Fixed by: `_fetchVersion++` in `_disconnect()` to cancel pending cooldown → still testing

### Write characteristic `withoutResponse: true`
Matches Python's `bleak` `response=False`. The bottle doesn't send a GATT write response.
Default Flutter Blue+ uses `WRITE_TYPE_DEFAULT` (with response), which caused timeouts.

### No `requestMtu(256)`
Causes "operation not supported" on Linux BlueZ. BLE negotiation handles this automatically.
Default MTU (23 bytes) is sufficient since all requests fit in a single packet.

### No Scan Filters
Bottle advertises only Device Info Service (`0x180A`) and sometimes Complete Local Name.
UART service UUID (`0xFE59` / `6e400001`) is NOT in the advertisement data.
Filters on those UUIDs return zero results. Scan for all devices and sort by RSSI.

### `autoConnect: false` removed (default `true`)
On Linux BlueZ, `autoConnect: false` is unreliable (device doesn't connect or drops immediately).

### Health Connect Graceful Degradation
Health Connect package only works on Android. Catches `MissingPluginException` on Linux and shows "Not available on this platform" instead of crashing.

### Bottle Sleep Behavior
The bottle disconnects on its own after ~30-60 seconds of inactivity (sleep mode).
UI must handle `Lost connection to device` gracefully. Disconnect does not crash — shows "Disconnected" status.

## What's NOT Yet Implemented

- UV purification start/stop (`RequestSetCapUvActivate`)
- SET requests (write device configuration)
- Settings screens (reminders, DND, power saving, thresholds)
- DFU firmware update
- ELP (Event Log Processing) — currently using direct polling instead
- Health Connect write on Android (needs Android SDK for testing)
- Protobuf test suite (verify decoded values against Python client output)

## Debug Build Command
```bash
cd app && flutter build linux --debug
```
Output: `build/linux/x64/debug/bundle/larq_bridge`
Run: `./build/linux/x64/debug/bundle/larq_bridge`
Dev: `flutter run -d linux`
