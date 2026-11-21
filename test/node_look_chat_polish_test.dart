import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bastion/backdrop_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/main.dart';
import 'package:bastion/node_avatar.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_link_preview.dart';
import 'package:bastion/services/bastion_node_looks.dart';
import 'package:bastion/services/bastion_preferences.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:bastion/theme/nx_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Photos implements BackdropPhotos {
  _Photos(this.bytes);
  final Uint8List? bytes;
  @override
  Future<Uint8List?> pick() async => bytes;
}

class _Pages implements LinkPageFetcher {
  _Pages(this.html);
  final String? html;
  int fetches = 0;
  @override
  Future<String?> fetch(Uri uri) async {
    fetches++;
    return html;
  }
}

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = Colors.orange);
  final image = await recorder.endRecording().toImage(w, h);
  return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

Widget _app(Widget home) => MaterialApp(
      theme: NotoryxTheme.fromPalette(BastionTheme.blaze.palette),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );

BastionChatMessage _msg(int id, DateTime at, String text) => BastionChatMessage(
      packetId: id,
      from: 5,
      to: 0xffffffff,
      channel: 0,
      text: text,
      timestamp: at,
      direction: BastionMessageDirection.incoming,
      deliveryState: BastionDeliveryState.received,
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('node looks', () {
    test('a color is saved, read back and cleared', () async {
      final a = BastionNodeLooks();
      await a.setColor(0x1234, NodeLookColors.all[3]);
      final b = BastionNodeLooks();
      await b.load();
      expect(b.lookFor(0x1234)?.color, NodeLookColors.all[3]);
      await b.clear(0x1234);
      final c = BastionNodeLooks();
      await c.load();
      expect(c.lookFor(0x1234), isNull);
    });

    test('unreadable saved looks start fresh', () async {
      await SharedPreferencesAsync().setString(BastionNodeLooks.prefsKey, '{not json');
      final looks = BastionNodeLooks();
      await looks.load();
      expect(looks.lookFor(1), isNull);
    });

    testWidgets('a photo is kept small; a non-picture is refused', (tester) async {
      await tester.runAsync(() async {
        final looks = BastionNodeLooks();
        expect(await looks.setPhoto(7, await _png(1200, 900)), isTrue);
        final photo = looks.lookFor(7)!.photo!;
        expect(photo.length, lessThanOrEqualTo(BastionNodeLooks.maxPhotoBytes));
        final frame = await (await ui.instantiateImageCodec(photo)).getNextFrame();
        expect(frame.image.width, BastionNodeLooks.photoSide);
        expect(await looks.setPhoto(8, Uint8List.fromList(List.filled(40, 3))), isFalse);
        expect(looks.lookFor(8), isNull);
      });
    });

    testWidgets('the avatar shows the picked color, and the sheet sets and clears it', (tester) async {
      final looks = BastionNodeLooks();
      await tester.pumpWidget(_app(Column(children: [
        NodeAvatar(num: 42, label: 'RDG', looks: looks),
        NodeLookSheet(num: 42, name: 'Ridge Relay', label: 'RDG', looks: looks, photos: _Photos(null)),
      ])));
      expect(find.byKey(const ValueKey('node-color-42')), findsNothing);
      expect(find.text('Look for Ridge Relay'), findsOneWidget);
      expect(find.text("Only on this phone. It's never sent over the mesh."), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Color 5'));
      await tester.pumpAndSettle();
      expect(looks.lookFor(42)?.color, NodeLookColors.all[4]);
      expect(find.byKey(const ValueKey('node-color-42')), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('node-look-clear')));
      await tester.pumpAndSettle();
      expect(looks.lookFor(42), isNull);
      expect(find.byKey(const ValueKey('node-color-42')), findsNothing);
    });

    test('initials are the first two letters', () {
      expect(avatarInitials('rdg'), 'RD');
      expect(avatarInitials('X'), 'X');
      expect(avatarInitials('  '), '?');
    });
  });

  group('link previews', () {
    test('finds the first https link and drops trailing punctuation', () {
      expect(BastionLinkPreviews.firstLink('see https://example.org/a?b=1.')?.toString(),
          'https://example.org/a?b=1');
      expect(BastionLinkPreviews.firstLink('plain http://example.org is skipped'), isNull);
      expect(BastionLinkPreviews.firstLink('no link here'), isNull);
    });

    test('reads Open Graph tags, falls back to the title, and shortens long descriptions', () {
      final uri = Uri.parse('https://www.example.org/trail');
      final og = BastionLinkPreviews.parse(uri,
          '<meta property="og:title" content="Ridge &amp; Valley"><meta name="description" content="${'x' * 300}">');
      expect(og!.host, 'example.org');
      expect(og.title, 'Ridge & Valley');
      expect(og.description!.length, BastionLinkPreviews.maxDescription + 1);
      expect(BastionLinkPreviews.parse(uri, '<title>\n  Trail map \n</title>')!.title, 'Trail map');
      expect(BastionLinkPreviews.parse(uri, '<p>no title</p>'), isNull);
    });

    test('each link is fetched once', () async {
      final pages = _Pages('<title>Hi</title>');
      final previews = BastionLinkPreviews(fetcher: pages);
      final uri = Uri.parse('https://example.org');
      expect((await previews.previewFor(uri))!.title, 'Hi');
      await previews.previewFor(uri);
      expect(pages.fetches, 1);
    });
  });

  group('chat', () {
    tearDown(() {
      BastionLinkPreviews.instance = BastionLinkPreviews();
      BastionPreferences.instance.linkPreviews = false;
    });

    Future<void> openPrimary(WidgetTester tester, List<BastionChatMessage> messages) async {
      await SharedPreferencesAsync().setString('bastion.comms.archive.v1', jsonEncode({
        'messages': [for (final m in messages) m.toJson()],
        'pending': [],
      }));
      await tester.pumpWidget(const BastionApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('conversation-ch0')));
      await tester.pumpAndSettle();
    }

    testWidgets('scrolling back offers a jump to the latest message', (tester) async {
      final now = DateTime.now();
      await openPrimary(tester, [
        for (var i = 0; i < 60; i++) _msg(i + 1, now.subtract(Duration(minutes: 60 - i)), 'message $i'),
      ]);
      expect(find.byKey(const ValueKey('chat-jump-latest')), findsNothing);
      await tester.drag(find.text('message 59'), const Offset(0, 1500));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-jump-latest')), findsOneWidget);
      expect(find.byTooltip('Jump to the latest message'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-jump-latest')));
      await tester.pumpAndSettle();
      expect(find.text('message 59'), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-jump-latest')), findsNothing);
    });

    testWidgets('link previews show only when switched on', (tester) async {
      final pages = _Pages('<title>Trail report</title>');
      BastionLinkPreviews.instance = BastionLinkPreviews(fetcher: pages);
      await openPrimary(tester, [_msg(1, DateTime.now(), 'read https://example.org/report')]);
      expect(find.text('Trail report'), findsNothing);
      expect(pages.fetches, 0, reason: 'nothing is fetched while previews are off');

      await tester.pageBack();
      await tester.pumpAndSettle();
      await BastionPreferences.instance.update(previews: true);
      await tester.tap(find.byKey(const ValueKey('conversation-ch0')));
      await tester.pumpAndSettle();
      expect(find.text('Trail report'), findsOneWidget);
      expect(find.text('example.org'), findsOneWidget);
    });
  });

  testWidgets('Home shows the connected radio\'s own readings, without repeating battery', (tester) async {
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pumpAndSettle();
    final panel = find.byKey(const ValueKey('home-sensors'));
    expect(panel, findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text('Sensors')), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.textContaining('Voltage')), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.textContaining('Battery')), findsNothing);
  });
}
