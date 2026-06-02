Here are the findings again with the artifacts now under `./tmp`.

The APK ships the protocol schemas directly:

- [cap_ble.proto](/home/albi/src/bottle/tmp/larq_base/cap_ble.proto)
- [event_log_model.proto](/home/albi/src/bottle/tmp/larq_base/event_log_model.proto)

Key BLE path:

- Scan filter: Device Information service `0000180A-0000-1000-8000-00805F9B34FB`
- Device names look like `LARQ_` + 11-char base62 suffix
- The suffix decodes to a 16-hex-char device id; code is in [Dc/l.java](/home/albi/src/bottle/tmp/larq_jadx/sources/Dc/l.java)
- Your nRF log confirms this: `LARQ_0jMdSZS8blV` decodes to serial `0885C30335D4E7B5`, matching `0x2A25`

Main protocol is Nordic UART Service:

- Service: `6e400001-b5a3-f393-e0a9-e50e24dcca9e`
- RX/write: `6e400002-b5a3-f393-e0a9-e50e24dcca9e`
- TX/notify: `6e400003-b5a3-f393-e0a9-e50e24dcca9e`
- CCCD: `00002902-0000-1000-8000-00805f9b34fb`

DFU is Nordic too:

- Service: `0000FE59-0000-1000-8000-00805F9B34FB`
- Buttonless DFU characteristic: `8ec90003-f315-4f60-9fb8-838830daea50`

Protocol shape:

```text
write raw CapBleRequest protobuf bytes to NUS RX
receive raw CapBleResponse protobuf bytes from NUS TX notifications
```

No extra app-level length prefix/framing showed up. Evidence:

- Request bytes use `capBleRequest.toByteArray()` in [wc/C5585n.java](/home/albi/src/bottle/tmp/larq_jadx/sources/wc/C5585n.java)
- Notification bytes are parsed directly with `CapBleResponse.parseFrom(bytes)` in [wc/C5566C.java](/home/albi/src/bottle/tmp/larq_jadx/sources/wc/C5566C.java)
- Request envelope helper is in [xc/Z1.java](/home/albi/src/bottle/tmp/larq_jadx/sources/xc/Z1.java)

Hydration-relevant reads:

- `RequestGetCapTofLog` -> `ResponseGetCapTofLog`
- `RequestGetCapStateLog` -> `ResponseGetCapStateLog`
- Useful setup/context: `RequestGetCapTofSettings`, especially `bottleSizeInMilliliter`

Log query:

```proto
message CapLogQuery {
  uint64 fromTimestamp = 1;
  fixed32 limit = 2;
  CapEnumLogQuerySearchAlgo algo = 3;
}
```

Start with:

```text
fromTimestamp = last_seen_timestamp, or 0 initially
limit = 10 or similar
algo = SEARCH_ALGO_TIMESTAMP
```

The app can also use `SEARCH_ALGO_INCREMENT`, but that is remote-config controlled. Timestamp search is the safer first probe.

Your nRF log is here:

- [nrf_log.txt](/home/albi/src/bottle/tmp/nrf_log.txt)

It confirms the service/characteristic layout but does not yet include protobuf writes or TX notifications.