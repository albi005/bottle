# Sip / Water Intake Sync — Bottle Protocol Reference

## Overview

The LARQ PureVis 2 bottle exposes several BLE protobuf APIs for retrieving sensor
data and logs. This document describes the APIs relevant to sip detection and
water intake tracking, with references to both our Dart implementation and the
decompiled LARQ Android app (jadx output in `tmp/jadx_output/`).

---

## 1. CapLogQuery — Log Retrieval Parameters

**Proto definition** (reconstituted from `CapBle.java:10656`):

```protobuf
message CapLogQuery {
    int64 fromTimestamp = 1;
    int32 limit = 2;
    CapEnumLogQuerySearchAlgo algo = 3;
}

enum CapEnumLogQuerySearchAlgo {
    SEARCH_ALGO_TIMESTAMP = 0;
    SEARCH_ALGO_INCREMENT = 1;
}
```

**Ours:** `app/lib/models/larq_protocol.dart` (model types),
`app/lib/services/protobuf_codec.dart:688` (encode).

### Parameters

| Field | Wire | Type | Effect |
|-------|------|------|--------|
| `fromTimestamp` (1) | varint | int64 | **Cursor** — returns entries with timestamp >= this value. Acts as a seek/index into the bottle's internal log. |
| `limit` (2) | varint | int32 | Requested max entries. Bottle caps at **8 per response** (MTU 247 bytes, observed in live testing). Note: our Dart codec uses `writeFixed32` for this field, but the proto schema declares it as `int32` (varint-encoded). Both encodings work for small values. |
| `algo` (3) | varint | enum | `0` = TIMESTAMP (default), `1` = INCREMENT (rare). See below. |

### Sort Order

**There is no sort-order parameter.** The bottle always returns entries
**ascending** (oldest-first) from the cursor position:

| `fromTimestamp` value | Behavior |
|------------------------|----------|
| `0` | Oldest entries first (ascending; includes epoch-0 dummy) |
| `lastSeenTs + 1` | Next page after cursor (ascending) |
| Very large future value (e.g., `now + 1 year`) | **Sometimes** returns descending (newest-first), but **only after the bottle has been warmed up by several forward-paging queries during the same connection**. On a fresh connection, returns empty (`code=success, type_url=null, bodyLen=null`). |

### `algo` Field (SEARCH_ALGO_TIMESTAMP vs SEARCH_ALGO_INCREMENT)

From decompiled app (`Nc/t.java:318`):

```java
// INCREMENT is selected ONLY when:
//   incrementEnabled=true AND isFirstRequest=false AND !f11317o
// Otherwise: TIMESTAMP
capEnumLogQuerySearchAlgo =
    (!aVar.f8898c || query.f8928b || this.f11317o)
        ? CapBle.CapEnumLogQuerySearchAlgo.SEARCH_ALGO_TIMESTAMP  // default
        : CapBle.CapEnumLogQuerySearchAlgo.SEARCH_ALGO_INCREMENT; // rare
```

- `aVar.f8898c` = `incrementEnabled` (from `Kc/a.java:18` — `BottleElpCmdV3` descriptor)
- `query.f8928b` = `isFirstRequest` (from `Kc/k.java:10` — `ELTimelineTraversalQuery`)
- `f11317o` = runtime boolean parameter

**Live test result:** `algo=1` caused the bottle to disconnect (firmware crash or
unhandled state). The app also uses a different retry strategy for INCREMENT
mode (`AbstractC5581j.b` vs `.a` at `Nc/t.java:359`). Avoid `algo=1` on the
PureVis 2 firmware.

### Paging

Each response returns exactly **8 entries** (except the last page). To page
forward:

```
fromTs = lastReceivedEntry.timestamp + 1
```

The dummy epoch-0 entry (`ts≈23`, type=Request, 0mm) appears as the last entry
in every response.

### Request/Response Wrappers

The same `CapLogQuery` object is used for all log types, wrapped in type-specific
requests:

| Log Type | Request Wrapper | Our Code |
|----------|----------------|----------|
| ToF Log | `RequestGetCapTofLog { query: 1 }` | `encodeRequestGetCapTofLog` at `protobuf_codec.dart:702` |
| State Log | `RequestGetCapStateLog { query: 1 }` | `encodeRequestGetCapStateLog` at `protobuf_codec.dart:737` |
| Activation Log | `RequestGetCapActivationLog { query: 1 }` | `encodeRequestGetCapActivationLog` at `protobuf_codec.dart:709` |
| Fault Log | `RequestGetCapFaultLog { query: 1 }` | `encodeRequestGetCapFaultLog` at `protobuf_codec.dart:716` |
| Activation ADC Log | `RequestGetActivationCapAdcLog { query: 1 }` | `protobuf_codec.dart:723` |
| Charging ADC Log | `RequestGetChargingCapAdcLog { query: 1 }` | `protobuf_codec.dart:730` |

Decompiled command mapping (`Y.java` → `b2.java` → characteristic UUID):

| Y Subclass | b2 Field | Command String |
|------------|----------|---------------|
| `Y.m` | `b2.f48206F` | `"readTofLog"` |
| `Y.k` | `b2.f48211K` | `"readStateLog"` |
| `Y.d` | `b2.f48209I` | `"readActivationLog"` |
| `Y.h` | `b2.f48210J` | `"readFaultLog"` |
| `Y.c` | `b2.f48207G` | `"readActivationAdcLog"` |
| `Y.g` | `b2.f48208H` | `"readChargingAdcLog"` |

**Ours:** `app/lib/services/larq_ble_service.dart:648-707` (query methods),
`:804-850` (loadMore methods), `:857-914` (auto-paging).

---

## 2. CapTofLog — ToF Distance Log Entry

**Proto definition** (reconstituted from `CapBle.java:14236`):

```protobuf
message CapTofLog {
    int64 timestamp = 1;
    CapEnumTofTriggerType triggerType = 2;
    int32 distanceInMillimeter = 3;
    int32 kcps = 4;
    float uvLedTempInOhm = 5;
}
```

**Ours:** `app/lib/models/larq_protocol.dart` (CapTofLog class),
`app/lib/services/protobuf_codec.dart` (decode).

### CapEnumTofTriggerType

**IMPORTANT: Our enum values are WRONG.** From decompiled `CapBle.java:8533`:

| Value | Actual Name | Our Code (WRONG) |
|-------|------------|-------------------|
| 0 | `TYPE_REQUEST` | sip → **should be 4** |
| 1 | `TYPE_INTERVAL` | flap → **should be 3** |
| 2 | `TYPE_CAP` | cap (correct) |
| 3 | `TYPE_CAP_ON_FLAP` | interval → **should be 1** |
| 4 | `TYPE_CAP_ON_FLAP_OPEN_SIP` | request → **should be 0** |

Human-readable mapping from decompiled `nc/C4346e.java:77-93`:
```
0 = "request", 1 = "interval", 2 = "cap", 3 = "flap", 4 = "sip"
```

**Fix needed:** Update `CapEnumTofTriggerType` enum in `app/lib/models/larq_protocol.dart`.

---

## 3. CapSipSensorState — Live Sip Sensor (Capacitive)

**Proto** (from `CapBle.java:11802`):

```protobuf
message CapSipSensorState {
    int32 value = 1;   // cumulative sip counter, increments on each detection
    bool state = 2;     // true while a sip is currently active
}
```

Request: `RequestGetCapSipSensorState` — empty, no parameters.
Response: `ResponseGetCapSipSensorState { CapSipSensorState state = 1; }`

**Command:** `"readSipSensorState"` (`b2.f48234w` at `xc/b2.java:168-169`).
No dedicated `Y` subclass — handled directly with a lambda in the descriptor map
(`J4/c.java:186`), which builds the empty `RequestGetCapSipSensorState` message.

**Ours:** `app/lib/services/larq_ble_service.dart:721` (`getSipSensorState()`).

### Usage in LARQ App

The live sip sensor state is polled but **only piped to cloud analytics**
(`BottleBleToCloudSubscription` at `D9/C1133s.java:51`). It is NOT used for
local sip counting or water intake computation.

---

## 4. CapStateLog — State Log with Sip Detection

**Proto** (from `CapBle.java:12308`):

```protobuf
message CapStateLog {
    int64 timestamp = 1;
    bool hall = 2;                              // lid open/closed
    bool bottleDetection = 3;                   // bottle presence
    bool ambientLight = 4;                      // ambient light
    bool sipDetection = 5;                      // sip detected in this interval
    float bottleDetectionCapacitorValue = 6;     // raw cap value
    float ambientLightSensorValue = 7;           // raw ambient light
    float sipDetectionCapacitorSensorValue = 8;  // raw sip cap value
}
```

Uses same `CapLogQuery` wrapper as ToF log. Retrieved via `readStateLog` command.

**Note:** The LARQ app uses `CapStateLog` entries only for cloud event logging
(`T/C2361a1.java:111-118`, `ab/C2636c.java:40-61`), not for local sip tracking.

---

## 5. ToF-to-Liquid-Intake Algorithm (How the LARQ App Counts Drinks)

The LARQ app does **not** use `CapSipSensorState` or `CapStateLog.sipDetection`
for water intake. Instead, it runs a **ToF distance-based volume algorithm**
(`BottleVolumeSubscription`, found in `N3/o.java`, `N3/p.java`):

**Input:** `CapTofLog` entries (ToF distance log)

**Method:** Analyzes `distanceInMillimeter` changes over time (inferred from
variable/field names in `mc/C4197a.java` and `AlgorithmConfig.java`; the core
algorithm in `N3/o.java` is obfuscated and could not be decompiled):
- Decreasing volume (likely distance increases) past `drinkThresholdInMl` → records a liquid intake
- Increasing volume (likely distance decreases, e.g. refill) past `fillThresholdInMl` → detects a fill
- Distance near 0mm for extended period → "bottle away" (not in use)

**Parameters** from decompiled app:

From `AlgorithmConfig.java:24-26` (the algorithm thresholds):
| Param | Type | Meaning |
|-------|------|---------|
| `drinkThresholdInMl` | double | Min volume decrease to count as a drink |
| `fillThresholdInMl` | double | Min volume increase to count as a fill |
| `minVolumeLimitInMl` | double | Min volume for any event |

From `N3/a.java` (runtime algorithm parameters passed to the compute function):
| Param | Type | Meaning |
|-------|------|---------|
| `isFilterTofByLatestTsEnabled` | bool | Filter ToF entries by latest known timestamp |

**Output:** Liquid intake records with `source = "bottle"` (`EnumC3684h.BOTTLE`
at `ic/EnumC3684h.java:37`), sent to Firebase via `LiquidIntakeService`.

**App-side volume state** (`mc/C4197a.java` — `BottleVolumeState`):
```
date, tofDist, lastSkippedVolumeInML, lastCalcVolumeInML,
lastCountedVolumeInML, volumeAddedInML, cumulativeCalcVolumeInML, tofSkipped
```

The algorithm maintains a `VolumeStateDic` (`C3673c<C4198b>`) that tracks the
bottle's fill level over time across multiple ToF readings.

**Bottom line:** To compute water intake, you need to run the ToF
distance-based volume algorithm on `CapTofLog` entries, not the sip sensor.

---

## 6. Other Log Types

### CapActivationLog (`CapBle.java:1112`)

```protobuf
message CapActivationLog {
    int64 timestamp = 1;
    CapEnumUvActivationMode mode = 2;
    int32 batterySocInPercentage = 3;
}
```

### CapFaultLog (`CapBle.java:8849`)

```protobuf
message CapFaultLog {
    int64 timestamp = 1;
    CapEnumFaultType type = 2;
}
```

### CapAdcLog (`CapBle.java:1684`)

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

---

## 7. Bottle Rate Limits

Live testing revealed:
- The bottle disconnects (link supervision timeout) after ~3 rapid BLE requests
- Safe rate: **1 request per 10+ seconds** during sequential probing
- During auto-paging (with delays between pages), ~150 pages complete successfully
- The normal poll cycle (many sensor queries with <1s gaps) also causes occasional
  disconnects on weaker connections

---

## 8. Health Connect Integration

**Ours:** `app/lib/services/health_connect_service.dart`

For syncing water intake to Android Health Connect, the approach should be:
1. Retrieve `CapTofLog` entries via the paging mechanism
2. Run the ToF-to-liquid-intake algorithm on the distance data
3. Write `HydrationRecord` entries to Health Connect

The `CapSipSensorState.value` (cumulative sip counter) is an alternative
simpler approach but the LARQ app uses the ToF distance method for accuracy.

---

## Source References

### Our Code
| Component | File |
|-----------|------|
| BLE Service | `app/lib/services/larq_ble_service.dart` |
| Protobuf Codec | `app/lib/services/protobuf_codec.dart` |
| Protocol Models | `app/lib/models/larq_protocol.dart` |
| Health Connect | `app/lib/services/health_connect_service.dart` |
| Device Screen | `app/lib/screens/device_screen.dart` |

### Decompiled LARQ App
| Component | File |
|-----------|------|
| CapBle protobuf definitions | `tmp/jadx_output/sources/defpackage/CapBle.java` |
| EventLog protobuf | `tmp/jadx_output/sources/defpackage/EventLogModel.java` |
| Command types (Y) | `tmp/jadx_output/sources/wc/Y.java` |
| Characteristic map (b2) | `tmp/jadx_output/sources/xc/b2.java` |
| Timeline traversal (algo sel) | `tmp/jadx_output/sources/Nc/t.java` |
| BottleVolumeSubscription | `tmp/jadx_output/sources/N3/o.java`, `N3/p.java` |
| Algo params | `tmp/jadx_output/sources/N3/a.java` |
| Volume state | `tmp/jadx_output/sources/mc/C4197a.java` |
| Algorithm config | `tmp/jadx_output/sources/com/product/core_elp/bottle/v3/reporting/AlgorithmConfig.java` |
| Sip sensor handler | `tmp/jadx_output/sources/xc/H1.java` |
| Sip sensor descriptor registration | `tmp/jadx_output/sources/J4/c.java:186` |
| Liquid intake source enum | `tmp/jadx_output/sources/ic/EnumC3684h.java` |
| Event log builder | `tmp/jadx_output/sources/T/C2361a1.java` |
| Cloud subscription | `tmp/jadx_output/sources/D9/C1133s.java` |
| Trigger type names | `tmp/jadx_output/sources/nc/C4346e.java` |
