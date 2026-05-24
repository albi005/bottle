# LARQ PureVis 2 — Bottle BLE Protocol Research

> This document describes the bottle's BLE interface — its command set, protocol,
> data types, and behavior. Implementation details and the app refactor will be
> in a separate `plan.md`.

## BLE Architecture

The bottle exposes a **Nordic UART Service (NUS)** — two characteristics
forming a single bidirectional byte stream. All commands and all responses
are multiplexed over this one pair via protobuf-encoded messages.

| Direction | UUID | Properties |
|-----------|------|------------|
| Phone writes → Bottle receives | `6e400002-b5a3-f393-e0a9-e50e24dcca9e` | Write, Write Without Response |
| Bottle sends → Phone receives | `6e400003-b5a3-f393-e0a9-e50e24dcca9e` | Notify |

The bottle also exposes standard BLE services for device info and battery:

| Service | UUID | Characteristics |
|---------|------|----------------|
| Device Information | `0000180a` | Model, Serial, Firmware, Hardware, Software, Manufacturer (all Read) |
| Battery Service | `0000180f` | Battery Level `00002a19` (Read, Notify) |
| DFU Service | `0000fe59` | DFU Control `8ec90003-f315-4f60-9fb8-838830daea50` (Write, Indicate) |

### Request-Response Protocol

Every interaction follows a strict request→response pattern:

1. Phone encodes a `CapBleRequest` protobuf and writes it to `6e400002`
2. Bottle processes the command and sends a `CapBleResponse` protobuf notification on `6e400003`
3. Responses are correlated to requests via a monotonically incrementing `requestId` (field 1, fixed32)

The bottle does **not** send unsolicited data. Every notification is a response to a prior write.

### Envelope Format

```
CapBleRequest {
    fixed32 requestId = 1;     // caller-generated, echoed back in response
    Any body = 2;              // type_url = "type.googleapis.com/Request*"
                               // value   = serialized request proto
}

CapBleResponse {
    fixed32 requestId = 1;
    CapEnumResponseCode code = 2;   // 0=FAIL, 1=SUCCESS, 2=NOT_SUPPORTED
    Any body = 3;                   // type_url = "type.googleapis.com/Response*"
}
```

### MTU and Timing

- **MTU:** The bottle negotiates 247 bytes (observed). Each response carries at
  most 8 log entries.
- **Concurrent requests:** Tested by firing 5 `readTofLog` commands as fast as
  possible (all writes within ~10ms). The bottle **did NOT disconnect**. It
  responded to all 5 with the same page of data (since they used the same
  `fromTimestamp`), and one request hit the 10s timeout. The bottle remained
  connected and the poll loop resumed normally afterward.
- **No inherent rate limit** was observed. Sequential requests complete
  reliably at natural BLE round-trip speed (~200-500ms per request due to
  response latency, not due to any required inter-request delay). No
  artificial pacing is needed.

---

## Bottle Command Set (39 Commands)

The bottle uses string-based command identifiers transmitted via the
protobuf `Any.type_url` field (not the NUS characteristic directly).
All commands are listed in the decompiled `b2` enum (`xc/b2.java:128-202`).

### Actuation (2)

| Ordinal | String | Effect |
|---------|--------|--------|
| 0 | `activate` | Unknown (not used by LARQ app) |
| 2 | `factoryReset` | Factory reset the bottle |

### Live Sensor Reads (11 read-only — no SET for most)

| Ordinal | String | Returns |
|---------|--------|---------|
| 3 | `readUiState` | `CapEnumUiState` + `CapPowerSavingMode` |
| 4 | `readTime` | Bottle's internal clock |
| 19 | `readHallEffectSensorState` | `CapHallEffectSensorState` (lid open/closed) |
| 20 | `readSipSensorState` | `CapSipSensorState` (cumulative sip counter) |
| 21 | `readBottleSensorState` | `CapBottleSensorState` (bottle presence) |
| 22 | `readAmbientLightSensorState` | `CapAmbientLightSensorState` (lux) |
| 23 | `readAccelerometerState` | `CapAccelerometerState` (x, y, z in m/s²) |
| 24 | `readTofState` | `CapTofState` (current distance, signal strength) |

### Config Reads (7)

| Ordinal | String | Returns |
|---------|--------|---------|
| 7 | `readUvConfig` | `CapUvConfig` (mode, duration) |
| 9 | `readDoNotDisturbSettings` | DND configuration |
| 11 | `readStateThresholdSettings` | Sensor threshold config |
| 13 | `readAdcProtectionSettings` | ADC protection config |
| 15 | `readLowBatterySettings` | Low battery thresholds |
| 18 | `readHydroReminderSettings` | Hydration reminder config |
| 26 | `readTofSettings` | ToF sensor config |
| 28 | `readCalibrationSettings` | Calibration config |

### Config Writes (7)

| Ordinal | String | Sets |
|---------|--------|------|
| 1 | `setTime` | Bottle clock |
| 5 | `setPowerSavingMode` | Power saving (off/on/auto) |
| 6 | `setUvConfig` | UV purification mode + duration |
| 8 | `setDoNotDisturbSettings` | DND config |
| 10 | `setStateThresholdSettings` | Sensor thresholds |
| 12 | `setAdcProtectionSettings` | ADC protection |
| 14 | `setLowBatterySettings` | Low battery thresholds |
| 16 | `setHydroReminderSettings` | Hydration reminder |
| 17 | `setBottleSensorState` | Bottle sensor (write-only sensor? unusual) |
| 25 | `setTofSettings` | ToF sensor config |
| 27 | `setCalibrationSettings` | Calibration config |

### Calibration (2)

| Ordinal | String | Effect |
|---------|--------|------|
| 29 | `startCalibration` | Begin calibration sequence |
| 30 | `stopCalibration` | End calibration sequence |

### Mode Entry (2)

| Ordinal | String | Effect |
|---------|--------|------|
| 31 | `enterLowBatteryMode` | Enter low-power mode |
| 32 | `enterDfuMode` | Enter Device Firmware Update mode |

### Log Queries (6 — all use CapLogQuery as parameter)

| Ordinal | String | Returns |
|---------|--------|---------|
| 33 | `readTofLog` | `CapTofLog[]` — ToF sensor history |
| 34 | `readActivationAdcLog` | `CapAdcLog[]` — ADC during UV activation |
| 35 | `readChargingAdcLog` | `CapAdcLog[]` — ADC during charging |
| 36 | `readActivationLog` | `CapActivationLog[]` — UV activation events |
| 37 | `readFaultLog` | `CapFaultLog[]` — fault events |
| 38 | `readStateLog` | `CapStateLog[]` — sensor state change log |

---

## CapLogQuery — Log Retrieval System

All 6 log types use the same query/response mechanism:

### Query Parameters

```protobuf
message CapLogQuery {
    int64 fromTimestamp = 1;           // cursor: return entries with ts >= this
    int32 limit = 2;                   // max entries per page (bottle caps at 8)
    CapEnumLogQuerySearchAlgo algo = 3; // 0=TIMESTAMP, 1=INCREMENT
}

enum CapEnumLogQuerySearchAlgo {
    SEARCH_ALGO_TIMESTAMP = 0;
    SEARCH_ALGO_INCREMENT = 1;
}
```

### Paging

The bottle always returns entries **ascending** from the cursor:

| `fromTimestamp` | Result |
|-----------------|--------|
| `0` | Oldest entries first; includes an epoch-0 dummy entry (`ts≈23`, trigger=Request, distance=0mm) |
| `max(seenTimestamps) + 1` | Next page (forward) |
| Very large (future) | After forward-paging has warmed the connection, **sometimes** returns newest entries descending. On a fresh connection, returns empty. **Unreliable — prefer forward-paging only.** |

Each response contains at most 8 entries (limited by the 247-byte MTU), regardless
of the `limit` value requested.

### Algo Field

- `SEARCH_ALGO_TIMESTAMP` (0): Default. Standard forward paging.
- `SEARCH_ALGO_INCREMENT` (1): Used by the LARQ app only when special
  conditions are met (`incrementEnabled=true`, `isFirstRequest=false`, and a
  runtime flag). On the PureVis 2 firmware, `algo=1` caused a disconnect in a
  live test. **Do not use.**

### Command → Request Wrapper Mapping

Each log type is wrapped in its own request message:

| Command | Request Wrapper |
|---------|----------------|
| `readTofLog` | `RequestGetCapTofLog { CapLogQuery query = 1; }` |
| `readStateLog` | `RequestGetCapStateLog { CapLogQuery query = 1; }` |
| `readActivationLog` | `RequestGetCapActivationLog { CapLogQuery query = 1; }` |
| `readFaultLog` | `RequestGetCapFaultLog { CapLogQuery query = 1; }` |
| `readActivationAdcLog` | `RequestGetActivationCapAdcLog { CapLogQuery query = 1; }` |
| `readChargingAdcLog` | `RequestGetChargingCapAdcLog { CapLogQuery query = 1; }` |

All response wrappers follow the pattern `ResponseGet*Log { repeated Entry entries = 1; }`.

---

## Data Types — Sensor States

### CapUiState + CapPowerSavingMode

```
readUiState → ResponseGetCapUiState { CapEnumUiState state=1; CapPowerSavingMode powerSavingMode=2; }
```

`CapEnumUiState` is an enum with 19 values:
`on(0)`, `fault(1)`, `uvMaintenance(2)`, `uvNormal(3)`, `uvAdventure(4)`,
`paired(5)`, `hydrationReminder(6)`, `batteryLow(7)`, `charging(8)`,
`charged(9)`, `uvInterlock(10)`, `bottleCalibration(11)`, `tofMeasurement(12)`,
`turnOff(13)`, `factoryReset(14)`, `allOff(15)`, `locked(16)`, `qc(17)`,
`last(18)`.

`CapPowerSavingMode`: `off(0)`, `on(1)`, `auto(2)`.

### CapSipSensorState

```protobuf
message CapSipSensorState {
    int32 value = 1;    // cumulative sip counter
    bool state = 2;     // true while sip is active (capacitive sensor detecting contact)
}
```

The `value` increments on each detected sip. It is a **cumulative counter** —
`Δvalue` between two reads gives the number of sips in that interval. The LARQ
app does not use this for drink counting; it sends it to cloud analytics only.

### CapTofState

```protobuf
message CapTofState {
    int32 distanceInMillimeter = 1;  // current distance from cap sensor to water surface
    int32 kcps = 2;                  // signal strength (kilo counts per second)
}
```

### CapBottleSensorState

```protobuf
message CapBottleSensorState {
    sint32 value = 1;    // raw sensor value
    bool state = 2;      // true = bottle present
}
```

### CapHallEffectSensorState

```protobuf
message CapHallEffectSensorState {
    int64 timestamp = 1;  // last change timestamp
    bool value = 2;       // true = lid open
}
```

### CapAccelerometerState

```protobuf
message CapAccelerometerState {
    float x = 1;
    float y = 2;
    float z = 3;
}
```

### CapAmbientLightSensorState

```protobuf
message CapAmbientLightSensorState {
    float value = 1;  // lux
}
```

---

## Data Types — Log Entries

### CapTofLog

The primary data type for water intake tracking. Each entry records a Time-of-Flight
distance measurement.

```protobuf
message CapTofLog {
    int64 timestamp = 1;                  // epoch seconds
    CapEnumTofTriggerType triggerType = 2;
    int32 distanceInMillimeter = 3;       // distance from cap to water surface
    int32 kcps = 4;                       // signal strength
    float uvLedTempInOhm = 5;            // UV LED temperature
}
```

#### CapEnumTofTriggerType

What caused this measurement:

| Value | Name | Human-readable |
|-------|------|---------------|
| 0 | `TYPE_REQUEST` | `"request"` |
| 1 | `TYPE_INTERVAL` | `"interval"` |
| 2 | `TYPE_CAP` | `"cap"` |
| 3 | `TYPE_CAP_ON_FLAP` | `"flap"` |
| 4 | `TYPE_CAP_ON_FLAP_OPEN_SIP` | `"sip"` |

- `request`: manually triggered measurement
- `interval`: periodic sampling
- `cap`: triggered when cap was removed
- `flap`: triggered when the drinking flap was opened
- `sip`: triggered when a sip was detected (flap open + capacitive sensor)

**Only `TYPE_CAP_ON_FLAP_OPEN_SIP` (value 4) corresponds to a drinking event.**

#### Epoch-0 Dummy Entry

Every log response includes a terminal dummy entry with `timestamp≈23`,
`triggerType=TYPE_REQUEST`, `distanceInMillimeter=0`. This is an artifact of
the bottle's log buffer structure, not a real measurement. Should be filtered
out by ignoring entries where `timestamp < 1000`.

### CapActivationLog

UV purification activation events:

```protobuf
message CapActivationLog {
    int64 timestamp = 1;
    CapEnumUvActivationMode mode = 2;   // maintenance(0), standard(1), adventure(2), stop(3)
    int32 batterySocInPercentage = 3;   // battery % at time of activation
}
```

### CapFaultLog

Error/fault events:

```protobuf
message CapFaultLog {
    int64 timestamp = 1;
    CapEnumFaultType type = 2;   // uvOvertemp(0), uvLedShort(1), uvLedOpen(2),
                                  // batteryTemp(3), batteryOpen(4), batteryShort(5),
                                  // ambientLight(6)
}
```

### CapAdcLog

Raw ADC (analog-to-digital) measurements during activation or charging:

```protobuf
message CapAdcLog {
    int64 timestamp = 1;
    float batteryInVolt = 2;
    float batteryTempInOhm = 3;
    float uvLedInVolt = 4;
    float uvLedCurrentInMilliamps = 5;
    float uvLedTempInOhm = 6;
    float cPcbTempInOhm = 7;
}
```

### CapStateLog

Periodic sensor state snapshot:

```protobuf
message CapStateLog {
    int64 timestamp = 1;
    bool hall = 2;                              // lid state
    bool bottleDetection = 3;                   // bottle presence
    bool ambientLight = 4;                      // ambient light
    bool sipDetection = 5;                      // sip detected this interval
    float bottleDetectionCapacitorValue = 6;    // raw cap value
    float ambientLightSensorValue = 7;          // raw ambient
    float sipDetectionCapacitorSensorValue = 8; // raw sip cap value
}
```

---

## ToF-to-Water-Intake Algorithm (How the LARQ App Counts Drinks)

The LARQ Android app counts water intake by analyzing `CapTofLog` distance data,
**not** by using `CapSipSensorState` or `CapStateLog.sipDetection`.

### Algorithm (Reconstructed from Field Names)

The core implementation in `N3/o.java` is obfuscated and could not be
decompiled, but the surrounding architecture reveals the approach:

1. **Maintain a volume state** per bottle (`mc/C4197a.java`):
   - `tofDist`: current water distance
   - `lastCalcVolumeInML`: last computed volume
   - `lastCountedVolumeInML`: last volume that counted as a drink
   - `volumeAddedInML`: recent volume added (fill detection)
   - `cumulativeCalcVolumeInML`: running total
   - `tofSkipped`: skipped readings counter

2. **Detect water level changes** from consecutive `CapTofLog` entries:
   - Distance **increases** (water level drops) → possible drink
   - Distance **decreases** (water level rises) → possible refill

3. **Apply thresholds** from `AlgorithmConfig.java`:
   - `drinkThresholdInMl` (double): minimum volume change to count as a drink
   - `fillThresholdInMl` (double): minimum volume change to detect a refill
   - `minVolumeLimitInMl` (double): minimum volume for any event

4. **Convert distance to volume** using the bottle's cylindrical geometry:
   - Inner diameter ≈ 70mm → cross-section ≈ π × (35²) = 3848 mm²
   - 1 mm of water column = 3.848 ml
   - Formula: `volume_ml = distance_delta_mm × 3.848`

5. **Track fill level** in a `VolumeStateDic` that persists across readings.

### Why Not CapSipSensorState?

The LARQ app uses `CapSipSensorState` only for cloud analytics
(`D9/C1133s.java:51`), not for local drink counting. The capacitive sip sensor
detects mouth contact but cannot measure volume. The ToF approach measures
actual water displacement, giving ml-accurate results.

### Liquid Intake Sources

The app classifies each intake with a source (`ic/EnumC3684h.java`):
- `BOTTLE` (0): detected from ToF data
- `MANUAL` (1): user-entered
- `UNKNOWN` (2): imported from other sources

---

## Log Buffer Size and Coverage

The bottle stores approximately 64 KB of log data. At ~23 bytes per `CapTofLog`
entry, this equates to roughly **1500 entries**. At 8 entries per page, a full
sync requires ~190 pages. At ~300ms per page (response latency), a full sync
takes about 1 minute.

Activation and fault logs are much smaller (~10-30 entries total).

---

## BlueZ / Linux Connection Quirks

These behaviors are specific to BlueZ on Linux. Android does not exhibit
them.

### Unclean Disconnect → RSSI-0 Ghost (Proven)

**Test procedure:**
1. Connect to bottle (`rssi=-55`)
2. `kill -9` the app process (no graceful disconnect)
3. Launch fresh app, observe scan results

**Observed:** The bottle appears immediately in scans with `rssi: 0`
and a different cached MAC. Connection attempts to this ghost address
fail silently. Scan cycles loop forever.

### Fix: `bluetoothctl remove` (Proven)

```sh
bluetoothctl remove <MAC>
```

BlueZ tears down the stale link and removes the cached device. A fresh
launch then connects immediately with a real RSSI.

### Fallback: `bluetoothctl power off / on`

If `bluetoothctl remove` doesn't resolve the issue, toggling the
adapter clears all BlueZ state:

```sh
bluetoothctl power off && sleep 2 && bluetoothctl power on
```

Takes ~3-5 seconds. Restores a completely clean state.

### MAC Rotation

The same bottle (`LARQ_0jMdSZS8blV`) has connected and responded under
these MACs:

```
40:0C:FD:32:FD:CE    4B:F0:8D:D7:58:E3    62:C7:E0:21:37:18
6B:9E:20:45:55:54
```

This is consistent with BLE Resolvable Private Address (RPA) rotation.
Bottles should be identified by advertised name (`LARQ_*`), not MAC.

---

## Summary: Bottle Capabilities

| Capability | Support |
|-----------|---------|
| Async push notifications | No — request-response only |
| Concurrent/pipelined requests | Yes (requestId routing), but no benefit |
| Log paging | Yes, CapLogQuery with fromTimestamp cursor |
| Incremental sync | Yes — query from known last timestamp |
| Epoch-0 dummy filtering | Required (timestamp < 1000 filter) |
| Descending/high-TS queries | Unreliable — use forward paging only |
| Sip detection | Hardware: capacitive sensor (CapSipSensorState) and ToF distance (CapTofLog) |
| Volume measurement | Distance-based via ToF, 3.85 ml/mm conversion |
| Bottle fill level tracking | App-side, from cumulative distance readings |
| UV purification | 3 modes + stop, configurable duration |
| Fault logging | 7 fault types, timestamped |
| Battery monitoring | BLE GATT Battery Service + activation log SOC |
| Power saving | Off/On/Auto modes |
| DFU mode | Enterable via command |
| Factory reset | Via command |
