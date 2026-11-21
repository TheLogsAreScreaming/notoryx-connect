import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// What a web page says about itself: its site, title and a short line.
@immutable
class LinkPreview {
  const LinkPreview({required this.host, required this.title, this.description});
  final String host;
  final String title;
  final String? description;
}

/// Downloads a page's HTML; swapped out in tests.
abstract interface class LinkPageFetcher {
  /// The start of the page at [uri] as text, or null when it isn't an HTML
  /// page or can't be fetched.
  Future<String?> fetch(Uri uri);
}

class HttpLinkPageFetcher implements LinkPageFetcher {
  const HttpLinkPageFetcher();

  /// Only this much of a page is read; titles are near the top.
  static const maxBytes = 256 * 1024;
  static const timeout = Duration(seconds: 6);

  @override
  Future<String?> fetch(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = 'Mozilla/5.0 (compatible; link preview)';
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = true;
      request.maxRedirects = 3;
      request.headers.set(HttpHeaders.acceptHeader, 'text/html');
      final response = await request.close().timeout(timeout);
      final type = response.headers.contentType;
      if (response.statusCode != 200 || type == null || type.mimeType != 'text/html') {
        await response.drain<void>();
        return null;
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length >= maxBytes) break;
      }
      return utf8.decode(bytes.length > maxBytes ? bytes.sublist(0, maxBytes) : bytes, allowMalformed: true);
    } on Object catch (e) {
      debugPrint('Link preview failed for ${uri.host}: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

/// Finds the first web link in a message and fetches a short preview of it.
/// Only used when link previews are switched on in Privacy; nothing is
/// fetched otherwise.
class BastionLinkPreviews {
  BastionLinkPreviews({LinkPageFetcher fetcher = const HttpLinkPageFetcher()}) : _fetcher = fetcher;

  static BastionLinkPreviews instance = BastionLinkPreviews();

  final LinkPageFetcher _fetcher;
  final Map<String, Future<LinkPreview?>> _cache = {};

  /// Previews kept in memory at once.
  static const cacheSize = 100;

  /// The longest description kept.
  static const maxDescription = 200;

  static final _link = RegExp(r'https://[^\s<>"]+', caseSensitive: false);

  /// The first https link in [text], or null. Plain http links are left
  /// alone, so a preview never travels unencrypted.
  static Uri? firstLink(String text) {
    final match = _link.firstMatch(text);
    if (match == null) return null;
    // Trailing punctuation belongs to the sentence, not the link.
    final raw = match.group(0)!.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return null;
    return uri;
  }

  /// The preview for [uri], fetched once and then kept.
  Future<LinkPreview?> previewFor(Uri uri) {
    final key = uri.toString();
    final cached = _cache[key];
    if (cached != null) return cached;
    if (_cache.length >= cacheSize) _cache.remove(_cache.keys.first);
    return _cache[key] = _load(uri);
  }

  Future<LinkPreview?> _load(Uri uri) async {
    final html = await _fetcher.fetch(uri);
    if (html == null) return null;
    return parse(uri, html);
  }

  /// Reads the title and description from a page's HTML.
  static LinkPreview? parse(Uri uri, String html) {
    String? meta(String name) {
      final tag = RegExp('<meta[^>]+(?:property|name)=["\']$name["\'][^>]*>', caseSensitive: false).firstMatch(html);
      if (tag == null) return null;
      final content = RegExp('content=["\']([^"\']*)["\']', caseSensitive: false).firstMatch(tag.group(0)!);
      return content?.group(1);
    }

    final titleTag = RegExp(r'<title[^>]*>([\s\S]*?)</title>', caseSensitive: false).firstMatch(html)?.group(1);
    final title = _clean(meta('og:title') ?? titleTag);
    if (title == null) return null;
    var description = _clean(meta('og:description') ?? meta('description'));
    if (description != null && description.length > maxDescription) {
      description = '${description.substring(0, maxDescription).trimRight()}…';
    }
    final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
    return LinkPreview(host: host, title: title, description: description);
  }

  static String? _clean(String? text) {
    if (text == null) return null;
    final out = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return out.isEmpty ? null : out;
  }
}
