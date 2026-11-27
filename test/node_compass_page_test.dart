import 'dart:async';

import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/node_compass_page.dart';
import 'package:bastion/services/bastion_channel_precision.dart';
import 'package:bastion/services/bastion_compass.dart';
import 'package:bastion/services/bastion_phone_position.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Compass implements CompassSource {
  _Compass({this.has = true});
  final bool has;
  final controller = StreamController<HeadingReading>.broadcast();
  @override
  Future<bool> available() async => has;
  @override
  Stream<HeadingReading> headings() => controller.stream;
  @override
  Future<double?> declination(double latitude, double longitude) async => 0;
}

class _Location implements PhoneLocationSource {
  _Location({this.problem});
  final String? problem;
  int asked = 0;
  final fixes = StreamController<PhoneFix>.broadcast();
  @override
  Future<String?> ensureAccess() async {
    asked++;
    return problem;
  }

  @override
  Stream<PhoneFix> watch({bool lowPower = false, bool background = false}) => fixes.stream;
}

class _Radio extends MeshtasticRadioCoordinator {
  _Radio({this.radioPlaced = true, this.targetBits, this.radioBits});
  final bool radioPlaced;
  final int? targetBits;
  final int? radioBits;
  @override
  int? get localNodeNum => 1;
  @override
  MeshtasticNode? get localNode => nodes.first;
  @override
  List<MeshtasticNode> get nodes => [
        radioPlaced
            ? MeshtasticNode(num: 1, longName: 'Base', latitude: 40.0, longitude: -105.0, positionPrecisionBits: radioBits)
            : const MeshtasticNode(num: 1, longName: 'Base'),
        // About 1.1 km due north of Base.
        MeshtasticNode(num: 2, longName: 'Ridge', latitude: 40.01, longitude: -105.0, positionPrecisionBits: targetBits),
      ];
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page));
  await tester.pumpAndSettle();
}

void main() {
  group('compass maths', () {
    test('turns take the short way round', () {
      expect(BastionCompass.turn(350, 10), 20);
      expect(BastionCompass.turn(10, 350), -20);
      expect(BastionCompass.turn(0, 180).abs(), 180);
      expect(BastionCompass.normalise(-30), 330);
    });

    test('smoothing passes through north, not south', () {
      final next = BastionCompass.smooth(359, 1, factor: 0.5);
      expect(next == 0 || next < 1 || next > 359, isTrue, reason: '$next');
      expect(BastionCompass.smooth(null, 370), 10);
    });

    test('on target within ten degrees either side', () {
      expect(BastionCompass.onTarget(355, 4), isTrue);
      expect(BastionCompass.onTarget(0, 15), isFalse);
    });
  });

  group('position precision', () {
    test('rounded positions report how rough they are', () {
      expect(BastionChannelPrecision.uncertaintyMeters(10), closeTo(23300, 1));
      expect(BastionChannelPrecision.uncertaintyMeters(13), closeTo(2912, 1));
      expect(BastionChannelPrecision.uncertaintyMeters(32), isNull);
      expect(BastionChannelPrecision.uncertaintyMeters(0), isNull);
      expect(BastionChannelPrecision.uncertaintyMeters(null), isNull);
      expect(BastionChannelPrecision.uncertaintyMeters(31), isNull, reason: 'under 30 m does not matter');
    });

    test('a received position keeps its precision', () {
      final node = MeshtasticNodeInfoCodec.applyPosition(
        const MeshtasticNode(num: 9),
        pb.Position(latitudeI: 400000000, longitudeI: -1050000000, precisionBits: 13),
      );
      expect(node.positionPrecisionBits, 13);
      expect(node.positionUncertaintyMeters, closeTo(2912, 1));
      final exact = MeshtasticNodeInfoCodec.applyPosition(
          node, pb.Position(latitudeI: 400000000, longitudeI: -1050000000, precisionBits: 32));
      expect(exact.positionUncertaintyMeters, isNull);
    });
  });

  testWidgets('points from the radio and tells which way to turn', (tester) async {
    final radio = _Radio();
    addTearDown(radio.dispose);
    final compass = _Compass();
    final location = _Location();
    await _pump(tester, NodeCompassPage(radio: radio, nodeNum: 2, compass: compass, location: location, haptics: false));
    expect(location.asked, 0, reason: 'the radio has a position, so the phone is not asked');
    expect(find.text('Measured from this radio\'s position.'), findsOneWidget);
    expect(find.textContaining('Bearing 0°'), findsOneWidget);

    expect(compass.controller.hasListener, isTrue);
    compass.controller.add((heading: 90, accuracy: 3));
    await tester.pumpAndSettle();
    expect(find.text('Turn left 90°'), findsOneWidget);
    expect(find.byKey(const ValueKey('nc-approximate')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nc-use-phone')));
    await tester.pump();
    location.fixes.add(PhoneFix(latitude: 40.02, longitude: -105.0, time: DateTime.utc(2026)));
    await tester.pumpAndSettle();
    expect(location.asked, 1);
    expect(find.text('Measured from this phone\'s location.'), findsOneWidget);
    expect(find.textContaining('Bearing 180°'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no compass falls back to north-up and warns about rough positions', (tester) async {
    final radio = _Radio(targetBits: 13);
    addTearDown(radio.dispose);
    await _pump(tester, NodeCompassPage(radio: radio, nodeNum: 2, compass: _Compass(has: false), location: _Location(), haptics: false));
    expect(find.textContaining('no compass'), findsOneWidget);
    expect(find.byKey(const ValueKey('nc-approximate')), findsOneWidget);
    expect(find.byKey(const ValueKey('nc-distance')), findsOneWidget);
  });

  testWidgets('with no radio position it asks for the phone and explains a refusal', (tester) async {
    final radio = _Radio(radioPlaced: false);
    addTearDown(radio.dispose);
    final location = _Location(problem: 'Location permission was not granted.');
    await _pump(tester, NodeCompassPage(radio: radio, nodeNum: 2, compass: _Compass(), location: location, haptics: false));
    expect(location.asked, 1);
    expect(find.text('Location permission was not granted.'), findsOneWidget);
    expect(find.textContaining('No position to point from'), findsWidgets);
  });

  testWidgets('warns when the radio it measures from has a rounded position', (tester) async {
    final radio = _Radio(radioBits: 13);
    addTearDown(radio.dispose);
    final location = _Location();
    await _pump(tester, NodeCompassPage(radio: radio, nodeNum: 2, compass: _Compass(), location: location, haptics: false));
    expect(find.byKey(const ValueKey('nc-radio-approximate')), findsOneWidget);
    expect(find.textContaining("Your radio's position is only approximate"), findsOneWidget);
    expect(find.byKey(const ValueKey('nc-approximate')), findsNothing, reason: 'the node itself is exact');

    await tester.tap(find.byKey(const ValueKey('nc-use-phone')));
    await tester.pump();
    location.fixes.add(PhoneFix(latitude: 40.0, longitude: -105.0, time: DateTime.utc(2026)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nc-radio-approximate')), findsNothing,
        reason: 'measuring from the phone no longer depends on the radio');
  });

  testWidgets('no radio warning when the radio position is exact', (tester) async {
    final radio = _Radio();
    addTearDown(radio.dispose);
    await _pump(tester, NodeCompassPage(radio: radio, nodeNum: 2, compass: _Compass(), location: _Location(), haptics: false));
    expect(find.byKey(const ValueKey('nc-radio-approximate')), findsNothing);
  });
}
