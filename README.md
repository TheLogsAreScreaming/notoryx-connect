<p align="center">
  <img src="branding/notoryx-icon.png" width="120" alt="NOTORYX app icon">
</p>

# NOTORYX Connect

Part of the **NOTORYX** off-grid communications family. **No Towers. No Limits.**

**An independent Android field app for LoRa mesh radios running Meshtastic® firmware.**

NOTORYX Connect pairs your phone with a radio over Bluetooth so you can message, map and manage the mesh without cell service. It interoperates with Meshtastic® firmware while keeping its own name, icon, interface and project identity.

> **Independent project:** NOTORYX Connect (formerly Bastion) is not affiliated with, sponsored by, endorsed by, or an official application of Meshtastic LLC.

<p align="center">
  <img src="docs/screenshots/home.png" width="200" alt="Home tab: field console with the demo radio connected, check-in and hold for SOS">
  <img src="docs/screenshots/nodes.png" width="200" alt="Nodes tab: the demo mesh's node list with last-heard and favorites filters">
  <img src="docs/screenshots/chats.png" width="200" alt="Chats: new message with channel picker, Send later and quick replies">
  <img src="docs/screenshots/tools.png" width="200" alt="Tools: connection doctor, timeline, checklists and automations">
</p>
<p align="center">
  <img src="docs/screenshots/trip.png" width="200" alt="Plan your trip: contacts, overdue alert and check-in reminder">
  <img src="docs/screenshots/beacons.png" width="200" alt="Mesh beacons heard, and sending one by hand">
  <img src="docs/screenshots/field_records.png" width="200" alt="Field records: incident log, templates, coverage and bot safeguards">
  <img src="docs/screenshots/settings.png" width="200" alt="Settings: themes, language, units, privacy and backups">
</p>
<p align="center">
  <img src="docs/screenshots/privacy.png" width="200" alt="Privacy and data: what's stored and what's sent">
  <img src="docs/screenshots/radio_backup.png" width="200" alt="Encrypted radio backup">
  <img src="docs/screenshots/home_light.png" width="200" alt="Home tab in the light Bare Beauty theme">
  <img src="docs/screenshots/nodes_light.png" width="200" alt="Nodes tab in the light Bare Beauty theme">
</p>

<sub>Screenshots are rendered from the app's built-in demo mode (a pretend radio and mesh), not a live radio.</sub>

> **Status (2026-11-15):** the latest release is **v1.0.0-beta.17** (version 1.0.0, build 21). It is a test beta. Beta.16 and beta.17 were checked on one phone (a Samsung Galaxy A15) with one radio (a Seeed T1000-E running Meshtastic firmware). Many features (USB, Wi-Fi, two-way ATAK, MQTT proxy, remote admin, offline map files, Windows and macOS builds) have automated tests but have not yet been checked on a range of phones, radios and firmware versions. Don't rely on it as your only way to call for help. Please [report issues](../../issues).

## Download

Get the latest beta from **[NOTORYX Connect releases](https://github.com/TheLogsAreScreaming/notoryx-connect-releases/releases)**. Betas are marked as pre-releases. Each release lists what changed and includes checksum files for checking your download.

| Platform | File | Notes |
|---|---|---|
| Android (ARM64 phones) | `NOTORYX-Connect-<version>-<build>.apk` | Signed with the release key. Checksums in `SHA256SUMS.txt`, signing details in `SIGNATURE.txt` |
| macOS (Intel and Apple silicon) | `NOTORYX-Connect-<version>-<build>-macOS-universal.zip` | Not notarized: right-click the app and choose **Open** the first time |
| Windows (64-bit) | `NOTORYX-Connect-<version>-<build>-Windows-x64-setup.exe` or `-Windows-x64.zip` | Installs for your user, no admin needed. Not code signed, so SmartScreen warns on first launch |
| Google Play | `NOTORYX-Connect-<version>-<build>.aab` | For the Play Console, not for installing directly |

iOS is built in CI (unsigned) but isn't released. App Store distribution waits on an Apple developer account and a GPL licensing question; see [docs/APP-STORE.md](docs/APP-STORE.md).

### Install on Android

1. On your phone, open the release and download the `.apk`.
2. Open the file. If Android asks, allow installs from your browser or file manager.
3. Open NOTORYX Connect and allow **Bluetooth**, **location** and **notifications** when asked.
4. For a steady background link, set the app's battery use to **Unrestricted** (**Settings → Background connection** shows how).

Newer betas install over older ones and keep your data. Don't uninstall first.

**Upgrading from v0.1.3-beta.1 or earlier:** the app ID changed from `org.backcountrysignal.bastion` to `com.bastionmesh.connect`, so the new app installs separately instead of updating the old one. Make a backup in the old app (**Settings → Phone data backup / restore**), install the new app, restore the backup there, then uninstall the old app. You only do this once.

## Getting started

1. **No radio yet?** On **Home**, tap **Try the demo** to explore the app with a pretend radio and mesh. Nothing is sent and your own data is left alone.
2. **Connect your radio.** On **Home**, tap **Connect radio**, or on **Nodes**, scan and tap **Connect**. Bluetooth, Wi-Fi (TCP port 4403) and USB (OTG cable) are supported. NOTORYX Connect checks the Meshtastic service, runs the PhoneAPI handshake and syncs the node list before it marks the session ready, and reconnects on its own if the link drops. If something goes wrong, **Tools → Connection doctor** walks through the likely causes.
3. **Send a message.** On **Chats**, pick a channel or a node and send. Messages typed while you're offline are queued and sent when the radio is back.
4. **Check your radio's settings.** **Settings → Radio configuration** shows the node's identity, LoRa settings, channels and modules. Every change is read back from the radio to confirm it saved.
5. **Plan your trip.** On **Home**, add up to 6 trip contacts and run **Trip readiness**. **Check in** sends them your status, position and battery, and **Hold for SOS** repeats a call for help until one of them answers.

## Features

### Trip safety
- **Field console** with radio status, node count and battery, plus a home-screen widget and a Quick Settings tile.
- **Plan your trip:** up to 6 trip contacts, an overdue alert, a check-in reminder, and a trip plan you can share.
- **Trip readiness** check before you leave: radio, battery, firmware, channels, SOS channel, position, background limits and when each trip contact was last heard.
- **Check in** with one tap (I'm OK, At camp, Delayed, Heading back). It goes to every trip contact as a direct message with time, position and battery, and the **check-in delivery map** shows who it reached.
- **Hold for SOS** sends to your trip contacts and optionally a channel, repeats while respecting the channel's airtime, stops when a contact answers, and **I'm safe** sends an all-clear.
- **Team view:** each trip contact's freshness, distance, direction and battery, 24-hour trails, **day replay** of team positions, **zone alerts** when people arrive or leave, and **off-route alerts**.

### Messaging
- Channel and direct messages with delivery receipts that say whether the radio proved delivery, and hop count, signal and relay on each message.
- Offline queue, **forward** and **send later**, a draft kept for each conversation, and an airtime estimate while you type.
- Emoji reactions (tap a message), replies, @mentions, pinned messages, unread markers and date dividers.
- Search across all saved messages. Chat history is kept in an on-phone database, separately for each radio, and can be **encrypted**.
- Reply from the notification. **Ignore** or **mute** nodes, hide words you choose, and get a warning when a node's name looks like another's. An SOS reply from a trip contact is never missed.
- **SALUTE** and **9-Line** report forms, check-in and assistance templates, and **Bot Mode** with quiet hours, rate limits and loop protection.
- Optional **community moderation** (off by default): report spam, see a Flagged label on banned nodes, and appeal a ban on your own node.

### Nodes and maps
- **NodeVault:** every node your radios have heard, with favorites, a favorites-only filter, a **node journal** (notes and tags), telemetry charts, signal history, neighbors and node-key change alerts.
- **Traceroute** with SNR for each hop, shown on the map, plus a **network diagram** and **mesh health** (channel use and airtime).
- Map with node positions, waypoints, rally points and routes, a coverage heatmap, and nodes your radio has forgotten. The map can also be read as a list for screen readers.
- **Place search**, a **topo map** and a line-of-sight **link planner** (Open-Meteo elevation).
- **Map layers** from GPX, KML or GeoJSON, **offline maps** from an MBTiles file, and GPX export of waypoints and trails. OpenStreetMap areas you've viewed stay cached offline.
- **Mesh beacons** (which can carry a Plus Code) and **local mesh discovery**.
- Opt-in phone GPS sharing, with position precision set for each channel.

### Radio management
- Connect over **Bluetooth**, **Wi-Fi** or **USB**, with a firmware version check, saved radios and a Disconnect button.
- Every config section and module can be edited through a generated form. Settings the radio can't use are greyed out with the reason, and every save is verified with a fresh read from the same radio.
- **Remote admin** of other nodes you hold the admin key for.
- Share and import channels as `meshtastic.org/e/#` links or QR codes.
- **Encrypted radio settings backup** (AES-256-GCM, PBKDF2 with 600,000 iterations), identity key backup, and a checklist for moving to a new radio.

### Field tools and integrations
- Incident log, coverage observations (receiver location, SNR and RSSI), range test, store-and-forward catch-up and CSV export.
- Deployment checklist, offline checklists, battery runtime estimate and an RSSI field reference.
- **Timeline** of messages, new nodes, signal changes and waypoints in one feed, and **automations**: rules that send a message, alert you or change channel when something happens.
- Local alerts on the phone: low battery, new nodes, favorites going quiet, and changes in the mesh.
- **Two-way ATAK** (asks before sharing positions) with map markers, and an **MQTT client proxy**.
- Low-power field mode and a background connection service on Android.

### Privacy, backups and look
- No account, no analytics, no ads and no NOTORYX servers. **Settings → Privacy & data** lists what's stored and sent, and can delete chat history or all phone data.
- Optional **app lock**, and an **encrypted phone data backup** of chats, NodeVault, waypoints, field records and settings.
- Eight themes (Blaze, Neon Anarchy, Tactical, Pink Overload, Bare Beauty, Okabe-Ito, Night Ops and Seasonal) in the NOTORYX Core look, with Inter type and squared cards, and side tabs on tablets.
- In English, Spanish, French and German (follows the phone language; translations are unreviewed). Layouts hold up with large text and screen readers ([accessibility audit](docs/ACCESSIBILITY_AUDIT.md)).

## Safety

NOTORYX Connect may support field and emergency-communications workflows, but software and mesh radio links are not guaranteed emergency lifelines. Keep backup communications and a safety plan suited to where you're going.

## Building from source

Requirements: Flutter 3.47.7, Java 17 and the Android SDK.

```sh
flutter create --no-pub --platforms=android --org com.bastionmesh --project-name bastion .
git checkout -- pubspec.lock   # flutter create replaces it with a template
python3 scripts/prepare_android.py
flutter pub get --enforce-lockfile
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter run
```

CI generates the Android project with the Dart project name `bastion` and organization `com.bastionmesh`. `scripts/prepare_android.py` then sets the application ID to `com.bastionmesh.connect` and adds the Bluetooth, location and notification permissions.

Dependency versions are locked in the committed `pubspec.lock`, and CI runs `flutter pub get --enforce-lockfile`, so every build uses the same packages. To change a dependency, edit `pubspec.yaml`, run plain `flutter pub get`, and commit the updated `pubspec.lock`.

The README screenshots (the main tabs in the Blaze and Bare Beauty themes, plus the trip, beacons, discovery, field records, privacy and backup screens) are rendered by `test/preview/screens_preview_test.dart` with the app's own fonts and the demo radio:

```sh
PREVIEW_OUT=docs/screenshots flutter test test/preview
```

### macOS, Windows and iOS

The **NOTORYX macOS Build** workflow generates the macOS project, applies `scripts/prepare_macos.py` (app name, Bluetooth/camera/location prompts, sandbox entitlements, Impeller off for Intel Macs) and builds a universal Intel + Apple silicon `NOTORYX Connect.app`, zipped as `NOTORYX-Connect-<version>-macOS-universal.zip`. It is ad-hoc signed, not notarized: on first launch, right-click the app and choose **Open**. Android-only features (background connection service, notifications) are inactive on macOS. Bundle ID `com.bastionmesh.connect` is separate from NOTORYX Core (`com.bastionmesh.bastion`), so both apps can be installed side by side.

The **NOTORYX Windows Build** workflow builds a 64-bit Windows app as a per-user installer and a zip. The **NOTORYX iOS Build** workflow builds an unsigned iOS app to check that it compiles; **NOTORYX iOS TestFlight** is ready for when an Apple developer account is set up ([docs/APP-STORE.md](docs/APP-STORE.md)).

### Build validation and releases

Pull requests and pushes run the **NOTORYX Android CI** workflow (Flutter analysis, tests, an ARM64 release APK build and a retained APK artifact) alongside the macOS, Windows and iOS builds. Signed candidates are built by the manual **NOTORYX Signed Release Candidate** workflow from main and published by hand to [notoryx-connect-releases](https://github.com/TheLogsAreScreaming/notoryx-connect-releases/releases). A build isn't production-ready until hardware testing, release signing, dependency and license review, privacy review and release QA are done. See [release readiness](docs/RELEASE-READINESS.md), the [device test checklist](docs/DEVICE-TEST-CHECKLIST.md) and [branch/PR triage](docs/BRANCH-AND-PR-TRIAGE.md).

## App icon and artwork

The NOTORYX Connect icon artwork is in `branding/`:

| File | Use |
|---|---|
| `notoryx-icon-source.png` | Original artwork (1254 px) |
| `notoryx-icon.png` | Launcher icon for older Android versions (1024 px) |
| `notoryx-icon-foreground.png` | Adaptive icon foreground: the N mark on transparency, inside the safe zone, over `#101011` |

Play Store graphics (512 px icon, 1024 × 500 feature graphic) are in `fastlane/metadata/android/en-US/images/`. `python3 tool/make_store_graphics.py` regenerates all of these from the source artwork (needs Pillow).

The icon and NOTORYX Connect visual identity are independent artwork and must not incorporate the official Meshtastic logo unless a future use is separately authorized and complies with the then-current trademark rules.

## Compatibility

NOTORYX Connect implements interoperability with the public protocol used by Meshtastic® firmware. Technical references to Meshtastic® in source code and documentation describe compatibility or protocol behavior; they are not NOTORYX Connect product branding.

NOTORYX Connect does not use “Meshtastic” in its primary or secondary software product name. The official Meshtastic logo is not used as the NOTORYX Connect application icon or primary branding.

## Trademark and licensing notice

Meshtastic® is a registered trademark of Meshtastic LLC. Meshtastic software components are released under various licenses, see GitHub for details. No warranty is provided - use at your own risk.

NOTORYX Connect is independently developed and is not affiliated with, sponsored by, or endorsed by Meshtastic LLC. All Meshtastic® trademarks remain the property of Meshtastic LLC.

Official policy and project information:

- Licensing and trademark rules: https://meshtastic.org/docs/legal/licensing-and-trademark/
- Official website: https://meshtastic.org/
- Official GitHub organization: https://github.com/meshtastic

See [TRADEMARKS.md](TRADEMARKS.md) for NOTORYX Connect's trademark-use rules.

## Upstream software and third-party licenses

Meshtastic software components are released under various licenses. NOTORYX Connect must preserve all applicable license notices, attribution, source-distribution obligations, and other requirements for any upstream component that is actually incorporated into the project.

NOTORYX Connect includes generated protocol bindings from `meshtastic/protobufs` v2.8.2. Its GPL-3.0 license text is preserved in `licenses/meshtastic-protobufs-GPL-3.0.txt`. NOTORYX Connect is licensed under GPL-3.0; see [LICENSE](LICENSE). Keep the generated-code and third-party notices with distributed builds.

Third-party Flutter/Dart dependencies remain subject to their respective licenses.

## Contributing

Testing, bug reports, hardware compatibility reports and feature ideas are welcome. Contributions must preserve NOTORYX Connect's independent branding and comply with [TRADEMARKS.md](TRADEMARKS.md) and all applicable third-party licenses.
