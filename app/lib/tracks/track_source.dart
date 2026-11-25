import 'dart:convert';

import 'package:http/http.dart' as http;

import '../search/album_search.dart';
import '../shelf/shelf_data.dart';

/// Track lists to suggest for an album. An interface so the screens can be
/// tested offline.
abstract class TrackSource {
  /// The track list of the release group [musicbrainzId]; empty when
  /// MusicBrainz has none.
  Future<List<Track>> trackList(String musicbrainzId);
}

class MusicBrainzTracks implements TrackSource {
  MusicBrainzTracks(
    this._client, {
    String contact = '',
    this.retryAfter = const Duration(milliseconds: 1100),
  }) : _headers = musicBrainzHeaders(contact);

  final http.Client _client;
  final Map<String, String> _headers;

  /// MusicBrainz allows one request a second; it answers 503 otherwise.
  final Duration retryAfter;

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final url = Uri.https('musicbrainz.org', '/ws/2/$path', {
      ...query,
      'fmt': 'json',
    });
    var response = await _client.get(url, headers: _headers);
    if (response.statusCode == 503) {
      await Future<void>.delayed(retryAfter);
      response = await _client.get(url, headers: _headers);
    }
    if (response.statusCode != 200) {
      throw http.ClientException('MusicBrainz answered ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  @override
  Future<List<Track>> trackList(String musicbrainzId) async {
    final releases =
        (await _get('release', {
              'release-group': musicbrainzId,
              'status': 'official',
              'inc': 'media',
              'limit': '100',
            }))['releases']
            as List;
    final id = pickRelease(releases);
    if (id == null) return const [];
    await Future<void>.delayed(retryAfter);
    final release = await _get('release/$id', {'inc': 'recordings'});
    return [
      for (final medium in release['media'] as List)
        for (final t in medium['tracks'] ?? const [])
          Track(
            disc: medium['position'],
            position: t['position'],
            title: t['title'],
            lengthMs: t['length'],
          ),
    ];
  }

  /// The earliest release with the track counts most releases share: the
  /// original album rather than a deluxe edition with a bonus disc.
  static String? pickRelease(List releases) {
    String shape(Map r) =>
        [for (final m in r['media'] as List) m['track-count']].join('+');
    final counts = <String, int>{};
    for (final r in releases) {
      if ((r['media'] as List).isEmpty) continue;
      counts.update(shape(r), (n) => n + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) return null;
    final common = counts.entries
        .reduce((a, b) => b.value > a.value ? b : a)
        .key;
    // Releases without a date go last.
    String date(Map r) =>
        (r['date'] as String?)?.isNotEmpty == true ? r['date'] : '9999';
    final candidates = [
      for (final r in releases)
        if ((r['media'] as List).isNotEmpty && shape(r) == common) r as Map,
    ]..sort((a, b) => date(a).compareTo(date(b)));
    return candidates.first['id'];
  }
}
