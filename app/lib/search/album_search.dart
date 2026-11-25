import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'musicbrainz.dart';

/// An album found on MusicBrainz (a release group).
@immutable
class SearchResult {
  const SearchResult({
    required this.musicbrainzId,
    required this.title,
    required this.artist,
    this.year,
  });

  final String musicbrainzId, title, artist;
  final int? year;

  /// Small cover straight from the Cover Art Archive; added albums get our
  /// own copy (the add-album function).
  String get thumbnailUrl =>
      'https://coverartarchive.org/release-group/$musicbrainzId/front-250';
  String get coverUrl =>
      'https://coverartarchive.org/release-group/$musicbrainzId/front-500';
}

/// Finding albums. An interface so the screens can be tested offline.
abstract class AlbumSearch {
  Future<List<SearchResult>> search(String query);
}

class MusicBrainzSearch implements AlbumSearch {
  MusicBrainzSearch(this._musicBrainz);

  final MusicBrainz _musicBrainz;

  /// Only the newest search is sent; older ones still waiting for their
  /// turn are dropped.
  int _latest = 0;

  /// Lucene's special characters, which MusicBrainz queries would otherwise
  /// read as syntax ("AC/DC", "Sigur Rós: …").
  static final _special = RegExp(r'[+\-&|!(){}\[\]^"~*?:\\/]');

  /// Every word must match: MusicBrainz joins words with OR otherwise, and
  /// a made-up title still brings 25 loose matches.
  static String query(String text) {
    final words = [
      for (final w in text.trim().split(RegExp(r'\s+')))
        w.replaceAllMapped(_special, (m) => '\\${m[0]}'),
    ];
    return '(${words.join(' AND ')}) AND primarytype:album';
  }

  @override
  Future<List<SearchResult>> search(String text) async {
    final search = ++_latest;
    final response = await _musicBrainz.get(
      Uri.https('musicbrainz.org', '/ws/2/release-group', {
        'query': query(text),
        'fmt': 'json',
        'limit': '25',
      }),
      wanted: () => search == _latest,
    );
    if (response.statusCode != 200) {
      throw http.ClientException('MusicBrainz answered ${response.statusCode}');
    }
    final groups = jsonDecode(
      utf8.decode(response.bodyBytes),
    )['release-groups'];
    return [
      for (final g in groups as List)
        SearchResult(
          musicbrainzId: g['id'],
          title: g['title'],
          artist: [
            for (final c in g['artist-credit'] ?? const [])
              '${c['name']}${c['joinphrase'] ?? ''}',
          ].join().trim(),
          year: int.tryParse(
            (g['first-release-date'] ?? '').padRight(4).substring(0, 4),
          ),
        ),
    ];
  }
}
