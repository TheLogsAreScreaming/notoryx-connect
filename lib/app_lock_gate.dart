import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_app_lock.dart';

/// Shows the lock screen over the app while it is locked. The app stays
/// built underneath, so the radio link and open pages are not disturbed.
class BastionAppLockGate extends StatefulWidget {
  const BastionAppLockGate({super.key, required this.lock, required this.child});
  final BastionAppLock lock;
  final Widget child;
  @override
  State<BastionAppLockGate> createState() => _BastionAppLockGateState();
}

class _BastionAppLockGateState extends State<BastionAppLockGate> {
  bool _wasLocked = false;

  @override
  void initState() {
    super.initState();
    widget.lock.addListener(_changed);
    _changed();
  }

  @override
  void dispose() {
    widget.lock.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final locked = widget.lock.locked;
    if (locked && !_wasLocked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    _wasLocked = locked;
    if (mounted) setState(() {});
  }

  void _unlock() {
    if (mounted) widget.lock.unlock(AppLocalizations.of(context).lockReason);
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.lock.locked;
    return Stack(fit: StackFit.expand, children: [
      ExcludeSemantics(excluding: locked, child: widget.child),
      if (locked) _lockScreen(context),
    ]);
  }

  Widget _lockScreen(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('app-lock-screen'),
      color: theme.colorScheme.surface,
      child: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(child: Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          Text(l.lockTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l.lockBody, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _unlock, icon: const Icon(Icons.fingerprint), label: Text(l.lockUnlock)),
        ]),
      ))),
    );
  }
}
