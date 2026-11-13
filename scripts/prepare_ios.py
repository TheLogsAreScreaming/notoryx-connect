"""Run after `flutter create --platforms=ios .` to brand the app and add the
permissions NOTORYX Connect needs on iOS. Idempotent."""
import plistlib
import re
from pathlib import Path

RUNNER = Path('ios/Runner')
BUNDLE_ID = 'com.bastionmesh.connect'

project = Path('ios/Runner.xcodeproj/project.pbxproj')
text, count = re.subn(r'PRODUCT_BUNDLE_IDENTIFIER = com\.bastionmesh\.bastion;',
                      f'PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};', project.read_text())
if count == 0:
    raise SystemExit('Could not set PRODUCT_BUNDLE_IDENTIFIER')
project.write_text(text)

podfile = Path('ios/Podfile')
podfile.write_text(re.sub(r"^#? *platform :ios, '[0-9.]+'", "platform :ios, '15.0'",
                          podfile.read_text(), flags=re.M))

with (RUNNER / 'Info.plist').open('rb') as f:
    plist = plistlib.load(f)
plist.update({
    'CFBundleDisplayName': 'NOTORYX Connect',
    'CFBundleName': 'NOTORYX Connect',
    # Languages the app is translated into. Without this list iOS and macOS
    # tell the app the phone is in English whatever its language.
    'CFBundleLocalizations': ['en', 'es', 'fr', 'de'],
    'NSBluetoothAlwaysUsageDescription':
        'NOTORYX Connect uses Bluetooth to connect to your LoRa mesh radio.',
    'NSFaceIDUsageDescription':
        'NOTORYX Connect uses Face ID for the optional app lock.',
    'NSCameraUsageDescription':
        'NOTORYX Connect uses the camera only to scan channel QR codes you choose to scan.',
    'NSLocationWhenInUseUsageDescription':
        'NOTORYX Connect uses your location only if you turn on location sharing.',
    'NSLocalNetworkUsageDescription':
        'NOTORYX Connect connects to radios on your Wi-Fi network if you ask it to.',
    # Lets the radio link continue while the app is in the background.
    'UIBackgroundModes': ['bluetooth-central'],
})
with (RUNNER / 'Info.plist').open('wb') as f:
    plistlib.dump(plist, f)
