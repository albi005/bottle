# Bottle (LARQ PureVis 2 BLE Bridge) — Session Resume

## Project
Flutter app (`app/`) that communicates with a LARQ PureVis 2 water bottle via BLE (UART service). Reverse-engineered protobuf protocol. Scans for bottles, connects, polls sensor states and log data.

## Environment
- **OS**: NixOS
- **Device**: Pixel 6 (ID `18221FDF6000GY`), USB-connected
- **Flutter**: 3.41.6 (via global NixOS config + devenv)
- **Build**: `flutter build apk --debug` or `flutter run -d 18221FDF6000GY`

## Recent Changes (in order of commits)

### `22fbb08` — Wrap CapLogQuery in request envelope, EOF-safe protobuf reader
- `_PbReader` now throws `PbReaderException` on premature EOF instead of silent truncation
- All log query functions now wrap `CapLogQuery` in `encodeRequestGet*()` before sending

### `baa7261` — Fix CapAdcLog 7-field model, add log paging with merge/load-more
**CapAdcLog** — Real proto has 7 float fields:
- `timestamp` (uint64, 1), `batteryInVolt` (float, 2), `batteryTempInOhm` (float, 3), `uvLedInVolt` (float, 4), `uvLedCurrentInMilliamps` (float, 5), `uvLedTempInOhm` (float, 6), `cPcbTempInOhm` (float, 7)
- Previously had `batteryVoltage` + `batterySocInPercentage` (incorrect — field 3 was read as fixed32 instead of float)
- `_decodeCapAdcLogList()` now reads all 7 fields correctly
- Battery % comes from `CapActivationLog.batterySocInPercentage` (field 3, fixed32) and GATT Battery Service — these are correct

**Paging**:
- `_mergeLogList()` deduplicates by timestamp, appends (doesn't replace)
- `loadMore{LogType}()` methods: `fromTimestamp = max(seen timestamps) + 1`, `limit = 255`
- "Load more entries" buttons on ToF, Activation, Fault, and ADC log cards (all converted to `StatefulWidget`)

### `d167619` — Increase limit to 255, fix button text, add FLUTTER_SDK
- `CapLogQuery` limit: 50 → 255 (practical max)
- Button text: "Load older entries" → "Load more entries" (bottle returns in storage order, not reverse-chrono)
- `devenv.nix`: added `env.FLUTTER_SDK` (for Dart MCP server)

### `475bc70` — Set FLUTTER_SDK to pkgs.flutter for MCP launch support
- Changed `env.FLUTTER_SDK` from `config.env.FLUTTER_ROOT` to `"${pkgs.flutter}"`

## Key Files

| File | Purpose |
|------|---------|
| `app/lib/models/larq_protocol.dart` | Proto model classes (CapAdcLog, CapTofLog, CapActivationLog, etc.) |
| `app/lib/services/protobuf_codec.dart` | Protobuf encoder/decoder, `_PbReader` (EOF-safe), all `encodeRequest*`/`decodeResponse*` |
| `app/lib/services/larq_ble_service.dart` | BLE comms, polling loop, paging (loadMore), merge logic |
| `app/lib/screens/device_screen.dart` | UI — sensor cards, log cards with load-more buttons |
| `app/lib/screens/home_screen.dart` | Scan/connect screen (still in use — `main.dart` entry point) |
| `app/lib/main.dart` | App entry, permissions, theme |
| `devenv.nix` | devenv config (android, flutter, FLUTTER_SDK) |

## MCP Launch Issue

The Dart MCP server's `launch_app` fails with `ProcessException: No such file or directory` when trying to spawn `flutter run`. The same command works from bash. This appears to be an environment inheritance issue — the MCP server was started before the devenv/direnv environment was fully active. A **fresh opencode session** started after direnv activated works fine (confirmed by another session launched successfully on same setup).

**Workaround**: Use `bash` tool to launch:
```
cd /home/albi/src/bottle/app && flutter run -d 18221FDF6000GY
```
Then use MCP `hot_restart`/`hot_reload`/`get_app_logs`/`flutter_driver` after connecting DTD.

## Bottle Info
- Name: `LARQ_0jMdSZS8blV` (MAC rotates, currently ~7B:24:AE:77:0C:60)
- Firmware: `00000101`
- Battery: ~78-90% (varies between GATT and activation log readings)
- Current log counts: 8 ToF, 10 Activation, 5 Fault, 5 Act ADC, 6 Chg ADC

## Testing Flow
1. `flutter run -d 18221FDF6000GY` from `app/` dir
2. App scans and auto-connects to bottle
3. Poll loop runs: ToF Log → ToF State → Bottle Sensor → UI State → SIP → Accel → Ambient Light → Hall Effect → Activation Log → Fault Log → Act ADC → Chg ADC → Battery
4. Logs populate in expandable cards; "Load more entries" buttons available

## Useful Commands
```bash
# Build and run
cd app && flutter run -d 18221FDF6000GY

# Build APK only
flutter build apk --debug

# Watch logs
adb logcat -s flutter | grep LARQ

# Kill stale flutter (pkill -f hangs; use kill by PID)
pgrep -f "flutter.*run"  # get PID
kill -9 <PID>
```

## Paging Logic Note
The bottle returns log entries in storage order (roughly chronological, not strictly sorted by timestamp). `fromTimestamp` filters entries `>=` the given value. Load-more uses `fromTimestamp = maxTs + 1` which pages forward in storage order. Not all entries with lower timestamps may be returned on the first page.

## Android SDK
- `ANDROID_HOME` set by devenv
- `local.properties` auto-generated, gitignored
