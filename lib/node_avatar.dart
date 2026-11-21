import 'dart:async';

import 'package:flutter/material.dart';

import 'backdrop_page.dart' show BackdropPhotos, SystemBackdropPhotos;
import 'l10n/generated/app_localizations.dart';
import 'services/bastion_node_looks.dart';
import 'theme/notoryx_tokens.dart';

/// Black or white, whichever reads better on [background].
Color readableOn(Color background) => background.computeLuminance() > 0.4 ? Colors.black : Colors.white;

/// One or two letters for a node's avatar.
String avatarInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.take(trimmed.length >= 2 ? 2 : 1).toString().toUpperCase();
}

/// A node's round avatar: the photo picked for it, else its initials on the
/// color picked for it, else its initials on the theme's own color.
class NodeAvatar extends StatelessWidget {
  const NodeAvatar({super.key, required this.num, required this.label, this.radius = 22, this.looks});

  final int num;

  /// Shown as initials; usually the node's short name.
  final String label;
  final double radius;

  /// Defaults to [BastionNodeLooks.instance].
  final BastionNodeLooks? looks;

  @override
  Widget build(BuildContext context) {
    final store = looks ?? BastionNodeLooks.instance;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final look = store.lookFor(num);
        final photo = look?.photo;
        final text = Text(avatarInitials(label),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: radius * 0.6));
        Widget plain(Color bg) =>
            CircleAvatar(radius: radius, backgroundColor: bg, foregroundColor: readableOn(bg), child: text);
        final Widget avatar;
        if (photo != null && photo.isNotEmpty) {
          avatar = ClipOval(
            key: ValueKey('node-photo-$num'),
            child: Image.memory(
              photo,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => plain(scheme.primaryContainer),
            ),
          );
        } else if (look?.color case final c?) {
          avatar = KeyedSubtree(key: ValueKey('node-color-$num'), child: plain(Color(c)));
        } else {
          avatar = CircleAvatar(
            radius: radius,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: text,
          );
        }
        return ExcludeSemantics(child: avatar);
      },
    );
  }
}

/// Opens the sheet that picks a color or photo for node [num].
Future<void> showNodeLookSheet(
  BuildContext context, {
  required int num,
  required String name,
  required String label,
  BastionNodeLooks? looks,
  BackdropPhotos photos = const SystemBackdropPhotos(),
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NodeLookSheet(num: num, name: name, label: label, looks: looks, photos: photos),
    );

/// Picks a color or a photo for one node. Only on this phone.
class NodeLookSheet extends StatefulWidget {
  const NodeLookSheet({
    super.key,
    required this.num,
    required this.name,
    required this.label,
    this.looks,
    this.photos = const SystemBackdropPhotos(),
  });

  final int num;
  final String name;
  final String label;
  final BastionNodeLooks? looks;
  final BackdropPhotos photos;

  @override
  State<NodeLookSheet> createState() => _NodeLookSheetState();
}

class _NodeLookSheetState extends State<NodeLookSheet> {
  bool _busy = false;
  BastionNodeLooks get _looks => widget.looks ?? BastionNodeLooks.instance;

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).nlPhotoFailed;
    setState(() => _busy = true);
    try {
      final bytes = await widget.photos.pick();
      if (bytes == null) return;
      if (!await _looks.setPhoto(widget.num, bytes)) messenger.showSnackBar(SnackBar(content: Text(failed)));
    } on Exception catch (e) {
      debugPrint('Node photo failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: _looks,
      builder: (context, _) {
        final look = _looks.lookFor(widget.num);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  NodeAvatar(num: widget.num, label: widget.label, radius: 28, looks: _looks),
                  const SizedBox(width: NxSpace.md),
                  Expanded(
                      child: Text(l.nlTitle(widget.name), style: Theme.of(context).textTheme.titleMedium)),
                ]),
                const SizedBox(height: NxSpace.sm),
                Text(l.nlHint, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: NxSpace.md),
                Wrap(
                  spacing: NxSpace.sm,
                  runSpacing: NxSpace.sm,
                  children: [
                    for (final (i, argb) in NodeLookColors.all.indexed)
                      Semantics(
                        button: true,
                        selected: look?.color == argb,
                        label: l.nlColorN(i + 1),
                        child: ExcludeSemantics(
                          child: InkResponse(
                            onTap: () => unawaited(_looks.setColor(widget.num, argb)),
                            radius: 26,
                            child: Container(
                              width: NxTouch.min,
                              height: NxTouch.min,
                              decoration: BoxDecoration(
                                color: Color(argb),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: look?.color == argb ? scheme.onSurface : scheme.outlineVariant,
                                  width: look?.color == argb ? 3 : 1,
                                ),
                              ),
                              child: look?.color == argb ? Icon(Icons.check, color: readableOn(Color(argb))) : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: NxSpace.md),
                Wrap(spacing: NxSpace.sm, runSpacing: NxSpace.sm, children: [
                  OutlinedButton.icon(
                    key: const ValueKey('node-look-photo'),
                    onPressed: _busy ? null : () => unawaited(_pickPhoto()),
                    icon: _busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.photo_library_outlined),
                    label: Text(l.nlChoosePhoto),
                  ),
                  if (look?.photo != null)
                    TextButton.icon(
                      onPressed: () => unawaited(_looks.removePhoto(widget.num)),
                      icon: const Icon(Icons.hide_image_outlined),
                      label: Text(l.nlRemovePhoto),
                    ),
                  if (look != null)
                    TextButton.icon(
                      key: const ValueKey('node-look-clear'),
                      onPressed: () => unawaited(_looks.clear(widget.num)),
                      icon: const Icon(Icons.restart_alt),
                      label: Text(l.nlClear),
                    ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}
