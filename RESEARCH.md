# LARQ PureVis 2 — Bottle BLE Protocol Research

> This document describes the bottle's BLE interface — its command set, protocol,
> data types, and behavior.

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

- **MTU:** The bottle negotiates 247 bytes (observed).
  - **Critical:** On Android, `mtu: null` in `device.connect()` skips MTU
    negotiation entirely, leaving the connection at the default MTU of 23 bytes.
    Our protobuf requests (51–67 bytes for sensor queries, larger for log
    queries) get fragmented across multiple BLE packets. The bottle requires
    **complete protobuf messages in a single write** — fragmented writes are
    silently ignored, causing the bottle to never respond.
  - **Fix:** Set `mtu: 512` (or omit the `mtu` parameter, which defaults to 512
    on Android). FBP will negotiate down to the bottle's supported 247 bytes.
- **Concurrent requests:** Tested by firing 5 `readTofLog` commands as fast as
  possible (all writes within ~10ms). The bottle **did NOT disconnect**. It
  responded to all 5 with the same page of data (since they used the same
  `fromTimestamp`), and one request hit the 10s timeout. The bottle remained
  connected and the poll loop resumed normally afterward.
- **No inherent rate limit** was observed. Sequential requests complete
  reliably at natural BLE round-trip speed (~200-500ms per request due to
  response latency, not due to any required inter-request delay). No
  artificial pacing is needed.

### BLE Notification Boundary Truncation (Critical)

The bottle silently truncates protobuf responses at the BLE notification
boundary. The max ATT payload is `MTU - 3 = 244 bytes`. The bottle's
protobuf encoder serializes entries until the buffer is full, then sends
the truncated result. The truncated response has a valid `Any` length
prefix but the inner body contains incomplete entries — the last entry's
length prefix is present but its data is cut off mid-field.

This causes `InvalidProtocolBufferException: input ended unexpectedly in
the middle of a field` when decoding.

**Symptoms:**
- Log types with small entries (Activation: ~13 bytes, Fault: ~8 bytes)
  work fine — 8 entries easily fit in 244 bytes.
- Log types with larger entries (TOF: ~23 bytes, State: ~27-29 bytes,
  ADC: ~36 bytes) fail — the response overflows the boundary.

**Fix:** Per-type page limits sized to fit the outer envelope (~55 bytes)
plus all entries within 244 bytes:

| Log Type | Entry Size | Safe Limit | Response Size |
|---|---|---|---|
| TOF Log | 23 bytes | **7** | 55 + 7×23 = 216 |
| Activation Log | 13 bytes | 8 | 55 + 8×13 = 159 |
| Fault Log | 8 bytes | 8 | 55 + 8×8 = 119 |
| State Log | 27–29 bytes | **6** | 55 + 6×29 = 229 |
| Activation ADC | 36 bytes | **4** | 55 + 4×38 = 207 |
| Charging ADC | 36 bytes | **4** | 55 + 4×38 = 207 |

**Multi-packet reassembly:** Some responses still arrive as multiple BLE
notifications. A 200ms coalescing timer accumulates bytes before parsing.
Without this, the first packet's partial data completes the request
completer, and subsequent packets are silently discarded.

### TX Write Type

The NUS TX characteristic (`6e400002`) supports only **Write Without
Response** (not Write With Response). The write call must use
`withoutResponse: true`. Using `withoutResponse: false` attempts a GATT
Write Request on a characteristic that only advertises Write Without
Response. Responses come as **notifications** on the RX characteristic
(`6e400003`), not as GATT write acknowledgments.

### requestId Field

`CapBleRequest.requestId` is `fixed32` at field number 1. The first
request must use `requestId = 1` (or higher), **not 0**. Protobuf 3
omits default-value fields during serialization — `requestId = 0` is
skipped entirely, producing a request without the field, which the bottle
cannot correlate with a response. Use pre-increment (`++_counter`).

### RX Subscription Order

Subscribe to `onValueReceived` on the RX characteristic (`6e400003`)
**before** calling `setNotifyValue(true)`. If `setNotifyValue` completes
before the listener is attached, the first notification from the bottle
may arrive during the gap and be lost.

---

## Proto Format Details

The bottle's `.proto` file has **no package declaration**. Type URLs in
`Any` bodies use the bare message name:
`type.googleapis.com/RequestGetCapUiState` (no `package.` prefix).

Our `cap.proto` file uses `package bottle;` for Dart code generation
purposes, but the type URLs sent to the bottle must NOT include the
`bottle.` prefix — the bottle does not recognize prefixed names.

### Bottle's Actual Field Types

The bottle's firmware proto descriptor (extracted from
`sources/defpackage/CapBle.java:48666`) specifies different field types
than what a naive `.proto` file would suggest. Several `int32` fields
are actually `fixed32` on the wire. See the "Proto Wire-Type
Mismatches" section above for the complete mapping and fix.

### Response Wrapper Field Names

All sensor response wrappers embed the state in a **`state` submessage**
at field 1 (not flat fields):

```protobuf
// Correct (matching the bottle's wire format):
message ResponseGetCapTofState { CapTofState state = 1; }
message ResponseGetCapSipSensorState { CapSipSensorState state = 1; }
message ResponseGetCapBottleSensorState { CapBottleSensorState state = 1; }
message ResponseGetCapHallEffectSensorState { CapHallEffectSensorState state = 1; }
message ResponseGetCapAmbientLightSensorState { CapAmbientLightSensorState state = 1; }
message ResponseGetCapAccelerometerState { CapAccelerometerState state = 1; }
```

`ResponseGetCapUiState` is an exception — it has flat `state` (enum) +
`powerSavingMode` (enum) at fields 1 and 2, not a submessage.

All log response wrappers use the repeated field name **`items`** at
position 1 (not `entries`):

```protobuf
message ResponseGetCapTofLog { repeated CapTofLog items = 1; }
// … same for all ResponseGet*Log messages
```

### Proto Wire-Type Mismatches (protoc-gen-dart)

The Dart protobuf library (`package:protobuf`) is **strict about wire
types**. If a field is registered as `OPTIONAL_INT32` (expects varint,
wire type 0) but the bottle sends `fixed32` (wire type 5) or `sint32`
(wire type 0 with zigzag), the field is silently skipped and defaults to
0. The `protoc-gen-dart` code generator also silently drops `fixed32`,
`uint64`, and `sint32` annotations — it generates `int32`/`int64` fields
regardless.

**The bottle uses these actual wire types** (parsed from the firmware's
embedded proto descriptor):

| Message | Field | Proto says | Bottle sends | Fix |
|---|---|---|---|---|
| `CapTofLog` | `distanceInMillimeter` (3) | `int32` | **fixed32** | `PbFieldType.OF3` |
| `CapTofLog` | `kcps` (4) | `int32` | **fixed32** | `PbFieldType.OF3` |
| `CapTofState` | `distanceInMillimeter` (1) | `int32` | **fixed32** | `PbFieldType.OF3` |
| `CapTofState` | `kcps` (2) | `int32` | **fixed32** | `PbFieldType.OF3` |
| `CapActivationLog` | `batterySocInPercentage` (3) | `int32` | **fixed32** | `PbFieldType.OF3` |
| `CapSipSensorState` | `value` (1) | `int32` | **sint32** (zigzag) | `PbFieldType.OS3` |
| `CapBottleSensorState` | `value` (1) | `sint32` | `sint32` ✓ | already OK |

**`CapLogQuery` fields** (used for sending, not receiving):
| Field | Type |
|---|---|
| `fromTimestamp` (1) | `uint64` (varint, same wire format as `int64` for positive values) |
| `limit` (2) | **fixed32** — hand-encoded with tag `0x15` because generated proto uses `int32` varint which is wrong |

**Fix:** Edit `cap.pb.dart` field registrations to add explicit
`fieldType: $pb.PbFieldType.OF3` for fixed32 fields and
`fieldType: $pb.PbFieldType.OS3` for sint32 fields. Also hand-encode
log query bodies (the `CapLogQuery.limit` field) because the generated
`CapLogQuery` class uses `aI` (varint) which the bottle rejects.

**Verified working:** TOF distance shows correct non-zero values (74 mm,
73 mm), sip counter changes across readings (0x01 → 0x02), confirming
both OF3 and OS3 fixes decode correctly.

**`CapPowerSavingMode`** values are inverted relative to the intuitive
naming in the bottle's firmware:

| Value | Firmware enum name | Meaning |
|-------|-------------------|---------|
| 0 | `POWER_SAVING_MODE_ON` | Power saving ON |
| 1 | `POWER_SAVING_MODE_OFF` | Power saving OFF |
| 2 | `POWER_SAVING_MODE_AUTO` | Auto mode |

The `CapEnumUiState` values match ours (0–18 in the same order) but use
different enum names (`UI_STATE_ON`, `UI_STATE_FAULT`, …).

### Official Reference App

The decompiled official LARQ Android app is at
`/tmp/opencode/larq_live_decomp/`. Key BLE parameters used:

| Parameter | Value |
|-----------|-------|
| BLE library | `flutter_blue_plus` ^1.34.5 |
| Proto codec | Hand-written encoder/decoder (`_PbWriter`/`_PbReader`) |
| TX UUID | `6e400002-b5a3-f393-e0a9-e50e24dcca9e` |
| RX UUID | `6e400003-b5a3-f393-e0a9-e50e24dcca9e` |
| Write type | `withoutResponse: true` |
| MTU | Default (512, negotiates to 247) |
| requestId start | 1 (pre-increment) |

The embedded proto descriptor is at `sources/defpackage/CapBle.java`
(in a single long string literal near line 47137).

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
    uint64 fromTimestamp = 1;           // cursor: return entries with ts >= this
    fixed32 limit = 2;                  // max entries per page (safe limits vary by type)
    CapEnumLogQuerySearchAlgo algo = 3; // 0=TIMESTAMP, 1=INCREMENT
}
```

**Hand-encoding required:** The Dart `protoc-gen-dart` silently drops
`fixed32` and `uint64` annotations, generating `int32`/`int64` fields
with varint encoding. The bottle expects `fixed32` (4-byte LE) for
`limit`. Log queries must be hand-encoded to produce the correct wire
format (tag `0x15` for limit, tag `0x08` for fromTimestamp).

### Paging

The bottle always returns entries **ascending** from the cursor:

| `fromTimestamp` | Result |
|-----------------|--------|
| `0` | Oldest entries first; includes an epoch-0 dummy entry (`ts≈23`, trigger=Request, distance=0mm) |
| `max(seenTimestamps) + 1` | Next page (forward) |
| Very large (future) | After forward-paging has warmed the connection, **sometimes** returns newest entries descending. On a fresh connection, returns empty. **Unreliable — prefer forward-paging only.** |

Each response contains at most **N** entries where N depends on the entry
type and the BLE MTU boundary (244 bytes). See "BLE Notification Boundary
Truncation" section above for per-type safe limits. The `limit` parameter
in the query should match these safe limits; requesting more than will fit
causes the bottle to return a truncated protobuf with a partial last entry.

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

`CapPowerSavingMode`: **Inverted!** `POWER_SAVING_MODE_ON=0`, `POWER_SAVING_MODE_OFF=1`, `AUTO=2`.

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

## MAC Rotation

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
