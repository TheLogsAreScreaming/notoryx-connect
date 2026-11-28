import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_local_names.dart';

/// Asks for a local name for a node. Returns the new name, '' to go back to
/// the node's own name, or null when cancelled.
Future<String?> showLocalNameDialog(
  BuildContext context, {
  required String current,
  required String radioName,
}) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController(text: current);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.localNameTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.localNameHint(radioName)),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('local-name-field'),
            controller: controller,
            autofocus: true,
            maxLength: BastionLocalNames.maxLength,
            decoration: InputDecoration(labelText: l.localNameTitle),
          ),
        ],
      ),
      actions: [
        if (current.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: Text(l.localNameClear),
          ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
          child: Text(l.commonSave),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
