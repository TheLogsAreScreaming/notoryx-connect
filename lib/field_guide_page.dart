import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Short, practical tips for getting on the mesh and keeping a radio
/// running in the field, as in NOTORYX Core. Works offline.
class FieldGuidePage extends StatelessWidget {
  const FieldGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sections = [
      (Icons.hub_outlined, l.gdSecMesh, [l.gdMesh1, l.gdMesh2, l.gdMesh3, l.gdMesh4]),
      (Icons.ac_unit, l.gdSecCold, [l.gdCold1, l.gdCold2, l.gdCold3]),
      (Icons.solar_power_outlined, l.gdSecSolar, [l.gdSolar1, l.gdSolar2]),
      (Icons.settings_input_antenna, l.gdSecAntenna, [l.gdAnt1, l.gdAnt2]),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.gdTitle)),
      body: ListView(
        padding: NxSpace.page,
        children: [
          for (final (icon, title, tips) in sections) ...[
            NxSectionLabel(title),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(NxSpace.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final tip in tips)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: NxSpace.xxs),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ExcludeSemantics(child: Icon(icon, size: 18)),
                        const SizedBox(width: NxSpace.sm),
                        Expanded(child: Text(tip)),
                      ]),
                    ),
                ]),
              ),
            ),
          ],
          NxSectionLabel(l.gdSecMore),
          Card(child: Padding(padding: const EdgeInsets.all(NxSpace.md), child: SelectableText(l.gdMore))),
        ],
      ),
    );
  }
}
