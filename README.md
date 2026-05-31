# bottle

Flutter app for syncing hydration data from a LARQ PureVis 2 smart water bottle
to Android Health Connect.
100% vibe-coded using OpenCode with DeepSeek V4 Pro (except for this README).

It automatically connects to nearby bottles, updates sensor data one-by-one,
syncs all logs to a SQLite database, then syncs hydration data to Health Connect.

- Android demo: https://youtube.com/watch?v=jNG4D9gp-lo
- Linux demo: https://youtube.com/watch?v=vJm-NQ-mUOg

The BLE protocol was reverse-engineered from a decompiled LARQ app.

Uses
- `signals` for updating the UI when state changes,
- `flutter_blue_plus` and `protobuf` for communicating with the bottle,
- `get_it` and `injectable` for dependency injection.
