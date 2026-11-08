/// How recently a node must have been heard to show on Nodes and Map.
enum BastionHeardWithin {
  any('Any time', null),
  hour('1 hour', Duration(hours: 1)),
  day('24 hours', Duration(hours: 24)),
  week('7 days', Duration(days: 7));

  const BastionHeardWithin(this.label, this.window);

  /// Short chip label.
  final String label;

  /// The window, or null for no limit.
  final Duration? window;

  /// Whether a node last heard at [lastHeard] passes at [now]. Nodes never
  /// heard pass only with [any]; [always] (your own radio) always passes.
  bool matches(DateTime? lastHeard, DateTime now, {bool always = false}) {
    final w = window;
    if (w == null || always) return true;
    if (lastHeard == null) return false;
    return now.difference(lastHeard) <= w;
  }

  static BastionHeardWithin fromName(String? name) =>
      values.where((v) => v.name == name).firstOrNull ?? any;
}
