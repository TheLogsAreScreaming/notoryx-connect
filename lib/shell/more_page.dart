part of '../main.dart';

/// The places the shell can switch to. Tools and Settings both live on the
/// More tab, each as one side of its switch.
enum ShellTab {
  home,
  chats,
  nodes,
  map,
  tools,
  settings;

  /// Position in the bottom bar.
  int get destination => index > 4 ? 4 : index;

  bool get isMore => this == tools || this == settings;
}

/// The More tab: Tools and Settings behind one switch, as in NOTORYX Core,
/// so the bar keeps five tabs that fit any phone.
class _MorePage extends StatelessWidget {
  const _MorePage({required this.section, required this.onSection, required this.tools, required this.settings});

  final ShellTab section;
  final ValueChanged<ShellTab> onSection;
  final Widget tools;
  final Widget settings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(NxSpace.md, NxSpace.sm, NxSpace.md, 0),
          child: SegmentedButton<ShellTab>(
            key: const ValueKey('more-switch'),
            segments: [
              ButtonSegment(value: ShellTab.tools, icon: const Icon(Icons.build_outlined), label: Text(l.tabTools)),
              ButtonSegment(
                  value: ShellTab.settings, icon: const Icon(Icons.settings_outlined), label: Text(l.tabSettings)),
            ],
            selected: {section},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onSection(s.single),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: section == ShellTab.tools ? 0 : 1,
            children: [tools, settings],
          ),
        ),
      ],
    );
  }
}
