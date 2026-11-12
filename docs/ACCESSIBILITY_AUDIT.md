# NOTORYX Connect accessibility audit

**Status: first pass, code and automated checks only.** Audited at commit `67a39cf` (`main`, 9 November 2026), after v1.0.0-beta.8.

**No screen reader, switch control or real-phone large-text walk-through has been done yet.** This page reports what the code and automated tests show. It doesn't claim the app is accessible, and it isn't a conformance statement.

## Method

Same method as NOTORYX Core's audit.

| Layer | How | Done? |
|---|---|---|
| 1. Pattern scan | `python3 tool/a11y_scan.py` from the repository root | Yes |
| 2. Automated tests | `test/bastion_accessibility_audit_test.dart` and `test/bastion_accessibility_test.dart` | Yes, for the screens listed below |
| 3. Review of scan results | Reading each flagged place in context | Yes, once |
| 4. Screen reader | TalkBack on Android, VoiceOver on iOS | **Not yet** |
| 5. Large text and display on a phone | Largest system text, bold text, reduce motion, each theme | **Not yet** |
| 6. People who use these tools | Feedback from disabled users | **Not yet** |

The scanner matches text patterns, so a flagged line is a place to look, not a confirmed bug, and an unflagged line isn't proof of correct behaviour.

## Results from the scan

| Check | Found | To review |
|---|---|---|
| Icon buttons without a tooltip | 32 | 0 |
| Floating buttons without a tooltip | 0 | 0 |
| Tap areas (`GestureDetector`) with no nearby label | 4 | 0 |
| `InkWell` with no nearby label or text | 3 | 0 |
| Images with no label | 0 | 0 |

| Pattern | Count | Why it matters |
|---|---|---|
| Text scaling clamped or disabled | 0 | Good: nothing blocks system text size |
| `FittedBox` | 0 | Good: text isn't shrunk to fit |
| `TextOverflow.ellipsis` | 4 in 4 files | Can cut text off; reviewed below |
| Reduce-motion checks | 1 | All animation goes through `NxMotion.of`, which turns it off |
| Bold-text checks | 0 | Whether bold text works hasn't been checked |
| Live regions | 11 in 10 files | Some status changes are announced |
| `Text` not translated | 277 in 30 files | Untranslated screens are English only |

## Screen checks

Flutter's guideline checks for tap target size (48 by 48), labelled tap targets and text contrast, plus layout overflow, ran on a 390 by 844 phone at normal and double text size, in the dark theme, with no radio connected.

Covered: Field records, Privacy, Radio backup, Phone backup, Beacons, Trip, Trip readiness, Local discovery, Mesh tools, Mesh health, Traceroute, Radio settings, Channel share, Channel import and ATAK feed. All pass.

The main tabs have large-text checks in the older test. Contrast for all themes is covered by the theme tests.

**Only what's on screen at load is checked.** Scrolled-off parts, dialogs, sheets and connected-radio states aren't covered, and contrast was measured in one theme on these screens.

## Fixed in this audit

- **Heatmap (beta.10):** when it's on, the map header says in words how many areas are strong, fair and weak, and from how many readings. Screen readers announce it.
- **Reduce motion (beta.10):** already handled. Every animation uses `NxMotion.of`, which returns no motion when the system asks; the first scan missed it because it looked for the wrong capitalisation. The SOS button's 2-second fill is timing for the hold, not decoration, and screen readers get a confirm dialog instead of the hold.

- Trip page dropdowns overflowed the screen with long option text. They now use the full width.

## Reviewed and left as they are

- Waypoint labels on the map and check-in delivery pins cut off long names to fit the map. Waypoint pins have a screen reader label with the full name; check-in pins still need checking on a phone.
- Node names in the chat and link planner dropdowns are shortened on one line.

## Known problems

1. **The map is visual by nature.** Pins are labelled for screen readers, but there's no non-visual way to explore positions apart from the Nodes list.
2. **The heatmap's squares can't be explored one by one.** The header now summarises them in words, but you can't find where a weak area is without looking.
3. **Hold-to-send SOS.** The Home button is a 2-second hold, with a confirm step. Whether it works well with TalkBack and VoiceOver is the most important thing to test.
4. **Reduce motion** is handled in code but hasn't been checked on a phone.
5. **Untranslated screens** stay English, including Field records, Radio settings and backups.

## Next

Do layers 4 and 5 on a real phone using section 10 of `docs/DEVICE-TEST-CHECKLIST.md`, starting with SOS, connecting a radio, sending a message and app lock.
