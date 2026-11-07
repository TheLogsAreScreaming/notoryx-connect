# NOTORYX Connect: competitive strategy and roadmap

Researched 2026-11-07 against `main` b0d3643. Evidence and competitor profiles are in [COMPETITIVE_ANALYSIS.md](COMPETITIVE_ANALYSIS.md); the side-by-side table is [FEATURE_MATRIX.md](FEATURE_MATRIX.md). Abbreviations: **MA** Meshtastic Android, **MI** Meshtastic Apple, **MW** Meshtastic Web, **SM** Socialmesh.

Everything here is a proposal. Nothing in this PR changes app code.

## 1. Competitive advantage opportunities

| Opportunity | Why it is open | Connect's head start |
|---|---|---|
| **The field-safety client** | No verified competitor has trip plans, overdue alerts, check-ins that report who they reached, or SOS that stops when answered | `bastion_trip.dart`, `bastion_field_checkin.dart` |
| **"Every save is proven"** | Competitors write config and hope. MW has no config backup at all (#247) | `bastion_settings_verifier.dart`, encrypted backups |
| **Explain the connection** | MI #1533, MA #6685 and MeshWave reviews show users can't tell why a link fails | Reconnect supervisor and background card already exist |
| **Explain the message path** | MA #896, #922; MI #1546, #1611: users want RF/MQTT/hops on each message | `viaMqtt` label exists; hops not yet |
| **Privacy by default, no account** | MeshWave collects device ID; Mesh World requires email; SM uses optional Firebase | No account, no cloud, privacy page, position rounding |

## 2. Competitor weakness report

| # | Weakness | Apps affected | Evidence | Connect today | Better answer | Benefit | Difficulty | Priority |
|---|---|---|---|---|---|---|---|---|
| W1 | Connection stuck or unexplained | MI, MA, MeshWave | MI #1533 (14 👍), MA #6685, MeshWave reviews | Partial: supervisor + background card, but no user-facing cause | Connection doctor: Bluetooth off / permission / bonded elsewhere / battery optimisation / firmware too old, each with one fix button | Fewer "it doesn't work" reports | M | P1 |
| W2 | History slows down with many messages | MI | MI #1040 | Same risk: JSON in SharedPreferences, whole archive re-encoded per write (`bastion_message_archive.dart:164`) | SQLite (drift) store with migration from the JSON archive | No lag, no lost chats | M | P0 |
| W3 | Can't see how a message arrived | MA, MI | MA #896 (14 👍), #922 (19 👍); MI #1546, #1611 | Partial: via-MQTT label only | Hops, RF/MQTT, SNR/RSSI and relay node on each received message | Trust in the mesh | S | P1 |
| W4 | Old firmware fails silently | MA | MA #1031; v2.8.3 forces update below 2.5.14 | Partial: version is read (`meshtastic_radio_coordinator.dart:832`) and used for 2.8 region policy, but there is no user-facing minimum-version gate | Version gate with a clear "update firmware" path (link out until in-app update exists) | Fewer broken sessions | S | P1 |
| W5 | Config backup missing or plain text | MW, others | MW #247 (12 👍, open) | Ahead: AES-256-GCM backup | Keep; add "restore to a new radio" checklist | Safe radio swaps | S | P3 |
| W6 | Location shared by default | MA (fixed) | MA #861 | Ahead: opt-in + rounding | Keep; add per-channel position precision | Privacy | S | P3 |
| W7 | Paywalls and accounts | MeshWave, Mesh World, SM packs | App Store listings and reviews | Ahead: free, GPL-3.0, no account | Keep; say so on the store page | Trust | — | — |
| W8 | Fake node stats | MA | MA #6263 (0 SNR/RSSI/hops on app-provided nodes) | Unverified | Show "no RF data" instead of zeros | Honest diagnostics | S | P2 |
| W9 | Third-party iOS gap | ecosystem | Only SM is open source and active on iOS | Missing: Android only | iOS build of Connect (Flutter makes this practical) | Doubles reachable users | L | P2 |

## 3. Innovation research

| Concept | Offered elsewhere? | Firmware support | Needs firmware change? | Effort | Value | Notes |
|---|---|---|---|---|---|---|
| Connection doctor | No | n/a (phone-side) | No | M | High | Uses Android BT state, bond list, battery-optimisation status, `my_info`/`metadata` firmware version |
| Per-message path card | Partly (MA hops) | `MeshPacket.hop_start`, `hop_limit`, `via_mqtt`, `rx_snr`, `rx_rssi`, `relay_node` (2.6+) | No | S | High | `relay_node` is only the last byte of the relaying node; label it "probably via" |
| Trip readiness check | No | n/a | No | S | High | Before a trip: radio battery, firmware, channel, trip contacts reachable (traceroute), GPS fix, background allowed |
| Check-in delivery map | No | ACKs + positions | No | M | Medium | Show which trip contacts got the check-in and where they last were |
| Airtime/congestion warnings | SM shows airtime | `DeviceMetrics.channel_utilization`, `air_util_tx` | No | S | Medium | Warn before sending repeated SOS on a saturated channel |
| Network change detection | No | NodeInfo/neighbour info | No | M | Medium | "3 routers you relied on went quiet in 24 h" (local-only) |
| SOS via MQTT fallback | No | MQTT client proxy | No, but needs internet | M | Medium | Only when the phone has data; clearly labelled |
| Store-and-forward catch-up on reconnect | Partial (S&F tab) | Store & Forward module on a router | Needs an S&F server on the mesh | M | Medium | Ask the S&F router for missed messages automatically |
| Voice / photos | MeshWave | Not designed for LoRa airtime | Practically yes | L | Low | **Don't build**: burns shared airtime |

## 4. Internal audit

### 4.1 Architecture
- Transport → session → coordinator → services → pages. The transport interface is already written to take TCP and USB (`meshtastic_radio_session.dart:10`).
- Hot spots: `lib/main.dart` (1,957 lines: Nodes, Chats and Tools pages in one file) and `meshtastic_radio_coordinator.dart` (1,686 lines).
- Persistence: 19 files use SharedPreferences; chat archive is one JSON blob per radio.
- State management: `StatefulWidget` + services; no Riverpod/provider layer.

### 4.2 Already ahead (protect these)
Trip/check-in/SOS, read-back verified saves, encrypted radio and phone backups, bot guard rails, filters with SOS bypass, per-radio history, field records and CSV, privacy page, 21 CI workflows including protocol-compatibility and security scans.

### 4.3 Behind (verified in source)
1. Chat storage engine (SharedPreferences JSON).
2. Bluetooth only on `main`; no USB.
3. No firmware update, no remote admin (`to: localNodeNum`), no MQTT client proxy.
4. No hop count on messages; no PKI key display or key-change warning.
5. No translations; `Semantics(` in only 8 files.
6. Android only (iOS not built; macOS build not released).

### 4.4 Most improvement for least effort
Hops + path card on messages (W3), firmware-version gate (W4), merging the six open PRs, and the connection doctor (W1) reuse data Connect already receives.

## 5. Prioritised roadmap

Each item lists problem → solution → code → acceptance → tests. Complexity: S (≤2 days), M (≤1 week), L (>1 week).

### P0: critical

**P0-1 SQLite message store.** *Problem:* the whole chat archive is re-encoded into one SharedPreferences string on every write; MI #1040 shows where this ends. *Solution:* drift tables for messages, queue, reactions, marks per radio; one-time migration from `bastion.*` keys, keep the old blob as `.before-migration`. *Code:* new `lib/services/store/`, adapt `bastion_message_archive.dart`, `bastion_message_search.dart`, `bastion_phone_backup.dart`. *Deps:* drift, sqlite3. *Risk:* migration data loss → keep the old blob, verify counts. *Accept:* 50k messages open a thread in <200 ms on a mid-range phone; backup/restore round-trips; no message lost in migration test. *Tests:* migration fixture from a real export, search parity tests, backup round-trip. **M**

**P0-2 Merge and release the open PRs.** #124 demo, #125 traceroute map, #126 mesh health, #127 rally points, #128 link planner (retarget to `main` after #127), #129 TCP. *Accept:* all merged in order, beta.5 published to notoryx-connect-releases. **S**

**P0-3 Real-radio regression record.** README says tested on one T1000-E. *Solution:* run `docs/DEVICE-TEST-CHECKLIST.md` on at least one ESP32 and one nRF52 radio and record results per release. *Accept:* checklist results committed for beta.5. **S**

### P1: high-impact competitive improvements

| ID | Item | Solves | Competitor comparison | Approach | Accept | Effort |
|---|---|---|---|---|---|---|
| P1-1 | Message path card | W3 | MA shows hops; nobody shows all of RF/MQTT/SNR/relay | Store `hop_start-hop_limit`, `rx_snr`, `rx_rssi`, `via_mqtt`, `relay_node` per message; tap a bubble for the card | Every received message shows hops (or "unknown"); unit tests on packet fixtures | S |
| P1-2 | Firmware version gate | W4 | MA forces update <2.5.14 | Reuse the version already read into `firmwareVersion`; banner + block config writes below a tested minimum | Old-firmware fixture shows the banner; writes blocked | S |
| P1-3 | Connection doctor | W1 | No one explains failures | Diagnose BT off, permission, bonded to another phone, battery optimisation, handshake timeout; one fix action each; copyable log | Each failure state reachable in tests shows its fix | M |
| P1-4 | USB serial | Matrix gap | MA, MW, SM have USB | Reuse PR #129's stream framer with `usb_serial` (vendor if needed, as Independent did) | Connects to an ESP32 over OTG; reconnects after unplug | M |
| P1-5 | PKI key display and key-change warning | Trust | Official apps handle PKI DMs | Show each node's public key fingerprint; warn when it changes; QR verify in person | Key change raises a warning in a test | S |
| P1-6 | Translations | Reach | MA, MI translated | `gen_l10n` with English first; radio-sent tags stay English (as in Core) | No hard-coded UI strings in pages; 1 extra locale | M |
| P1-7 | Trip readiness check | New | No competitor | One screen: battery, firmware, channel, contacts reachable (traceroute), GPS, background allowed | All six checks shown with pass/fail | S |

### P2: advanced differentiators

| ID | Item | Notes | Effort |
|---|---|---|---|
| P2-1 | iOS build | Flutter app; BLE via universal_ble already cross-platform; needs bundle ID, background modes, TestFlight | L |
| P2-2 | Remote admin of other nodes | Session passkey flow already exists for the local node; extend `to:` and PKI admin keys | M |
| P2-3 | MQTT client proxy | Phone uplinks for a radio without Wi-Fi; opt-in, off by default | M |
| P2-4 | Check-in delivery map | Who got it, where they were | M |
| P2-5 | Airtime-aware SOS | Back off when `channel_utilization` is high; tell the user | S |
| P2-6 | Split `main.dart` | Move Nodes/Chats/Tools pages to files; no behaviour change | S |
| P2-7 | Home-screen widget | Radio status + check-in button (Core already has an Android widget to learn from) | M |

### P3: long-term

- In-app firmware update (nRF DFU and ESP32 OTA): high risk of bricking; needs hardware matrix. **L**
- Store-and-forward catch-up on reconnect (needs an S&F router on the mesh). **M**
- Network change detection from neighbour info (local only). **M**
- Android Auto messaging. **M**
- Desktop release (macOS workflow exists). **M**

## 6. Top 25 recommended improvements

Ranked by user impact × feasibility × differentiation.

1. P0-1 SQLite message store
2. P0-2 Merge #124–#129 and ship beta.5
3. P1-1 Message path card (hops, RF/MQTT, SNR, relay)
4. P1-2 Firmware version gate
5. P0-3 Real-radio regression record
6. P1-3 Connection doctor
7. P1-7 Trip readiness check
8. P1-4 USB serial
9. P1-5 PKI fingerprint + key-change warning
10. P2-5 Airtime-aware SOS
11. P2-4 Check-in delivery map
12. P1-6 Translations
13. P2-1 iOS build
14. P2-2 Remote admin
15. P2-6 Split `main.dart`
16. Node/map filter by last heard (MA #1714, MI #1126)
17. "No RF data" instead of zeros (W8)
18. P2-3 MQTT client proxy
19. P2-7 Home-screen widget
20. Offline tile area download (today only viewed tiles are cached)
21. Data-usage view for MQTT/tiles (MA #2765)
22. Semantics pass on all pages
23. P3 Store-and-forward catch-up
24. P3 Network change detection
25. P3 Desktop release

## 7. Quick wins (no architecture change)

- Hop count on each bubble (data already in `MeshPacket`).
- Firmware version banner from the `firmwareVersion` the coordinator already reads.
- "Last heard" filter chips on Nodes and Map.
- "No RF data" label instead of 0 SNR/RSSI.
- Retarget #128 to `main` before merging #127's branch away.
- Copy-log button on the connection error state.

## 8. Innovation backlog (needs research)

| Concept | Open question |
|---|---|
| Firmware OTA in app | Which boards, which bootloaders, rollback |
| Store-and-forward auto catch-up | How common are S&F routers on real meshes? |
| Trip "breadcrumb" over the mesh | Airtime cost of periodic positions vs value |
| Network change detection | False-alarm rate on small meshes |
| SOS via MQTT fallback | Abuse and false-alarm handling on public brokers |

**Do not build:** voice, photos or AR over LoRa (airtime cost, MeshWave reviews show reliability suffers); social gamification (sigils, patina scores); paywalls or accounts.

## 9. Strategic scoring

Scores 0–10. Criteria: 0 = absent, 5 = works for the common case, 8 = best verified in class, 10 = nothing left to want. **Confidence:** H = read source, M = release notes/README, L = store listing only. Missing evidence lowers confidence, not the score.

| Area | Connect | MA | MI | SM | MeshWave |
|---|---|---|---|---|---|
| Ease of use | 7 (H) | 7 (M) | 6 (M) | 6 (M) | 6 (L) |
| Messaging | 7 (H) | 8 (M) | 7 (M) | 7 (M) | 6 (L) |
| Connectivity reliability | 6 (H) | 7 (M) | 6 (M) | ? | 4 (L) |
| Mapping | 7 (H) | 7 (M) | 7 (M) | 7 (M) | 7 (L) |
| Network diagnostics | 7 (H) | 7 (M) | 6 (M) | 7 (M) | 3 (L) |
| Advanced features | 8 (H) | 9 (M) | 7 (M) | 8 (M) | 6 (L) |
| Performance | 5 (H) | 7 (M) | 5 (M) | ? | ? |
| Accessibility | 5 (H) | 7 (M) | 7 (M) | ? | ? |
| Privacy and security | 8 (H) | 7 (M) | 7 (M) | 6 (M) | 4 (L) |
| Overall | 7 | 8 | 7 | 7 | 5 |

"?" = not enough evidence to score. **After P0 + P1:** Connect reaches about 8 overall (connectivity 8, messaging 8, performance 7, accessibility 6), level with MA on Android and ahead on safety and verification.

## 10. Executive summary

- **Strongest competitor:** Meshtastic Android v2.8.3. **Closest third-party:** Socialmesh.
- **What MA does better:** firmware updates, USB/TCP, remote admin, MQTT proxy, translations, database-backed history, Android Auto, desktop.
- **What Connect already does better:** trip safety (plan, check-in, repeating SOS), read-back verified settings, encrypted backups, bot guard rails, field records, no account or cloud.
- **Biggest market gaps:** explaining *why* a connection or message failed; a serious open-source third-party iOS client; field-readiness tooling.
- **Improve on competitor features:** hops per message (MA) → full path card; config backup (MW missing) → keep encrypted lead; SOS (SM) → keep "until answered" lead.
- **Innovations that make Connect stand out:** connection doctor, trip readiness check, check-in delivery map, airtime-aware SOS.
- **Build first:** SQLite message store, then ship #124–#129 as beta.5.
- **Don't build:** voice/photos/AR over LoRa, gamified node collecting, paywalls or accounts.
- **Five actions now:**
  1. Merge #124–#129 in order (retarget #128 first) and publish beta.5.
  2. Start the SQLite message store with a migration test from a real export.
  3. Add hop count + path card to messages.
  4. Add a firmware version gate.
  5. Run the device checklist on a second, non-T1000-E radio and commit the result.
