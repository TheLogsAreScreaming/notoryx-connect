import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bastion/backdrop_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_backdrop.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:bastion/theme/nx_backdrop.dart';
import 'package:bastion/theme/nx_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/shell_nav.dart';

class _Photos implements BackdropPhotos {
  _Photos(this.bytes);
  final Uint8List? bytes;
  int picks = 0;
  @override
  Future<Uint8List?> pick() async {
    picks++;
    return bytes;
  }
}

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = Colors.teal);
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Widget _app(Widget home) => MaterialApp(
      theme: NotoryxTheme.fromPalette(BastionTheme.blaze.palette),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('BackdropStyle', () {
    test('round-trips through its saved form', () {
      const style = BackdropStyle(kind: BackdropKind.mesh, color1: 0xFF112233, color2: 0xFF445566, dim: 0.6, blur: 12);
      expect(BackdropStyle.fromJson(style.toJson()), style);
    });

    test('keeps dim and blur in range, so text stays readable', () {
      final s = const BackdropStyle().copyWith(dim: 0, blur: 500);
      expect(s.dim, BackdropStyle.minDim);
      expect(s.blur, BackdropStyle.maxBlur);
      expect(const BackdropStyle().copyWith(dim: 5).dim, BackdropStyle.maxDim);
    });

    test('anything unreadable falls back to the theme glow', () {
      expect(BackdropStyle.fromJson('nonsense'), const BackdropStyle());
      expect(BackdropStyle.fromJson({'kind': 'lava', 'dim': 'x'}).kind, BackdropKind.theme);
    });
  });

  group('BastionBackdrop', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('bastion-backdrop-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('saves the style and reads it back', () async {
      final a = BastionBackdrop(folder: dir);
      await a.setStyle(const BackdropStyle(kind: BackdropKind.linear, color1: 0xFF0B1F3A));
      final b = BastionBackdrop(folder: dir);
      await b.load();
      expect(b.style.kind, BackdropKind.linear);
      expect(b.style.color1, 0xFF0B1F3A);
    });

    test('a photo setting whose file is gone shows the theme instead', () async {
      await BastionBackdrop(folder: dir).setStyle(const BackdropStyle(kind: BackdropKind.photo));
      final b = BastionBackdrop(folder: dir);
      await b.load();
      expect(b.style.kind, BackdropKind.theme);
    });

    testWidgets('a photo is shrunk, saved, survives a restart and is deleted on reset', (tester) async {
      await tester.runAsync(() async {
        final a = BastionBackdrop(folder: dir);
        expect(await a.setPhoto(await _png(3200, 800)), isTrue);
        expect(a.style.kind, BackdropKind.photo);
        final saved = File('${dir.path}/${BastionBackdrop.photoFileName}');
        expect(saved.existsSync(), isTrue);
        final codec = await ui.instantiateImageCodec(saved.readAsBytesSync());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, BastionBackdrop.photoMaxSide);
        expect(frame.image.height, 400);

        final b = BastionBackdrop(folder: dir);
        await b.load();
        expect(b.style.kind, BackdropKind.photo);
        expect(b.photo, isNotNull);

        await b.reset();
        expect(b.style, const BackdropStyle());
        expect(saved.existsSync(), isFalse);
      });
    });

    test('a file that is not a picture is refused and changes nothing', () async {
      final a = BastionBackdrop(folder: dir);
      expect(await a.setPhoto(Uint8List.fromList(List.filled(64, 7))), isFalse);
      expect(await a.setPhoto(Uint8List(0)), isFalse);
      expect(a.style.kind, BackdropKind.theme);
    });
  });

  test('cards are see-through glass that keeps most of the page colour', () {
    for (final t in BastionTheme.values) {
      final theme = NotoryxTheme.fromPalette(t.palette);
      final card = theme.cardTheme.color!;
      expect(card.a, closeTo(NotoryxTheme.glassOpacity, 0.01), reason: t.id);
      expect(theme.extension<NxGlow>(), isNotNull, reason: t.id);
    }
  });

  group('Background page', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('bastion-backdrop-page-'));
    tearDown(() => dir.deleteSync(recursive: true));

    testWidgets('choosing a gradient shows both color rows, and reset goes back to the theme', (tester) async {
      final store = BastionBackdrop(folder: dir);
      await tester.pumpWidget(_app(BackdropPage(store: store)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bg-preview')), findsOneWidget);
      expect(find.text('First color'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('bg-kind-linear')));
      await tester.pumpAndSettle();
      expect(store.style.kind, BackdropKind.linear);
      expect(find.text('First color'), findsOneWidget);
      expect(find.text('Second color'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Color 3').first);
      await tester.pumpAndSettle();
      expect(store.style.color1, BackdropColours.all[2]);

      await tester.scrollUntilVisible(find.byKey(const ValueKey('bg-reset')), 200);
      await tester.tap(find.byKey(const ValueKey('bg-reset')));
      // Reset deletes any photo file, which needs real time.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(store.style, const BackdropStyle());
    });

    testWidgets('a picture that cannot be used says so and keeps the old background', (tester) async {
      final store = BastionBackdrop(folder: dir);
      final photos = _Photos(Uint8List.fromList(List.filled(32, 1)));
      await tester.pumpWidget(_app(BackdropPage(store: store, photos: photos)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bg-kind-photo')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pumpAndSettle();
      expect(photos.picks, 1);
      expect(find.text("Couldn't use that photo. Try a different one."), findsOneWidget);
      expect(store.style.kind, BackdropKind.theme);
    });

    testWidgets('cancelling the picker changes nothing', (tester) async {
      final store = BastionBackdrop(folder: dir);
      await tester.pumpWidget(_app(BackdropPage(store: store, photos: _Photos(null))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bg-kind-photo')));
      await tester.pumpAndSettle();
      expect(store.style.kind, BackdropKind.theme);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('five-tab bar', () {
    testWidgets('Home, Chats, Nodes, Map and More, in that order', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const BastionApp());
      await tester.pumpAndSettle();
      final labels = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((d) => d.label)
          .toList();
      expect(labels, ['Home', 'Chats', 'Nodes', 'Map', 'More']);
      expect(find.byType(NxBackdrop), findsOneWidget);
    });

    testWidgets('More remembers whether Tools or Settings was open', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const BastionApp());
      await tester.pumpAndSettle();
      await openTools(tester);
      expect(find.text('Connection doctor'), findsOneWidget);

      await openSettings(tester);
      expect(find.text('Your radio, how the app behaves, and your data.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.hub_outlined).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_horiz).last);
      await tester.pumpAndSettle();
      expect(find.text('Your radio, how the app behaves, and your data.'), findsOneWidget,
          reason: 'More opens on the side used last');
    });

    testWidgets('Settings lists the Background page', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const BastionApp());
      await tester.pumpAndSettle();
      await openSettings(tester);
      await tester.scrollUntilVisible(find.text('Appearance & dashboard'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Appearance & dashboard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appearance & dashboard'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const ValueKey('settings-background')), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Theme glow'), findsOneWidget);
    });
  });
}
