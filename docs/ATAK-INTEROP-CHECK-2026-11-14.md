# ATAK interoperability check: 2026-11-14

Filled-in copy of [ATAK-INTEROP-CHECK.md](ATAK-INTEROP-CHECK.md).

| | |
|---|---|
| Build tag + APK SHA-256 | beta.15 (1.0.0+19) plus the #244 offline-map fix, signed locally (not a published build) |
| Phone + Android | Samsung SM-S156V, Android 16 |
| ATAK version | ATAK-CIV 5.6.0.12 (Play Store) |
| Radio + firmware | T1000-E "SQCH_49cb", Meshtastic over Bluetooth, 14 mesh nodes |

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Turn on the TAK bridge: consent screen first, nothing shared before accepting | **Fail** | There is no consent screen. The switch starts sending straight away; the only notice is the text above the switch ("Nothing leaves the phone, and nothing goes out over the mesh"). Either add a one-time consent step or change this row. |
| 2 | Mesh node positions appear in ATAK with the right names and places | **Pass** | 3 nodes appeared under Team › Cyan Team: `!9ea67960`, `Bigfoot's Burner Phone` (1–10 m from the phone, matches the radio beside it) and `Rav4 KC1TCD`. ATAK's default UDP input on 4242 worked without any ATAK setup. |
| 3 | Moving node updates in ATAK; old positions go stale and disappear after their expiry | **Partly** | Moves update: `Rav4 KC1TCD` went from 2.53 km to 1,223 m between checks. Disappearing: 6+ min after the bridge was turned off (stale is 5 min) all 3 were still listed. Connect sends them as team members (`a-f-G-U-C`), which ATAK keeps on its list after they go stale. |
| 4 | A marker placed in ATAK appears on the Connect map | **Fail, then Pass (simulated)** | With the default receive port 4243, Connect showed "Could not listen: … Address already in use": ATAK 5.6 holds 4243 itself. Fixed in PR #245 (default 4250). With the port set to 4250 by hand, CoT sent over loopback from adb showed as a marker. Not yet tried with a real ATAK output (ATAK › Network Preferences › Manage Outputs › UDP 127.0.0.1:4250). |
| 5 | Connect's own position sent to ATAK isn't echoed back into Connect as a second marker | **Pass (simulated)** | A CoT with a `NOTORYX-` uid was ignored. Real ATAK echo not tried (needs the ATAK output above). |
| 6 | Nothing is transmitted over the mesh because of ATAK traffic (watch the radio's TX count) | Not tried | TX count not watched. |
| 7 | Oversized or malformed CoT from ATAK is ignored without a crash | **Pass** | Bad numbers, non-XML bytes, a 0,0 position and an 80 KB message: app stayed up, none shown (netcat split the 80 KB message into packets, and the first piece, which held a complete event, was shown). |
| 8 | Many markers (50+) don't freeze either app | **Pass** | 60 markers sent back to back: "Showing 62 markers", no freeze, no "not responding". "Clear markers" removed them. |
| 9 | Turning the bridge off stops all sharing straight away | **Pass** | Turned off at 16:46:56. Connect closed its send socket and ATAK logged "port 4242 has not received data" from then on. |

## Other findings

- ATAK will not stay open without "Allow all the time" location on first start; it loops on its own permission screens and closes on Cancel. On a later start it opened normally.
- Connect's background service stopped while the phone was in Settings (16:31), and Android then closed the app; the radio link and ATAK feed stopped with it until Connect was opened again. It did not reconnect to the radio on its own when reopened.
- The scan list shows the connected radio twice, both with Disconnect.
- Connect logged an unhandled `SocketException` from its MQTT connection (`mqtt.meshtastic.org`, "Software caused connection abort").
