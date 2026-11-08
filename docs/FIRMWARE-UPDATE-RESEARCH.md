# In-app firmware update: research and recommendation

Status: research only. No code writes firmware. Roadmap item P3.

## Recommendation

Don't build in-app flashing for 1.0. Keep the current path: the firmware check warns and points to the Meshtastic web flasher. Revisit once real-radio testing has a hardware matrix.

A failed flash can leave someone without a radio, in an app whose purpose includes calling for help. The official apps already cover this job for the boards where it's safe.

## What's known

| Topic | Finding | Source |
|---|---|---|
| nRF52 over Bluetooth | Official Android and iOS apps can update OTA-capable nRF52 boards. The entry appears only for capable devices. | [nRF52 OTA docs](https://meshtastic.org/docs/getting-started/flashing-firmware/nrf52/ota/) |
| Nordic DFU app version | The docs warn that a current Android nRF DFU release isn't compatible, and point to an older nRF Connect release. Tool versions matter. | Same |
| Update flow | Phone downloads the matching binary, radio enters DFU mode, firmware transfers over Bluetooth. | [Apple firmware docs](https://meshtastic.org/docs/software/apple/user/firmware/) |
| Failure handling | App should stay in the foreground and in range. A radio that looks bricked can usually be recovered with the flasher on a computer. | Same |
| ESP32 from a phone | No official source found confirming Wi-Fi OTA from the phone app. A Bluetooth prototype exists but is unofficial. | [Prototype](https://github.com/garthvh/Meshtastic-Flasher-OTA-ESP32) |

## If it's built later

1. **nRF52 only at first.** It's the documented path, and bootloader recovery exists.
2. **Allowlist boards**, never infer. Match the exact hardware model to the exact firmware file; a wrong binary is the main brick risk.
3. **Only official release files**, checked against a published hash before transfer.
4. **Preconditions:** radio battery over 50%, Bluetooth link healthy, app in the foreground, no active trip or SOS.
5. **Back up first:** offer the radio config backup, since an update may reset settings.
6. **Warn plainly** and link to computer recovery before starting.

## Still to find out

- Which boards the team can actually test, including one to deliberately fail on.
- The current ESP32 OTA mechanism in firmware 2.7+ and whether it needs a separate loader.
- Whether a maintained Flutter DFU plugin works with Meshtastic's bootloaders. The Nordic version note above suggests testing is essential.
