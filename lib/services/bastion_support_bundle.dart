/// Facts about the app and radio for a support report. Every field is
/// something safe to share: no keys, messages, positions or node lists.
class SupportFacts {
  const SupportFacts({
    required this.appVersion,
    required this.platform,
    required this.locale,
    required this.connection,
    required this.link,
    this.radioModel,
    this.firmware,
    this.region,
    this.preset,
    required this.nodesHeard,
    required this.nodesKnown,
    required this.channelsInUse,
    required this.settings,
  });

  final String appVersion;
  final String platform;
  final String locale;
  final String connection;
  final String link;
  final String? radioModel;
  final String? firmware;
  final String? region;
  final String? preset;
  final int nodesHeard;
  final int nodesKnown;
  final int channelsInUse;

  /// Setting name to value, e.g. `MQTT proxy: off`. Only on/off and choice
  /// settings; nothing typed in by the person.
  final Map<String, String> settings;
}

/// Builds the plain-text support report and keeps sensitive things out of it.
abstract final class BastionSupportBundle {
  // Long base64 runs (channel keys, public keys), hex keys, coordinates,
  // e-mail addresses, Bluetooth addresses and node IDs that could identify
  // someone. A base64 run must hold a digit or + / = somewhere, so long
  // CamelCase error names (useful in a report) are kept.
  static final _base64 = RegExp(r'(?<![A-Za-z0-9+/])(?=[A-Za-z0-9+/]*[0-9+/])[A-Za-z0-9+/]{20,}={0,2}');
  static final _mac = RegExp(r'\b(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b');
  static final _hexKey = RegExp(r'\b[0-9a-fA-F]{32,}\b');
  static final _coordinates = RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}');
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  static final _nodeId = RegExp(r'![0-9a-fA-F]{8}\b');

  /// Removes anything that looks like a key, a position, an e-mail address,
  /// a Bluetooth address or a node ID from [text], and each of [names]
  /// (this radio's names).
  static String redact(String text, [Iterable<String> names = const []]) {
    var out = text;
    for (final n in names) {
      if (n.trim().length >= 2) out = out.replaceAll(n, '[radio name]');
    }
    return out
      .replaceAll(_mac, '[address removed]')
      .replaceAll(_coordinates, '[position removed]')
      .replaceAll(_email, '[e-mail removed]')
      .replaceAll(_hexKey, '[key removed]')
      .replaceAll(_base64, '[key removed]')
      .replaceAll(_nodeId, '![id removed]');
  }

  static String build({
    required SupportFacts facts,
    required Iterable<Object> connectionLog,
    required Iterable<Object> errors,
    Iterable<String> radioNames = const [],
    DateTime? now,
  }) {
    final b = StringBuffer()
      ..writeln('NOTORYX Connect support report')
      ..writeln('Made: ${(now ?? DateTime.now()).toIso8601String()}')
      ..writeln('No keys, messages, positions, node names, IDs or Bluetooth addresses are included.')
      ..writeln()
      ..writeln('App')
      ..writeln('- Version: ${facts.appVersion}')
      ..writeln('- Platform: ${facts.platform}')
      ..writeln('- Language: ${facts.locale}')
      ..writeln()
      ..writeln('Radio')
      ..writeln('- Connection: ${facts.connection} (${facts.link})')
      ..writeln('- Model: ${facts.radioModel ?? '-'}')
      ..writeln('- Firmware: ${facts.firmware ?? '-'}')
      ..writeln('- Region / preset: ${facts.region ?? '-'} / ${facts.preset ?? '-'}')
      ..writeln('- Nodes heard / known: ${facts.nodesHeard} / ${facts.nodesKnown}')
      ..writeln('- Channels in use: ${facts.channelsInUse}')
      ..writeln()
      ..writeln('Settings');
    for (final e in facts.settings.entries) {
      b.writeln('- ${e.key}: ${e.value}');
    }
    b
      ..writeln()
      ..writeln('Recent app errors');
    final errorLines = [for (final e in errors) redact('$e', radioNames)];
    if (errorLines.isEmpty) b.writeln('- none');
    for (final line in errorLines) {
      b.writeln('- $line');
    }
    b
      ..writeln()
      ..writeln('Connection log');
    final logLines = [for (final e in connectionLog) redact('$e', radioNames)];
    if (logLines.isEmpty) b.writeln('- empty');
    for (final line in logLines) {
      b.writeln(line);
    }
    return b.toString();
  }
}
