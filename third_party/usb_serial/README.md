# usb_serial (vendored)

Copy of [usb_serial](https://pub.dev/packages/usb_serial) 0.5.2 by Ron Bessems, BSD-3-Clause (see `LICENSE`).

Only `android/build.gradle` is changed: the published one uses `jcenter()` and Android Gradle Plugin 4.1, which current Gradle refuses. The Dart and Java sources are unchanged. Replace this with the pub.dev package if a maintained release fixes the build.
