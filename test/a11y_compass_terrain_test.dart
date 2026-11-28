import 'dart:async';

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/link_planner_page.dart';
import 'package:bastion/main.dart';
import 'package:bastion/node_compass_page.dart';
import 'package:bastion/services/bastion_compass.dart';
import 'package:bastion/services/bastion_link_planner.dart';
import 'package:bastion/services/bastion_phone_position.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Point me to it and Check terrain, filled in (rounded positions, a live
/// heading, a finished profile), swept for tap size, labels, contrast and
/// overflow at normal and double text size in both themes.

class _Compass implements CompassSource {
  final controller = StreamController<HeadingReading>.broadcast();
  @override
  Future<bool> available() async => true;
  @override
  Stream<HeadingReading> headings() => controller.stream;
  @override
  Future<double?> declination(double latitude, double longitude) async => 0;
}

class _Location implements PhoneLocationSource {
  @override
  Future<String?> ensureAccess() async => null;
  @override
  Stream<PhoneFix> watch({bool lowPower = false, bool background = false}) => const Stream.empty();
}

class _Elevation implements ElevationSource {
  @override
  Future<List<double>> heights(List<({double latitude, double longitude})> points) async => [
    for (var i = 0; i < points.length; i++) 1000 + (i == points.length ~/ 2 ? 40.0 : 0),
  ];
}

/// This radio and the target both share rounded positions, so every
/// approximate warning shows.
class _Radio extends MeshtasticRadioCoordinator {
  @override
  int? get localNodeNum => 1;
  @override
  MeshtasticNode? get localNode => nodes.first;
  @override
  List<MeshtasticNode> get nodes => const [
    MeshtasticNode(num: 1, longName: 'Base', latitude: 40.0, longitude: -105.0, positionPrecisionBits: 13),
    MeshtasticNode(num: 2, longName: 'Ridge', latitude: 40.03, longitude: -104.98, positionPrecisionBits: 14),
  ];
}

Future<List<String>> _sweep(
  WidgetTester tester,
  String name,
  Widget page,
  double scale,
  Brightness theme, {
  Future<void> Function()? after,
}) async {
  final problems = <String>[];
  final handle = tester.ensureSemantics();
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  // Tall enough that everything is built (and so checked) even at double text size.
  tester.view.physicalSize = const Size(390, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: BastionApp.appearance(theme),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: page,
    ),
  );
  await tester.pumpAndSettle();
  if (after != null) await after();
  final error = tester.takeException();
  if (error != null) problems.add('$name x$scale: ${'$error'.split('\n').first}');
  for (final (label, guideline) in [
    ('tap size', androidTapTargetGuideline),
    ('label', labeledTapTargetGuideline),
    ('contrast', textContrastGuideline),
  ]) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) problems.add('$name x$scale ${theme.name} $label: ${result.reason?.replaceAll('\n', ' | ')}');
  }
  handle.dispose();
  return problems;
}

void main() {
  for (final theme in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Point me to it, ${theme.name}, text size $scale', (tester) async {
        final radio = _Radio();
        addTearDown(radio.dispose);
        final compass = _Compass();
        addTearDown(compass.controller.close);
        final problems = await _sweep(
          tester,
          'compass',
          NodeCompassPage(radio: radio, nodeNum: 2, compass: compass, location: _Location(), haptics: false),
          scale,
          theme,
          after: () async {
            compass.controller.add((heading: 300, accuracy: 3));
            await tester.pumpAndSettle();
          },
        );
        expect(find.byKey(const ValueKey('nc-radio-approximate')), findsOneWidget);
        expect(problems, isEmpty, reason: problems.join('\n'));
      });

      testWidgets('Check terrain, ${theme.name}, text size $scale', (tester) async {
        final radio = _Radio();
        addTearDown(radio.dispose);
        final problems = await _sweep(
          tester,
          'terrain',
          LinkPlannerPage(radio: radio, elevation: _Elevation(), initialFrom: 1, initialTo: 2),
          scale,
          theme,
          after: () async {
            final run = find.text('Check line of sight');
            await tester.ensureVisible(run);
            await tester.tap(run);
            await tester.pumpAndSettle();
          },
        );
        expect(find.byKey(const ValueKey('lp-approximate')), findsOneWidget);
        expect(find.text('Height profile'), findsOneWidget);
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  }
}
