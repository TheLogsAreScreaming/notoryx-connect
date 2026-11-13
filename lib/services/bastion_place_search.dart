import 'dart:convert';
import 'dart:io';

import '../app_version.dart';
import 'bastion_waypoints.dart';
import 'meshtastic_node_database.dart';

/// Where a search result came from.
enum PlaceKind { node, waypoint, online }

/// One thing the map can jump to.
class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.kind,
    this.detail = '',
  });

  final String name;
  final String detail;
  final double latitude;
  final double longitude;
  final PlaceKind kind;
}

/// Finds nodes and waypoints by name without the internet.
///
/// Case and common accents are ignored. Names that start with the search
/// come first, then names with a word that starts with it, then the rest.
abstract final class BastionPlaceSearch {
  static const maxResults = 30;

  static List<PlaceResult> local(
    String query, {
    required Iterable<MeshtasticNode> nodes,
    required Iterable<MeshWaypoint> waypoints,
  }) {
    final q = fold(query.trim());
    if (q.isEmpty) return const [];
    final ranked = <(int, PlaceResult)>[];
    void consider(PlaceResult r, List<String> names) {
      int? best;
      for (final name in names) {
        final rank = _rank(fold(name), q);
        if (rank != null && (best == null || rank < best)) best = rank;
      }
      if (best != null) ranked.add((best, r));
    }

    for (final w in waypoints) {
      if (w.name.isEmpty && w.description.isEmpty) continue;
      consider(
        PlaceResult(
          name: w.name,
          detail: w.description,
          latitude: w.latitude,
          longitude: w.longitude,
          kind: PlaceKind.waypoint,
        ),
        [w.name, w.description],
      );
    }
    for (final n in nodes) {
      if (!n.hasPosition) continue;
      consider(
        PlaceResult(
          name: n.displayName,
          detail: n.shortName ?? '',
          latitude: n.latitude!,
          longitude: n.longitude!,
          kind: PlaceKind.node,
        ),
        [n.displayName, n.shortName ?? '', n.id ?? '', n.num.toRadixString(16)],
      );
    }
    ranked.sort((a, b) {
      final byRank = a.$1.compareTo(b.$1);
      return byRank != 0 ? byRank : a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase());
    });
    return [for (final r in ranked.take(maxResults)) r.$2];
  }

  /// 0 = starts with, 1 = a word starts with, 2 = contains, null = no match.
  static int? _rank(String name, String q) {
    if (name.isEmpty) return null;
    if (name.startsWith(q)) return 0;
    if (name.split(RegExp(r'[\s\-_/,.!]+')).any((w) => w.startsWith(q))) return 1;
    if (name.contains(q)) return 2;
    return null;
  }

  static const _accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ß': 'ss',
  };

  /// Lower case with common accents removed, so "Peña" finds "pena".
  static String fold(String s) {
    final lower = s.toLowerCase();
    final out = StringBuffer();
    for (final ch in lower.split('')) {
      out.write(_accents[ch] ?? ch);
    }
    return out.toString();
  }
}

/// Looks up towns, peaks, trailheads and addresses with OpenStreetMap's
/// Nominatim service. Only called when someone presses "Search online"; it
/// sees the search text and the phone's IP address. Follows the usage policy:
/// one request per press, at most one a second, with an identifying agent.
class NominatimPlaceSearch {
  NominatimPlaceSearch({HttpClient Function()? client, DateTime Function()? clock})
    : _client = client ?? HttpClient.new,
      _clock = clock ?? DateTime.now;

  final HttpClient Function() _client;
  final DateTime Function() _clock;
  DateTime? _last;

  static const host = 'nominatim.openstreetmap.org';
  static const userAgent = 'NOTORYX-Connect/$bastionAppVersion (+https://meshmayhem.org)';
  static const limit = 10;

  /// Whether a search now would break the one-per-second rule.
  bool get tooSoon {
    final last = _last;
    return last != null && _clock().difference(last) < const Duration(seconds: 1);
  }

  Future<List<PlaceResult>> search(String query, {String? language}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    if (tooSoon) throw StateError('Wait a second before searching again.');
    _last = _clock();
    final uri = Uri.https(host, '/search', {'q': q, 'format': 'jsonv2', 'limit': '$limit'});
    final client = _client()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      if (language != null) request.headers.set(HttpHeaders.acceptLanguageHeader, language);
      final response = await request.close().timeout(const Duration(seconds: 15));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('Place search answered ${response.statusCode}.');
      }
      return parse(body);
    } finally {
      client.close(force: true);
    }
  }

  /// Reads a Nominatim jsonv2 reply, skipping anything without a position.
  static List<PlaceResult> parse(String body) {
    final list = jsonDecode(body);
    if (list is! List) throw const FormatException('Place search sent an unexpected reply.');
    final results = <PlaceResult>[];
    for (final item in list) {
      if (item is! Map) continue;
      final lat = double.tryParse('${item['lat']}');
      final lon = double.tryParse('${item['lon']}');
      if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) continue;
      final full = '${item['display_name'] ?? ''}';
      final name = '${item['name'] ?? ''}'.trim();
      final title = name.isNotEmpty ? name : full.split(',').first.trim();
      if (title.isEmpty) continue;
      final rest = full.startsWith(title) ? full.substring(title.length).replaceFirst(RegExp(r'^,\s*'), '') : full;
      results.add(PlaceResult(name: title, detail: rest, latitude: lat, longitude: lon, kind: PlaceKind.online));
    }
    return results;
  }
}
