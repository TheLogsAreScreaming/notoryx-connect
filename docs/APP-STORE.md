# App Store guide for NOTORYX Connect

What is needed to get NOTORYX Connect onto Apple's App Store. Nothing here has been submitted. Items marked **Owner** need your account, money or legal decision.

## 1. Resolve first: the GPL (Owner)

NOTORYX Connect is GPL-3.0 and includes GPL-3.0 Meshtastic® protobuf code (`lib/generated/meshtastic`). App Store terms add usage restrictions that are widely held to conflict with the GPL. Apps have been removed over this, VLC being the best-known case.

Before paying for anything, have a lawyer answer:

- Who holds copyright in each GPL part of this app, including the code this project grew from?
- Can every holder grant permission for App Store distribution, or can that code be replaced? Generated protobufs are not the app's own code to relicense.
- Would a GPL "additional permission" from all holders be enough?

This guide is a technical checklist, not legal advice. NOTORYX Core Independent is MIT-licensed, so it may be an easier first App Store release.

## 2. Accounts and secrets (Owner)

- [ ] Join the Apple Developer Program ($99 a year).
- [ ] Register bundle ID `com.bastionmesh.connect` and create the app in App Store Connect.
- [ ] Create an App Store Connect API key with the **Admin** role.
- [ ] Add repository secrets: `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` (`base64 -i AuthKey_XXXX.p8`).
- [ ] Run **NOTORYX iOS TestFlight** from main. No Xcode is needed on your Mac.

The build number comes from `pubspec.yaml`, and each upload needs a new one.

## 3. What is different on iOS

| Feature | iOS |
|---|---|
| Bluetooth radios | Yes, with `bluetooth-central` background mode |
| Wi-Fi radios | Yes |
| USB radios | Hidden, not supported |
| Message and field alerts | Yes, from this change; asks permission at launch |
| Background connection | iOS decides how long it lasts; no foreground service as on Android |
| Battery settings card, home widget | Hidden |
| SMS relay, ATAK feed | Not on iOS |

Connect has never been run on a real iPhone. Before submitting, test on one with a radio: connect, send and receive, lock the phone for 15 minutes, check an alert arrives, Face ID lock, encrypted history, QR scan and the map.

## 4. Review notes for Apple (paste into App Review Information)

> NOTORYX Connect talks to LoRa mesh radios over Bluetooth, and needs that hardware for full use. To review without a radio, open Settings and turn on **Demo mode**, or tap the demo option on Home. It simulates a radio and mesh. Nothing is sent. No account or login is needed.
>
> Bluetooth runs in the background so messages keep arriving while the phone is locked. Location is used only if the person turns on location sharing or coverage recording. The camera is used only to scan channel QR codes.
>
> NOTORYX Connect is an independent project and is not affiliated with Meshtastic LLC.

Check that those demo steps still match the app when you submit.

## 5. Listing draft

Follows [TRADEMARKS.md](../TRADEMARKS.md): "Meshtastic" stays out of the name, subtitle and icon, and appears only as a compatibility statement.

- **Name:** NOTORYX Connect
- **Subtitle:** Off-grid LoRa mesh messaging
- **Category:** Communication; secondary Navigation
- **Keywords:** lora,mesh,off-grid,radio,messaging,hiking,offline,emergency,backcountry,node (leave "Meshtastic" out)
- **Description, first lines:** Message and map your team with LoRa mesh radios, with no cell service, account or subscription. Compatible with radios running Meshtastic® firmware.
- **Description, last lines:** Meshtastic® is a registered trademark of Meshtastic LLC. Meshtastic software components are released under various licenses, see GitHub for details. No warranty is provided - use at your own risk. NOTORYX Connect is independent and is not affiliated with or endorsed by Meshtastic LLC.

Avoid claims that the app is an emergency service or guarantees delivery. Re-check the [current trademark rules](https://meshtastic.org/docs/legal/licensing-and-trademark/) before submitting, and finish the name clearance tracked in issue 55.

## 6. App Store Connect answers (Owner to confirm)

- **Privacy policy URL:** required. `PRIVACY-POLICY.md` still has placeholders and says "Android app", so update it first.
- **App privacy:** drafted answer is "Data Not Collected", since the publisher runs no server and receives nothing. Map tiles, terrain lookups and MQTT go to third parties at the user's request, so confirm this against Apple's definitions.
- **Encryption:** the app uses AES for channels, backups and chat history. Apple asks about this at upload, and the answer can involve US export rules, so `ITSAppUsesNonExemptEncryption` is deliberately left unset.
- **Age rating:** user-generated content between users; answer the questionnaire honestly.
- **Screenshots (Owner):** 6.9-inch iPhone at minimum, and iPad only if iPad remains a supported device.
