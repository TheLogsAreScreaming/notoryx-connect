import 'bastion_chat_message.dart';
import 'bastion_conversations.dart';
import 'bastion_node_vault.dart';
import 'bastion_waypoints.dart';
import 'meshtastic_node_database.dart';

/// A node found by search: one the radio knows now, or one this phone
/// remembers.
class SearchNode {
  const SearchNode({
    required this.num,
    required this.name,
    this.shortName,
    this.lastHeard,
    this.remembered = false,
  });

  final int num;
  final String name;
  final String? shortName;
  final DateTime? lastHeard;

  /// Only in the remembered list, not in the radio's current node list.
  final bool remembered;

  String get id => '!${num.toRadixString(16).padLeft(8, '0')}';
}

/// A message found by search.
class SearchMessage {
  const SearchMessage(this.message, this.conversation);
  final BastionChatMessage message;
  final BastionConversation conversation;
}

/// A channel found by search.
class SearchChannel {
  const SearchChannel(this.index, this.name);
  final int index;
  final String name;
}

/// A page or feature of the app, found by its name or description.
class SearchFeature {
  const SearchFeature({
    required this.id,
    required this.title,
    required this.subtitle,
    this.keywords = '',
  });

  /// Stable identifier the page uses to open the feature.
  final String id;
  final String title;
  final String subtitle;

  /// Extra words that should find it, in the current language.
  final String keywords;
}

class AppSearchResults {
  const AppSearchResults({
    this.nodes = const [],
    this.messages = const [],
    this.channels = const [],
    this.places = const [],
    this.features = const [],
  });

  final List<SearchNode> nodes;
  final List<SearchMessage> messages;
  final List<SearchChannel> channels;
  final List<MeshWaypoint> places;
  final List<SearchFeature> features;

  bool get isEmpty =>
      nodes.isEmpty && messages.isEmpty && channels.isEmpty && places.isEmpty && features.isEmpty;
}

/// Searches everything the app holds on this phone. Nothing is sent.
abstract final class BastionAppSearch {
  /// Results per group, so a common word can't flood the page.
  static const nodeLimit = 30;
  static const messageLimit = 40;

  static AppSearchResults run(
    String query, {
    List<MeshtasticNode> nodes = const [],
    List<BastionNodeRecord> remembered = const [],
    List<BastionChatMessage> messages = const [],
    List<SearchChannel> channels = const [],
    List<MeshWaypoint> places = const [],
    List<SearchFeature> features = const [],
  }) {
    final q = fold(query.trim());
    if (q.isEmpty) return const AppSearchResults();
    // "!b2c6" and "b2c6" both find a node ID.
    final idQuery = q.startsWith('!') ? q.substring(1) : q;

    bool nodeMatches(int num, String? name, String? short) =>
        _has(name, q) ||
        _has(short, q) ||
        (idQuery.isNotEmpty && num.toRadixString(16).padLeft(8, '0').contains(idQuery));

    final foundNodes = <int, SearchNode>{};
    for (final n in nodes) {
      if (!nodeMatches(n.num, n.longName, n.shortName)) continue;
      foundNodes[n.num] = SearchNode(
        num: n.num,
        name: n.displayName,
        shortName: n.shortName,
        lastHeard: n.lastHeard,
      );
    }
    for (final r in remembered) {
      if (foundNodes.containsKey(r.num) || !nodeMatches(r.num, r.longName, r.shortName)) continue;
      foundNodes[r.num] = SearchNode(
        num: r.num,
        name: r.displayName,
        shortName: r.shortName,
        lastHeard: r.lastSeen,
        remembered: true,
      );
    }
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final nodeList = foundNodes.values.toList()
      ..sort((a, b) {
        // Names that start with the query first, then the most recently heard.
        final sa = fold(a.name).startsWith(q) ? 0 : 1;
        final sb = fold(b.name).startsWith(q) ? 0 : 1;
        if (sa != sb) return sa - sb;
        return (b.lastHeard ?? epoch).compareTo(a.lastHeard ?? epoch);
      });

    final messageList = [
      for (final m in messages)
        if (!m.isReaction && _has(m.text, q)) SearchMessage(m, BastionConversation.of(m)),
    ]..sort((a, b) => b.message.timestamp.compareTo(a.message.timestamp));

    return AppSearchResults(
      nodes: nodeList.take(nodeLimit).toList(),
      messages: messageList.take(messageLimit).toList(),
      channels: [for (final c in channels) if (_has(c.name, q)) c],
      places: [
        for (final p in places)
          if (_has(p.name, q) || _has(p.description, q)) p,
      ],
      features: [
        for (final f in features)
          if (_has(f.title, q) || _has(f.subtitle, q) || _has(f.keywords, q)) f,
      ],
    );
  }

  static bool _has(String? text, String q) => text != null && fold(text).contains(q);

  /// Lower case without accents, so "cafe" finds "Café" and "nœud" finds "noeud".
  static String fold(String text) {
    final lower = text.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final c = String.fromCharCode(rune);
      out.write(_plain[c] ?? c);
    }
    return out.toString();
  }

  static const _plain = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
    'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'œ': 'oe',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'ß': 'ss',
  };
}
