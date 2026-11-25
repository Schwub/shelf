import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../search/album_search.dart';

/// What a shared link turned out to be (the resolve-link function).
sealed class Resolved {
  const Resolved();

  /// Throws [UnsupportedLink] or [LinkNotFound] for the function's errors.
  factory Resolved.fromJson(Map<String, dynamic> json) =>
      switch (json['kind']) {
        'album' => FoundAlbum(
          SearchResult(
            musicbrainzId: json['musicbrainz_id'] as String,
            title: json['title'] as String,
            artist: json['artist'] as String,
            year: json['year'] as int?,
          ),
        ),
        'unknown' => UnknownAlbum(
          title: json['title'] as String,
          artist: json['artist'] as String,
          year: json['year'] as int?,
          coverUrl: json['cover_url'] as String?,
        ),
        'not_album' => NotAnAlbum(json['what'] as String),
        _ => throw FormatException('Unknown kind: ${json['kind']}'),
      };
}

/// An album MusicBrainz knows.
class FoundAlbum extends Resolved {
  const FoundAlbum(this.album);
  final SearchResult album;
}

/// An album MusicBrainz doesn't know: what its page says, to add it by hand.
class UnknownAlbum extends Resolved {
  const UnknownAlbum({
    required this.title,
    required this.artist,
    this.year,
    this.coverUrl,
    this.cover,
  });

  final String title, artist;
  final int? year;
  final String? coverUrl;

  /// The page's cover, downloaded; null when there is none or it failed.
  final Uint8List? cover;
}

/// A track, playlist, artist or other page: "track", "playlist", "artist"
/// or "other".
class NotAnAlbum extends Resolved {
  const NotAnAlbum(this.what);
  final String what;
}

/// Not a Spotify or Bandcamp link.
class UnsupportedLink implements Exception {}

/// The page is gone.
class LinkNotFound implements Exception {}

/// Resolving shared links. An interface so the screens can be tested offline.
abstract class LinkResolver {
  Future<Resolved> resolve(Uri link);
}

class SupabaseLinkResolver implements LinkResolver {
  SupabaseLinkResolver(this._db, this._client);

  final SupabaseClient _db;
  final http.Client _client;

  @override
  Future<Resolved> resolve(Uri link) async {
    final Resolved resolved;
    try {
      final response = await _db.functions.invoke(
        'resolve-link',
        body: {'url': '$link'},
      );
      resolved = Resolved.fromJson(response.data as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw switch (e.status) {
        400 => UnsupportedLink(),
        404 => LinkNotFound(),
        _ => e,
      };
    }
    if (resolved case UnknownAlbum(:final coverUrl?)) {
      return UnknownAlbum(
        title: resolved.title,
        artist: resolved.artist,
        year: resolved.year,
        cover: await _download(coverUrl),
      );
    }
    return resolved;
  }

  /// The photo for adding the album by hand; it goes up as if picked.
  Future<Uint8List?> _download(String url) async {
    try {
      final response = await _client.get(Uri.parse(url));
      return response.statusCode == 200 ? response.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }
}
