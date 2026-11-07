# NOTORYX Connect: competitive intelligence report

Researched 2026-11-07 against NOTORYX Connect `main` b0d3643 (after PR #123). Open PRs #124–#129 are counted as "in review", not as shipped. This is a research document: no app code was changed.

Companion files: [FEATURE_MATRIX.md](FEATURE_MATRIX.md) / [feature_matrix.json](feature_matrix.json) (60 rows) and [COMPETITIVE_ROADMAP.md](COMPETITIVE_ROADMAP.md) (weaknesses, roadmap, top 25, scoring, executive summary).

## 0. Method and limits

- **Our app:** read from source. Every NOTORYX claim below points at a file in `lib/`.
- **Competitors:** GitHub repositories (stars, last push, license, latest release via the GitHub API on 2026-11-07), release notes, READMEs, App Store listings and the most-reacted GitHub issues (`sort=reactions`). Reaction counts are a rough signal of demand, not a measure of how many users are affected.
- **Not done:** no competitor app was installed or tested. Google Play reviews and Reddit threads could not be retrieved reliably, so user complaints come from GitHub issues and the few App Store reviews that WebFetch could read. Treat "U" (unverified) in the matrix as unknown, never as "missing".
- **Protocol scope:** this report is Meshtastic-only. MeshCore apps are covered by the NOTORYX Core report (notoryx-core PR 217). The two protocols are not interchangeable, and nothing here assumes a MeshCore feature can be ported as-is.

## 1. Ecosystem map

### 1.1 Direct competitors (phone apps that pair with a Meshtastic radio)

| App | Developer | Platforms | License | Latest verified release | Activity |
|---|---|---|---|---|---|
| **Meshtastic Android** (official) | Meshtastic project | Android, plus a desktop build (Compose) | GPL-3.0 | [v2.8.3, 2026-10-19](https://github.com/meshtastic/Meshtastic-Android/releases/latest) | [1,913★, pushed 2026-11-07](https://github.com/meshtastic/Meshtastic-Android) |
| **Meshtastic Apple** (official) | Meshtastic project | iOS, iPadOS, macOS | GPL-3.0 | [v2.7.27, 2026-11-02](https://github.com/meshtastic/Meshtastic-Apple/releases/latest) | [961★, pushed 2026-11-07](https://github.com/meshtastic/Meshtastic-Apple) |
| **Socialmesh** | Socialmesh Pty Ltd (gotnull) | iOS, Android (Flutter) | GPL-3.0; optional Firebase | tag v1.77.0+222 | [37★, pushed 2026-11-06](https://github.com/gotnull/socialmesh); [App Store](https://apps.apple.com/app/id6742694642) |
| **MeshWave** | Richard Ramos | iPhone | Proprietary, $9.99 Pro | 1.1.4 (App Store, Nov 2026) | [App Store](https://apps.apple.com/app/id6760241031), 3.3★ from 8 ratings |
| **Mesh World** | Meshworld LLC | iPad/iPhone; Meshtastic **and** MeshCore | Proprietary, subscription | 2.0.3 | [App Store](https://apps.apple.com/us/app/mesh-world/id6747457936), 1.7★ from 3 ratings |
| **Kiba Outdoors** | — | Android, iOS | Proprietary | not verified | Mentioned in search results only; not profiled |

### 1.2 Other Meshtastic clients and tools (ideas, not direct rivals)

| Tool | What it is | Status (2026-11-07) |
|---|---|---|
| [Meshtastic Web](https://github.com/meshtastic/web) | Browser client over BLE, USB, HTTP | v2.7.2 (2026-08-09), 875★, 82 open issues |
| [Meshtastic Python CLI](https://github.com/meshtastic/python) | Command-line config and scripting | 2.7.11 (2026-07-17), 166 open issues |
| [contact](https://github.com/pdxlocations/contact) | Terminal (curses) client | 1.7.4 (2026-10-28), 352★ |
| [MeshSense](https://github.com/Affirmatech/MeshSense) | Desktop network monitor | v1.0.18 (2025-01-22); last push 2025-10-23, 104 open issues: slowing down |
| [MeshMonitor](https://github.com/Yeraze/meshmonitor) | Self-hosted web dashboard | v4.17.2 (2026-11-03), 723★, BSD-3 |
| [ATAK plugin](https://github.com/meshtastic/ATAK-Plugin) | TAK integration | 1.1.42 (2026-03-31) |
| [mesh-client](https://github.com/Colorado-Mesh/mesh-client) | Electron desktop for Meshtastic, MeshCore and Reticulum | v6.6.0 (2026-11-03) |
| [Sideband](https://github.com/markqvist/Sideband) | Reticulum/LXMF app (not Meshtastic) | 2.2.0 (2026-10-01), 1,904★ |
| [meshtastic-ios](https://github.com/thepoweroftwo/meshtastic-ios) | Early open-source iOS client | Abandoned (last push 2021-09-23) |

## 2. Competitor profiles

### 2.1 Meshtastic Android (official): the strongest competitor
- **Strengths verified in v2.8.3 notes:** required firmware update path for old radios (bootloader check, nRF DFU reboot), app database backup/restore, failed messages resend in place, separate reaction notifications, radio settings searchable and editable without a radio, on-phone Site Planner coverage, Demo Mode, Android Auto messaging, a desktop build, a remote shell for the DMShell firmware module.
- **Demand signals (top reacted issues, mostly closed = shipped):** hops away (#922, 19 👍), Android Auto (#969), F-Droid (#6), RF-vs-MQTT flag (#896), old-firmware warning (#1031), last-heard filters (#1714), widgets (#745), location-sharing default off (#861).
- **Open weaknesses:** data-usage visibility (#2765), already-paired BT node won't connect (#6685), app-provided nodes with fake 0 SNR/RSSI/hops (#6263), desktop map blank on Windows (#7604). 260 issues mention disconnect/Bluetooth/reconnect over the project's life.
- **What it lacks that Connect has:** trip planning, check-in, repeating SOS, field records, read-back verified saves, an encrypted radio-config backup, bot mode.

### 2.2 Meshtastic Apple (official)
- **Strengths:** the only first-party iOS/macOS client; MQTT client proxy; remote admin (work in progress: #2067, #2498); TCP since #296 (26 👍, the most-reacted issue).
- **Weaknesses:** "stuck in connecting, no way to cancel" (#1533, 14 👍), laggy with many messages (#1040), conversations keyed to channel slot instead of channel identity (#2495), channel send/receive bug (#2587), MQTT proxy zeroes `hop_limit` (#2572).
- **Release cadence:** v2.7.27 on 2026-11-02.

### 2.3 Socialmesh: the closest third-party rival
- Flutter, GPL-3.0, both stores, very active (148 issues filed, pushed 2026-11-06).
- **Breadth:** SOS with GPS, geofence and battery alerts, team coordination, TAK, IFTTT webhooks, MQTT bridge config, full device config including detection sensor and canned messages, 7,000+ RTTTL ringtones, procedural "NodeDex" sigils and social tags. Optional Firebase for cloud sync and social features.
- **Weaknesses:** a reported map decimal bug placing nodes wrong ([chrome-stats review](https://chrome-stats.com/d/com.gotnull.socialmesh)); paid theme/widget packs; a lot of novelty surface (sigils, patina scores).
- **Overlap:** Connect already matched several Socialmesh features (history limit, draggable scroll bars, hardware names; PRs #114–#118).

### 2.4 MeshWave (iOS)
- Push-to-talk voice, photo sharing, AR landmarks, rangefinder, barometric weather, geofences, offline maps; $9.99 Pro with a 14-day trial.
- **Complaints in reviews:** two nodes in one room failing to exchange messages, "finicky connections", scan not finding a node next to the phone (fixed in 1.1.2 per the listing), privacy worry (precise location + device ID collected, not linked to user).
- **Takeaway:** feature-count marketing without diagnostics leaves users blaming the protocol.

### 2.5 Mesh World (iOS, dual protocol)
- Claims first dual Meshtastic + MeshCore client; maps with 3D terrain and offline tiles, AR view, custom MeshCore repeater routing.
- **Complaints:** email required to use the app, subscription billing, Bluetooth-only (no serial/HTTP). 1.7★ from 3 ratings.

### 2.6 Meshtastic Web
- Strong for desktop USB users. Open demand: config backup (#247, 12 👍, open), mobile responsiveness (#666, open), HTTPS connection failures (#1015), remember previous connection (#164).

## 3. Recurring weaknesses across the ecosystem

1. **Connection state is opaque.** "Stuck in connecting" (MI #1533), already-paired node won't connect (MA #6685), "finicky connections" and scan misses (MeshWave reviews). Users can't tell phone, radio or firmware apart as the cause.
2. **Message history doesn't scale.** iOS lag with many messages (MI #1040); Android needed a database backup feature. Connect stores chats as JSON in SharedPreferences, which will hit the same wall.
3. **RF vs internet vs hops is unclear.** MA #896, MA #922, MI #1546, MI #1611 all ask "how did this message reach me?".
4. **Old firmware breaks things silently.** MA #1031, and v2.8.3 now forces an update below 2.5.14.
5. **Config backup is still missing in places** (MW #247 open) and is unencrypted where it exists.
6. **Privacy defaults.** Location sharing on by default (MA #861); data usage invisible (MA #2765); MeshWave and Mesh World collect identifiers or emails.
7. **Paywalls and accounts** (MeshWave Pro, Mesh World subscription and email, Socialmesh paid packs) annoy users of a free, open protocol.
8. **iOS gaps for third parties:** most innovative Android work never reaches iPhone, and the only open-source third-party iOS option besides Socialmesh is abandoned.

## 4. NOTORYX Connect internal audit (summary)

Full detail in [COMPETITIVE_ROADMAP.md §4](COMPETITIVE_ROADMAP.md#4-internal-audit).

- **Size:** ~74.6k Dart lines in `lib/`, of which ~17.2k are hand-written (the rest is generated protobufs in `lib/generated/`); 72 service files; 85 test files with ~370 test cases; 21 CI workflows.
- **Architecture:** a coordinator (`meshtastic_radio_coordinator.dart`, 1,686 lines) over a session/transport split, with services per feature. `lib/main.dart` is 1,957 lines and holds the Nodes, Chats and Tools pages.
- **Ahead of every verified competitor:** trip/check-in/SOS loop, field records, read-back verified config saves, encrypted radio and phone backups, bot guard rails, per-radio history.
- **Behind:** Bluetooth only on `main` (TCP in PR #129, no USB), no firmware update, no remote admin, no MQTT client proxy, no PKI key display, no translations, no iOS build, chats in SharedPreferences.

## 5. Answers in brief

- **Strongest competitor:** Meshtastic Android. It is official, on every Android phone that runs Meshtastic, and now has a desktop build, Android Auto and firmware updates.
- **Closest third-party rival:** Socialmesh, because it is open source, on both stores and very active.
- **Connect's lane:** the trip-safety and field-operations client that proves every setting it writes. Nobody else owns that.
