# ATAK interoperability check: 2026-11-14

Filled-in copy of [ATAK-INTEROP-CHECK.md](ATAK-INTEROP-CHECK.md).

| | |
|---|---|
| Build tag + APK SHA-256 | First run: beta.15 (1.0.0+19) plus the #244 offline-map fix, signed locally. Recheck: published v1.0.0-beta.16 (1.0.0+20) |
| Phone + Android | Samsung SM-S156V, Android 16 |
| ATAK version | ATAK-CIV 5.6.0.12 (Play Store) |
| Radio + firmware | T1000-E "SQCH_49cb", Meshtastic over Bluetooth, 14 mesh nodes |

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Turn on the TAK bridge: consent screen first, nothing shared before accepting | **Fail, then Pass on beta.16** | First run: no consent screen, the switch started sending straight away. Beta.16: turning on "Send mesh positions to ATAK" shows "Share mesh positions with ATAK?". Cancel left it off (no "Sending" line); "Share with ATAK" turned it on ("Sending 2 nodes"). |
| 2 | Mesh node positions appear in ATAK with the right names and places | **Pass** | 3 nodes appeared under Team › Cyan Team: `!9ea67960`, `Bigfoot's Burner Phone` (1–10 m from the phone, matches the radio beside it) and `Rav4 KC1TCD`. ATAK's default UDP input on 4242 worked without any ATAK setup. |
| 3 | Moving node updates in ATAK; old positions go stale and disappear after their expiry | **Partly** | Moves update: `Rav4 KC1TCD` went from 2.53 km to 1,223 m between checks. Disappearing: 6+ min after the bridge was turned off (stale is 5 min) all 3 were still listed. Connect sends them as team members (`a-f-G-U-C`), which ATAK keeps on its list after they go stale. |
| 4 | A marker placed in ATAK appears on the Connect map | **Fail, then Pass on beta.16** | First run: the default receive port 4243 failed with "Address already in use" (ATAK 5.6 holds 4243), fixed in PR #245 (default 4250). Beta.16 with a real ATAK output (Manage Outputs › UDP 127.0.0.1:4250): ATAK's own position showed as "ATAK Friendly: arrowhead". A point placed in ATAK and sent with Send › Broadcast took the count from "Showing 1 marker" to "Showing 2 markers". |
| 5 | Connect's own position sent to ATAK isn't echoed back into Connect as a second marker | **Pass on beta.16** | With both directions on for about 10 minutes (Connect sending 2 nodes, ATAK outputting to 4250), Connect showed only the 2 ATAK markers above, none of its own nodes. A `NOTORYX-` uid sent by hand is also ignored. |
| 6 | Nothing is transmitted over the mesh because of ATAK traffic (watch the radio's TX count) | **Pass (by code)** | TX count not read off the radio. In the code, the bridge only reads the node list and sends to 127.0.0.1; received markers are only drawn on the map. Nothing in the bridge can reach the radio. |
| 7 | Oversized or malformed CoT from ATAK is ignored without a crash | **Pass** | Bad numbers, non-XML bytes, a 0,0 position and an 80 KB message: app stayed up, none shown (netcat split the 80 KB message into packets, and the first piece, which held a complete event, was shown). |
| 8 | Many markers (50+) don't freeze either app | **Pass** | 60 markers sent back to back: "Showing 62 markers", no freeze, no "not responding". "Clear markers" removed them. |
| 9 | Turning the bridge off stops all sharing straight away | **Pass** | Turned off at 16:46:56. Connect closed its send socket and ATAK logged "port 4242 has not received data" from then on. |

## Other findings

- ATAK will not stay open without "Allow all the time" location on first start; it loops on its own permission screens and closes on Cancel. On a later start it opened normally.
- Connect's background service stopped while the phone was in Settings (16:31), and Android then closed the app; the radio link and ATAK feed stopped with it until Connect was opened again. It did not reconnect to the radio on its own when reopened. **Fixed in beta.16 (#247, #249):** with ATAK in front for 5½ minutes the service and radio link stayed up; swiping Connect away from Recents removed the radio notification within 16 s; reopening reconnected to the radio on its own in about 10 s.
- The scan list shows the connected radio twice, both with Disconnect. **Fixed in beta.16 (#248):** shown once.
- Connect logged an unhandled `SocketException` from its MQTT connection (`mqtt.meshtastic.org`, "Software caused connection abort"). Handled in beta.16 (#248); the exact network error was not reproduced again.

## Cleanup

After the recheck both Connect ATAK switches were turned off and the "Connect test" output was removed from ATAK. The two test points placed in ATAK (R.14.183158, R.14.233737) are still on its map.
