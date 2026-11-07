# NOTORYX Connect: master feature comparison matrix

Researched 2026-11-07 (NOTORYX Connect `main` b0d3643; open PRs #124–#129 marked O). Machine-readable copy: [`feature_matrix.json`](feature_matrix.json).

## How to read this

- NX cells come from reading NOTORYX Connect source on `main`. A competitor cell is only I/S/F/M when a primary source (release notes, README, store listing, issue tracker) says so; otherwise it is U. U never means "missing".
- S/F on NX means clearly better/worse than the best competitor we could verify, not better than all of them.
- No competitor app was installed and tested hands-on for this report.

| Code | Meaning |
|---|---|
| I | Implemented |
| P | Partial |
| M | Missing |
| S | Superior |
| F | Inferior |
| U | Unverified |
| NA | Not applicable |
| O | In open PR |

**Apps:** **NX** = NOTORYX Connect (main b0d3643); **MA** = Meshtastic Android v2.8.3 (also desktop); **MI** = Meshtastic Apple v2.7.27; **MW** = Meshtastic Web v2.7.2; **SM** = Socialmesh v1.77.0; **MV** = MeshWave 1.1.4 (iOS)

**NOTORYX Connect (main b0d3643) totals (60 rows):** 29 implemented, 10 missing, 8 superior, 6 in open pr, 5 partial, 1 inferior, 1 unverified

## Messaging

| Feature | NX | MA | MI | MW | SM | MV | Evidence / note |
|---|---|---|---|---|---|---|---|
| Channel and direct messages | I | I | I | I | I | I | `meshtastic_messaging_service.dart` |
| Delivery state from routing ACK | I | I | I | I | U | I | `want_ack` in `meshtastic_mesh_tools.dart`; MeshWave lists "delivery confirmation" |
| Resend a failed message in place | P | I | U | U | U | U | NX: offline queue resends on reconnect; MA v2.8.3 "failed messages resend in place" |
| Offline queue (send when radio returns) | I | U | U | U | U | U | README "Offline queue" |
| Message search | I | I | U | U | U | U | `bastion_message_search.dart` |
| Reactions, drafts per thread | I | I | I | U | I | U | `bastion_chat_message.dart`; MA v2.8.3 reaction notification channel |
| RF vs MQTT origin label | I | I | I | U | U | U | `viaMqtt`; requested in MA #896 (14 👍) and MI #1546 |
| Hop count shown on a message | M | I | I | U | U | U | No hop field in `bastion_chat_message.dart`; MA #922 (19 👍) closed; MI #1611 |
| Ignore / mute / word filters | I | U | U | U | U | U | `bastion_filters.dart`; SOS from a trip contact bypasses ignore |
| Pins, @mentions, unread markers | I | U | U | U | U | U | PR #122 merged |
| Bot / away reply with loop protection | S | M | M | M | U | M | `bastion_bot_guard.dart`, `bastion_bot_rules.dart` |
| Read new messages aloud | I | U | U | M | U | U | `bastion_speech.dart` (flutter_tts) |
| PKI key display / key-mismatch warning | M | U | U | U | U | U | No public-key handling in `lib/` outside generated protobufs |
| Message storage engine | F | S | S | U | U | U | NX keeps chats as JSON in SharedPreferences (`bastion_message_archive.dart:76`); MA has an app database with backup/restore (v2.8.3) |

## Safety and field

| Feature | NX | MA | MI | MW | SM | MV | Evidence / note |
|---|---|---|---|---|---|---|---|
| Trip plan, overdue alert, check-in | S | M | M | M | U | U | `bastion_trip.dart`, `bastion_field_checkin.dart` |
| SOS that repeats until answered | S | M | M | M | P | P | NX: 5 min × 12, stops on reply; SM "one-tap SOS broadcast"; MV lists emergency messages |
| Geofence alerts | I | U | U | M | I | I | `bastion_geofences.dart`; SM README; MV "MeshFence" |
| Low-battery / node-quiet alerts | I | U | U | U | I | U | `bastion_field_alerts.dart` |
| Incident log and coverage records (CSV) | S | M | M | M | U | U | `bastion_field_log.dart` |
| Deployment checklist, runtime estimate | S | M | M | M | U | U | `field_tools_page.dart` |

## Mesh networking and diagnostics

| Feature | NX | MA | MI | MW | SM | MV | Evidence / note |
|---|---|---|---|---|---|---|---|
| Node list, favourites, notes | I | I | I | I | I | U | `bastion_nodedex.dart` |
| Filter nodes/map by last heard | U | I | I | U | U | U | MA #1714, MI #1126 |
| Traceroute with SNR per hop | I | I | I | I | I | U | `traceroute_page.dart` |
| Traceroute drawn on the map | O | U | U | U | U | U | PR #125 |
| Neighbour info | I | U | U | U | U | U | `node_detail_page.dart:425` |
| Telemetry history charts | I | I | I | U | U | U | `telemetry_chart.dart` (PR #121) |
| Mesh health / airtime view | O | P | P | U | I | U | PR #126; SM README "packets, hops and airtime" |
| Range test, store-and-forward tools | I | I | I | U | U | U | `mesh_tools_page.dart` |
| Network monitor dashboard (desktop) | M | P | U | P | U | M | MeshSense v1.0.18 (desktop, last release 2025-01-22) and MeshMonitor v4.17.2 (server) are the specialists |

## Mapping and location

| Feature | NX | MA | MI | MW | SM | MV | Evidence / note |
|---|---|---|---|---|---|---|---|
| Map with nodes and waypoints | I | I | I | I | I | I | `map_page.dart` |
| Offline map tiles | P | U | U | U | U | I | NX caches viewed OSM tiles for a year (`bastion_tile_cache.dart`); no area download |
| Team view (distance, bearing, freshness) | S | M | M | M | I | U | Trip contacts only; SM "Team Coordination" |
| Trails and GPX export | I | U | U | U | U | I | `bastion_trails.dart`, `bastion_gpx.dart`; MV "route history" |
| Rally points and shared routes | O | M | M | M | U | U | PR #127 |
| Terrain / link planner | O | I | U | U | U | P | PR #128; MA v2.8.3 "Site Planner coverage runs on the phone"; MV rangefinder |
| Position rounding for privacy | I | I | I | U | U | U | `bastion_phone_position.dart` |

## Device connectivity

| Feature | NX | MA | MI | MW | SM | MV | Evidence / note |
|---|---|---|---|---|---|---|---|
| Bluetooth LE | I | I | I | I | I | I | `meshtastic_radio_transport.dart` |
| Wi-Fi / TCP | O | I | I | I | U | M | PR #129; MI #296 (26 👍, closed) |
| USB serial | M | I | U | I | I | M | Transport interface is ready ("future USB", `meshtastic_radio_session.dart:10`) |
| Auto-reconnect with backoff | I | I | P | P | U | U | `bastion_reconnect_supervisor.dart`; MI #1533 "stuck in connecting"; MW #164 |
| Background link (foreground service) | I | I | U | NA | U | U | `bastion_background_service.dart` + battery-optimisation card |
| Several radios, per-radio history | I | U | U | U | U | U | README "kept separately for each radio" |
| Firmware update | M | I | U | U | U | M | MA v2.8.3 bootloader check + DFU reboot |

## Radio management

| Feature | NX | MA | MI | MW | SM | MV | Evidence / note |
|---|---|---|---|---|---|---|---|
| Edit every config section and module | I | I | I | I | I | U | `proto_form.dart` generated forms |
| Read-back verification after each save | S | U | U | U | U | U | `bastion_settings_verifier.dart` |
| Remote admin of other nodes | M | I | I | U | U | U | NX admin targets `localNodeNum` only (`meshtastic_admin_session.dart:168`); MI #2498 |
| Channel links and QR import/export | I | I | I | I | I | U | `bastion_channel_import.dart` |
| Encrypted radio-config backup | S | P | U | M | U | U | AES-256-GCM, PBKDF2 600k; MW #247 asks for config backup (12 👍, open) |
| Encrypted phone-data backup | I | I | U | M | U | U | MA v2.8.3 database backup/restore |
| MQTT client proxy (phone as uplink) | M | I | I | U | U | U | Only the proto enum exists in NX (`meshtastic_phoneapi_codec.dart:7`); MI #2572 |

## UI/UX, accessibility and platform

| Feature | NX | MA | MI | MW | SM | MV | Evidence / note |
|---|---|---|---|---|---|---|---|
| Light / dark / system themes | I | I | I | I | S | U | `lib/theme/notoryx_theme.dart`; SM sells theme packs |
| Large-text resilient layouts | I | U | U | F | U | U | `bastion_accessibility_test.dart`; MW #666 mobile responsiveness (open) |
| Screen-reader labels | P | U | U | U | U | U | `Semantics(` in 8 files |
| Translations | M | I | I | U | U | U | No l10n in NX; MI #2742 (Polish) |
| Demo mode without a radio | O | I | U | U | U | U | PR #124; MA v2.8.3 showcase scenario |
| Home-screen widgets / shortcuts | P | I | U | NA | I | U | NX has app-icon shortcuts only; MA #745 widgets |
| Car (Android Auto / CarPlay) | M | I | M | NA | U | U | MA v2.8.3 Android Auto messaging; MI #231 |
| iOS build | M | NA | I | NA | I | I | NX is Android-only today |
| Desktop build | P | I | I | I | U | M | NX macOS workflow exists, not released |
| Open source | I | I | I | I | I | M | NX GPL-3.0 |
