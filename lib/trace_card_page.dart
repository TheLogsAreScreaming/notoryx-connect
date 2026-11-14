import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_trace_card.dart';
import 'services/bastion_units.dart';
import 'theme/notoryx_tokens.dart';

String _snr(AppLocalizations l, double? snr) => snr == null ? l.tcSnrUnknown : '${snr.toStringAsFixed(1)} dB';

String _seconds(Duration d) => (d.inMilliseconds / 1000).toStringAsFixed(1);

String _when(DateTime t, String locale) => DateFormat.yMMMd(locale).add_Hm().format(t.toLocal());

/// The trace card as plain text, for sharing where an image doesn't fit.
String traceCardText(AppLocalizations l, TraceCard card, {required BastionUnits units, required String locale}) {
  final points = card.routePoints;
  return [
    l.tcTitle,
    l.tcFrom(card.sender),
    l.tcTo(card.target),
    l.tcSentAt(_when(card.sentAt, locale)),
    l.tcRoundTrip(_seconds(card.roundTrip)),
    l.tcRelays(card.relays),
    '',
    l.tcThere,
    for (final (i, h) in card.towards.indexed) '${i + 1}. ${h.name} (${h.nodeId}) · ${_snr(l, h.snrDb)}',
    '',
    l.tcBack,
    if (card.back.isEmpty)
      l.tcBackUnknown
    else
      for (final (i, h) in card.back.indexed) '${i + 1}. ${h.name} (${h.nodeId}) · ${_snr(l, h.snrDb)}',
    if (points.isNotEmpty || card.weakestSnr != null) '',
    if (points.isNotEmpty) l.tcDistance(BastionUnitFormat.distance(card.routeMeters, units)),
    if (card.weakestSnr != null) l.tcWeakest(_snr(l, card.weakestSnr)),
  ].join('\n');
}

/// Shows one finished traceroute as a card that can be shared as an image
/// or as text.
class TraceCardPage extends StatefulWidget {
  const TraceCardPage({super.key, required this.card});

  final TraceCard card;

  @override
  State<TraceCardPage> createState() => _TraceCardPageState();
}

class _TraceCardPageState extends State<TraceCardPage> {
  final _boundary = GlobalKey();
  bool _sharing = false;

  Future<void> _share({required bool image}) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final text = traceCardText(l, widget.card,
        units: BastionPreferences.instance.units, locale: Localizations.localeOf(context).toLanguageTag());
    setState(() => _sharing = true);
    try {
      if (image) {
        final render = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final picture = await render.toImage(pixelRatio: 3);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        picture.dispose();
        await SharePlus.instance.share(ShareParams(
          text: text,
          files: [XFile.fromData(bytes!.buffer.asUint8List(), mimeType: 'image/png', name: 'trace-card.png')],
        ));
      } else {
        await SharePlus.instance.share(ShareParams(text: text));
      }
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.tcShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tcTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: NxSpace.page,
          children: [
            RepaintBoundary(key: _boundary, child: TraceCardView(card: widget.card)),
            const SizedBox(height: NxSpace.md),
            Wrap(
              spacing: NxSpace.sm,
              runSpacing: NxSpace.sm,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  key: const ValueKey('trace-card-share-image'),
                  onPressed: _sharing ? null : () => _share(image: true),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l.tcShareImage),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('trace-card-share-text'),
                  onPressed: _sharing ? null : () => _share(image: false),
                  icon: const Icon(Icons.notes),
                  label: Text(l.tcShareText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The card itself: who and when, the timing, a sketch of the round trip
/// and every hop there and back.
class TraceCardView extends StatelessWidget {
  const TraceCardView({super.key, required this.card});

  final TraceCard card;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final units = BastionPreferences.instance.units;
    final points = card.routePoints;
    final unplaced = card.unplaced;
    return Container(
      padding: const EdgeInsets.all(NxSpace.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(NxRadius.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.tcTitle.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary)),
          const SizedBox(height: NxSpace.xxs),
          Text(l.tcFrom(card.sender), style: theme.textTheme.titleMedium),
          Text(l.tcTo(card.target), style: muted),
          Text(l.tcSentAt(_when(card.sentAt, locale)), style: muted),
          const SizedBox(height: NxSpace.sm),
          Wrap(spacing: NxSpace.md, runSpacing: NxSpace.xs, children: [
            _Fact(Icons.timer_outlined, l.tcRoundTrip(_seconds(card.roundTrip))),
            _Fact(Icons.hub_outlined, l.tcRelays(card.relays)),
            if (points.isNotEmpty)
              _Fact(Icons.straighten, l.tcDistance(BastionUnitFormat.distance(card.routeMeters, units))),
            if (card.weakestSnr != null)
              _Fact(Icons.signal_cellular_alt_1_bar, l.tcWeakest(_snr(l, card.weakestSnr))),
          ]),
          const SizedBox(height: NxSpace.md),
          if (points.isEmpty)
            Text(l.tcNoMap, style: muted)
          else
            Semantics(
              container: true,
              image: true,
              label: l.tcMapLabel(card.sender, [for (final h in card.towards) h.name].join(', ')),
              child: ExcludeSemantics(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CustomPaint(
                    painter: TraceRoutePainter(
                      points: points,
                      line: scheme.primary,
                      dot: scheme.tertiary,
                      home: scheme.secondary,
                      background: scheme.surfaceContainerLowest,
                    ),
                  ),
                ),
              ),
            ),
          if (points.isNotEmpty && unplaced.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: NxSpace.xxs),
              child: Text(l.tcUnplaced(unplaced.join(', ')), style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: NxSpace.md),
          Text(l.tcThere, style: theme.textTheme.titleSmall),
          _HopRow(index: '•', title: card.sender, detail: l.tcStart, snr: ''),
          for (final (i, h) in card.towards.indexed)
            _HopRow(index: '${i + 1}', title: h.name, detail: h.nodeId, snr: _snr(l, h.snrDb)),
          const SizedBox(height: NxSpace.sm),
          Text(l.tcBack, style: theme.textTheme.titleSmall),
          if (card.back.isEmpty)
            Text(l.tcBackUnknown, style: muted)
          else
            for (final (i, h) in card.back.indexed)
              _HopRow(index: '${i + 1}', title: h.name, detail: h.nodeId, snr: _snr(l, h.snrDb)),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        ExcludeSemantics(child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(width: NxSpace.xxs),
        Flexible(child: Text(text)),
      ]);
}

class _HopRow extends StatelessWidget {
  const _HopRow({required this.index, required this.title, required this.detail, required this.snr});
  final String index, title, detail, snr;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NxSpace.xxs),
        child: Row(children: [
          SizedBox(width: 28, child: ExcludeSemantics(child: Text(index, style: TextStyle(color: muted)))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title),
              Text(detail, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted)),
            ]),
          ),
          if (snr.isNotEmpty) Text(snr),
        ]),
      ),
    );
  }
}

/// Draws the round trip on a plain backdrop: the route, a dot per node and
/// a ring where it started and ended. Needs no map tiles, so it works
/// offline and looks the same in a shared image.
class TraceRoutePainter extends CustomPainter {
  TraceRoutePainter({
    required this.points,
    required this.line,
    required this.dot,
    required this.home,
    required this.background,
  });

  final List<({double lat, double lon})> points;
  final Color line, dot, home, background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(NxRadius.sm)),
      Paint()..color = background,
    );
    final xy = projectRoute(points, width: size.width, height: size.height, padding: 20);
    if (xy.length < 2) return;
    final path = Path()..moveTo(xy.first.x, xy.first.y);
    for (final p in xy.skip(1)) {
      path.lineTo(p.x, p.y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in xy.skip(1)) {
      canvas.drawCircle(Offset(p.x, p.y), 5, Paint()..color = dot);
    }
    canvas.drawCircle(
      Offset(xy.first.x, xy.first.y),
      8,
      Paint()
        ..color = home
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(TraceRoutePainter old) =>
      old.points != points || old.line != line || old.dot != dot || old.home != home || old.background != background;
}
