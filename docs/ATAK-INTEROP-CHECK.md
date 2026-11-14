# ATAK interoperability check

NOTORYX Connect's TAK bridge talks to an ATAK app **on the same phone**, over loopback. It is not the official ATAK plugin, and it never retransmits TAK traffic over the mesh by default. This sheet checks that boundary with a real ATAK install. Mark each row **Pass**, **Fail** (what happened) or **Not tried**.

| | |
|---|---|
| Build tag + APK SHA-256 | |
| Phone + Android | |
| ATAK version | |
| Radio + firmware | |

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Turn on the TAK bridge: consent screen first, nothing shared before accepting | | |
| 2 | Mesh node positions appear in ATAK with the right names and places | | |
| 3 | Moving node updates in ATAK; old positions go stale and disappear after their expiry | | |
| 4 | A marker placed in ATAK appears on the Connect map | | |
| 5 | Connect's own position sent to ATAK isn't echoed back into Connect as a second marker | | |
| 6 | Nothing is transmitted over the mesh because of ATAK traffic (watch the radio's TX count) | | |
| 7 | Oversized or malformed CoT from ATAK is ignored without a crash | | |
| 8 | Many markers (50+) don't freeze either app | | |
| 9 | Turning the bridge off stops all sharing straight away | | |

Write down what doesn't work as people would expect from the official plugin. Full plugin parity (mesh transport, airtime budget) is a separate decision.
