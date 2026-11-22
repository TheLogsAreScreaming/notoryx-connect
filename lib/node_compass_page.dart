import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_compass.dart';
import 'services/bastion_geo.dart';
import 'services/bastion_phone_position.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'services/meshtastic_node_database.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// "Point me to it": a big arrow that points at a node and turns with the
/// phone, with the distance and bearing. Measures from this radio's own
/// position until the phone's location is asked for (or when the radio has
/// none). The phone's location never leaves the phone.
class NodeCompassPage extends StatefulWidget {
  NodeCompassPage({
    super.key,
    required this.radio,
    required this.nodeNum,
    PhoneLocationSource? location,
    this.compass = const DeviceCompass(),
    this.haptics = true,
  }) : location = location ?? GeolocatorLocationSource();

  final MeshtasticRadioCoordinator radio;
  final int nodeNum;
  final PhoneLocationSource location;
  final CompassSource compass;

  /// Off in tests.
  final bool haptics;

  @override
  State<NodeCompassPage> createState() => _NodeCompassPageState();
}

enum _From { phone, radio }

class _NodeCompassPageState extends State<NodeCompassPage> {
  StreamSubscription<HeadingReading>? _headings;
  StreamSubscription<PhoneFix>? _fixes;
  bool? _hasCompass;
  double? _heading; // degrees from true north, smoothed
  int _accuracy = 3;
  double _declination = 0;
  bool _declinationSet = false;
  PhoneFix? _phone;
  bool _locating = false;
  String? _locationProblem;
  bool _wasOnTarget = false;

  MeshtasticRadioCoordinator get _radio => widget.radio;

  MeshtasticNode? get _target {
    for (final n in _radio.nodes) {
      if (n.num == widget.nodeNum) return n;
    }
    return null;
  }

  ({double lat, double lon, _From from})? get _here {
    if (_phone case final p?) return (lat: p.latitude, lon: p.longitude, from: _From.phone);
    final local = _radio.localNode;
    if (local != null && local.hasPosition) return (lat: local.latitude!, lon: local.longitude!, from: _From.radio);
    return null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    // With no radio position there is nothing to point from, so ask for
    // the phone's location straight away.
    if (_here == null) unawaited(_usePhone());
    final has = await widget.compass.available();
    if (!mounted) return;
    setState(() => _hasCompass = has);
    if (!has) return;
    await _updateDeclination();
    if (!mounted) return;
    _headings = widget.compass.headings().listen(_onHeading, onError: (Object _) {
      if (mounted) setState(() => _hasCompass = false);
    });
  }

  Future<void> _updateDeclination() async {
    final here = _here;
    if (here == null) return;
    final d = await widget.compass.declination(here.lat, here.lon);
    if (mounted && d != null) {
      setState(() {
        _declination = d;
        _declinationSet = true;
      });
    }
  }

  void _onHeading(HeadingReading r) {
    final next = BastionCompass.smooth(_heading, r.heading + _declination);
    final here = _here, target = _target;
    if (here != null && target != null && target.hasPosition) {
      final onTarget = BastionCompass.onTarget(
          next, BastionGeo.bearingDegrees(here.lat, here.lon, target.latitude!, target.longitude!));
      if (onTarget && !_wasOnTarget && widget.haptics) unawaited(HapticFeedback.lightImpact());
      _wasOnTarget = onTarget;
    }
    setState(() {
      _heading = next;
      _accuracy = r.accuracy;
    });
  }

  Future<void> _usePhone() async {
    setState(() {
      _locating = true;
      _locationProblem = null;
    });
    final problem = await widget.location.ensureAccess();
    if (!mounted) return;
    if (problem != null) {
      setState(() {
        _locating = false;
        _locationProblem = problem;
      });
      return;
    }
    await _fixes?.cancel();
    _fixes = widget.location.watch().listen((fix) {
      if (!mounted) return;
      final first = _phone == null;
      setState(() {
        _phone = fix;
        _locating = false;
      });
      if (first || !_declinationSet) unawaited(_updateDeclination());
    }, onError: (Object error) {
      if (mounted) {
        setState(() {
          _locating = false;
          _locationProblem = '$error';
        });
      }
    });
  }

  @override
  void dispose() {
    unawaited(_headings?.cancel());
    unawaited(_fixes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _radio,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final units = BastionPreferences.instance.units;
    final points = l.ncPoints.split(',');
    String point(double bearing) =>
        points.length == 8 ? points[((BastionCompass.normalise(bearing) + 22.5) ~/ 45) % 8] : '';
    final target = _target;
    final name = target?.displayName ?? '!${widget.nodeNum.toRadixString(16).padLeft(8, '0')}';
    final here = _here;
    final heading = _heading;
    final compass = _hasCompass == true && heading != null;
    final placed = target != null && target.hasPosition;
    final bearing = here == null || !placed
        ? null
        : BastionGeo.bearingDegrees(here.lat, here.lon, target.latitude!, target.longitude!);
    final distance = here == null || !placed
        ? null
        : BastionGeo.distanceMeters(here.lat, here.lon, target.latitude!, target.longitude!);
    final turn = bearing == null || !compass ? null : BastionCompass.turn(heading, bearing);
    final onTarget = turn != null && turn.abs() <= BastionCompass.onTargetDegrees;
    String turnText(double t, {bool spoken = false}) {
      // Rounded to tens for a screen reader, so it isn't told every wobble.
      final deg = spoken ? (t.abs() / 10).round() * 10 : t.abs().round();
      if (t.abs() <= BastionCompass.onTargetDegrees) return l.ncOnTarget;
      return t < 0 ? l.ncTurnLeft(deg) : l.ncTurnRight(deg);
    }

    final distanceText = distance == null ? null : BastionUnitFormat.distance(distance, units);
    final bearingText = bearing == null ? null : l.ncBearing(bearing.round() % 360, point(bearing));
    final rose = compass ? -heading : 0.0;
    final arrow = bearing == null ? null : bearing + rose;
    final rough = target?.positionUncertaintyMeters;

    return Scaffold(
      appBar: AppBar(title: Text(l.ncTitle)),
      body: SafeArea(
        child: ListView(padding: NxSpace.page, children: [
          Text(name, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: NxSpace.sm),
          Semantics(
            liveRegion: true,
            label: !placed
                ? l.ncNoTarget(name)
                : here == null
                    ? l.ncNoPosition
                    : [name, distanceText, turn == null ? bearingText : turnText(turn, spoken: true)]
                        .whereType<String>()
                        .join(', '),
            child: ExcludeSemantics(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      key: const ValueKey('nc-compass'),
                      painter: CompassPainter(
                        roseDegrees: rose,
                        arrowDegrees: arrow,
                        onTarget: onTarget,
                        scheme: theme.colorScheme,
                        north: points.isEmpty ? 'N' : points.first,
                        textStyle: theme.textTheme.titleMedium ?? const TextStyle(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: NxSpace.md),
          if (!placed)
            NxBanner(tone: NxTone.warning, message: l.ncNoTarget(name))
          else if (here == null)
            NxBanner(tone: NxTone.info, message: l.ncNoPosition)
          else
            ExcludeSemantics(
              child: Column(children: [
                Text(distanceText!, key: const ValueKey('nc-distance'), style: theme.textTheme.displaySmall),
                if (turn != null) Text(turnText(turn), style: theme.textTheme.headlineSmall),
                Text(bearingText!, style: theme.textTheme.titleMedium),
              ]),
            ),
          const SizedBox(height: NxSpace.sm),
          if (placed && rough != null)
            NxBanner(
              key: const ValueKey('nc-approximate'),
              tone: NxTone.warning,
              message: l.ncApproximate(name, BastionUnitFormat.distance(rough, units)),
            ),
          if (_hasCompass == false) _Note(icon: Icons.explore_off_outlined, text: l.ncNoCompass),
          if (compass && _accuracy <= 1) _Note(icon: Icons.screen_rotation, text: l.ncCalibrate),
          if (_locationProblem case final problem?) NxBanner(tone: NxTone.danger, message: problem),
          if (here != null)
            Text(here.from == _From.phone ? l.ncFromPhone : l.ncFromRadio,
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          if (here?.from != _From.phone) ...[
            const SizedBox(height: NxSpace.sm),
            Center(
              child: OutlinedButton.icon(
                key: const ValueKey('nc-use-phone'),
                onPressed: _locating ? null : _usePhone,
                icon: _locating
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: Text(l.ncUsePhone),
              ),
            ),
          ],
          const SizedBox(height: NxSpace.sm),
          Text(l.ncPrivacy, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: NxSpace.sm),
        child: Row(children: [
          Icon(icon, size: 20),
          const SizedBox(width: NxSpace.sm),
          Expanded(child: Text(text)),
        ]),
      );
}

/// A compass rose turned by [roseDegrees] and an arrow pointing
/// [arrowDegrees] clockwise from the top of the screen.
class CompassPainter extends CustomPainter {
  CompassPainter({
    required this.roseDegrees,
    required this.arrowDegrees,
    required this.onTarget,
    required this.scheme,
    required this.north,
    required this.textStyle,
  });

  final double roseDegrees;
  final double? arrowDegrees;
  final bool onTarget;
  final ColorScheme scheme;
  final String north;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    canvas.drawCircle(centre, radius, Paint()..color = scheme.surfaceContainerHighest);
    canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = scheme.outline);

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(roseDegrees * math.pi / 180);
    final tick = Paint()..color = scheme.onSurfaceVariant;
    for (var d = 0; d < 360; d += 15) {
      final long = d % 90 == 0;
      tick.strokeWidth = long ? 3 : 1.5;
      canvas.drawLine(Offset(0, -radius + 2), Offset(0, -radius + (long ? 18 : 10)), tick);
      canvas.rotate(15 * math.pi / 180);
    }
    final label = TextPainter(
      text: TextSpan(text: north, style: textStyle.copyWith(color: scheme.error, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(-label.width / 2, -radius + 22));
    canvas.restore();

    final arrow = arrowDegrees;
    if (arrow == null) return;
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(arrow * math.pi / 180);
    final length = radius * 0.7;
    final shape = Path()
      ..moveTo(0, -length)
      ..lineTo(length * 0.28, length * 0.15)
      ..lineTo(0, length * 0.02)
      ..lineTo(-length * 0.28, length * 0.15)
      ..close();
    canvas.drawPath(shape, Paint()..color = onTarget ? scheme.tertiary : scheme.primary);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CompassPainter old) =>
      old.roseDegrees != roseDegrees ||
      old.arrowDegrees != arrowDegrees ||
      old.onTarget != onTarget ||
      old.scheme != scheme ||
      old.north != north;
}
