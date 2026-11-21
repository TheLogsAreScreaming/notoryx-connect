import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_backdrop.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_backdrop.dart';

/// Chooses a picture for the Background page; null when cancelled.
abstract interface class BackdropPhotos {
  Future<Uint8List?> pick();
}

class SystemBackdropPhotos implements BackdropPhotos {
  const SystemBackdropPhotos();

  @override
  Future<Uint8List?> pick() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/heic'],
        uniformTypeIdentifiers: ['public.image'],
      ),
    ]);
    if (file == null) return null;
    if (await file.length() > BastionBackdrop.photoMaxBytes) return Uint8List(0);
    return file.readAsBytes();
  }
}

/// Picks what sits behind the main tabs: the theme's glow, a color, a
/// gradient, a blend of two colors or a photo, with dim and blur.
class BackdropPage extends StatefulWidget {
  const BackdropPage({super.key, this.store, this.photos = const SystemBackdropPhotos()});

  /// Defaults to [BastionBackdrop.instance].
  final BastionBackdrop? store;
  final BackdropPhotos photos;

  @override
  State<BackdropPage> createState() => _BackdropPageState();
}

class _BackdropPageState extends State<BackdropPage> {
  bool _busy = false;

  BastionBackdrop get _store => widget.store ?? BastionBackdrop.instance;

  void _set(BackdropStyle next) => unawaited(_store.setStyle(next));

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).bgPhotoFailed;
    setState(() => _busy = true);
    try {
      final bytes = await widget.photos.pick();
      if (bytes == null) return;
      if (!await _store.setPhoto(bytes)) messenger.showSnackBar(SnackBar(content: Text(failed)));
    } on Exception catch (e) {
      debugPrint('Background photo failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String kindLabel(AppLocalizations l, BackdropKind k) => switch (k) {
        BackdropKind.theme => l.bgKindTheme,
        BackdropKind.solid => l.bgKindSolid,
        BackdropKind.linear => l.bgKindLinear,
        BackdropKind.mesh => l.bgKindMesh,
        BackdropKind.photo => l.bgKindPhoto,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.bgTitle)),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final style = _store.style;
          final kinds = [
            BackdropKind.theme,
            BackdropKind.solid,
            BackdropKind.linear,
            BackdropKind.mesh,
            if (!kIsWeb) BackdropKind.photo,
          ];
          final twoColors = style.kind == BackdropKind.linear || style.kind == BackdropKind.mesh;
          final usesColors = twoColors || style.kind == BackdropKind.solid;
          return ListView(
            padding: NxSpace.page,
            children: [
              // The real backdrop with a card on it.
              ClipRRect(
                borderRadius: BorderRadius.circular(NxRadius.lg),
                child: SizedBox(
                  height: 190,
                  child: Stack(fit: StackFit.expand, children: [
                    NxBackdropLayer(style: style, photo: _store.photo),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(NxSpace.lg),
                        child: Card(
                          key: const ValueKey('bg-preview'),
                          child: Padding(
                            padding: const EdgeInsets.all(NxSpace.md),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.bgPreviewTitle, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: NxSpace.xs),
                                Text(l.bgPreviewBody),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: NxSpace.sm),
              Text(l.bgHint, style: text.bodySmall),
              const SizedBox(height: NxSpace.lg),
              Wrap(
                spacing: NxSpace.sm,
                runSpacing: NxSpace.sm,
                children: [
                  for (final k in kinds)
                    ChoiceChip(
                      key: ValueKey('bg-kind-${k.name}'),
                      label: Text(kindLabel(l, k)),
                      selected: style.kind == k,
                      onSelected: (_) {
                        if (k == BackdropKind.photo && _store.photo == null) {
                          unawaited(_pickPhoto());
                        } else {
                          _set(style.copyWith(kind: k));
                        }
                      },
                    ),
                ],
              ),
              if (usesColors) ...[
                const SizedBox(height: NxSpace.lg),
                _ColorRow(
                  title: twoColors ? l.bgColor1 : l.bgKindSolid,
                  selected: style.color1,
                  labelFor: l.bgColorN,
                  onPick: (c) => _set(style.copyWith(color1: c)),
                ),
              ],
              if (twoColors) ...[
                const SizedBox(height: NxSpace.md),
                _ColorRow(
                  title: l.bgColor2,
                  selected: style.color2,
                  labelFor: l.bgColorN,
                  onPick: (c) => _set(style.copyWith(color2: c)),
                ),
              ],
              if (style.kind == BackdropKind.photo) ...[
                const SizedBox(height: NxSpace.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => unawaited(_pickPhoto()),
                    icon: _busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.photo_library_outlined),
                    label: Text(l.bgChoosePhoto),
                  ),
                ),
                const SizedBox(height: NxSpace.xs),
                Text(l.bgPhotoNotBackedUp, style: text.bodySmall),
              ],
              if (style.isCustom) ...[
                const SizedBox(height: NxSpace.lg),
                _LabelledSlider(
                  label: l.bgDim,
                  value: style.dim,
                  min: BackdropStyle.minDim,
                  max: BackdropStyle.maxDim,
                  valueText: '${(style.dim * 100).round()}%',
                  onChanged: (v) => _set(style.copyWith(dim: v)),
                ),
                if (style.kind == BackdropKind.photo)
                  _LabelledSlider(
                    label: l.bgBlur,
                    value: style.blur,
                    min: 0,
                    max: BackdropStyle.maxBlur,
                    valueText: style.blur.round().toString(),
                    onChanged: (v) => _set(style.copyWith(blur: v)),
                  ),
                const SizedBox(height: NxSpace.md),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('bg-reset'),
                    onPressed: () => unawaited(_store.reset()),
                    icon: const Icon(Icons.restart_alt),
                    label: Text(l.bgReset),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.title, required this.selected, required this.labelFor, required this.onPick});

  final String title;
  final int selected;
  final String Function(int index) labelFor;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: NxSpace.sm),
        Wrap(
          spacing: NxSpace.sm,
          runSpacing: NxSpace.sm,
          children: [
            for (final (i, argb) in BackdropColours.all.indexed)
              Semantics(
                button: true,
                selected: argb == selected,
                label: labelFor(i + 1),
                child: ExcludeSemantics(
                  child: InkResponse(
                    onTap: () => onPick(argb),
                    radius: 26,
                    child: Container(
                      width: NxTouch.min,
                      height: NxTouch.min,
                      decoration: BoxDecoration(
                        color: Color(argb),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: argb == selected ? scheme.onSurface : scheme.outlineVariant,
                          width: argb == selected ? 3 : 1,
                        ),
                      ),
                      // A tick as well as the ring, so the choice isn't shown by
                      // color alone.
                      child: argb == selected
                          ? Icon(Icons.check,
                              color: Color(argb).computeLuminance() > 0.4 ? Colors.black : Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LabelledSlider extends StatelessWidget {
  const _LabelledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueText,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String valueText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Flexible(child: Text(label)),
          Expanded(
            flex: 3,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              label: valueText,
              semanticFormatterCallback: (_) => valueText,
              onChanged: onChanged,
            ),
          ),
          Text(valueText),
        ],
      );
}

/// The settings row that opens [BackdropPage].
class BackdropSettingsTile extends StatelessWidget {
  const BackdropSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = BastionBackdrop.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListTile(
        key: const ValueKey('settings-background'),
        leading: const Icon(Icons.wallpaper_outlined),
        title: Text(l.bgTitle),
        subtitle: Text(_BackdropPageState.kindLabel(l, store.style.kind)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BackdropPage())),
      ),
    );
  }
}
