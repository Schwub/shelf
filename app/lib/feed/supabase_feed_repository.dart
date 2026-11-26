import 'package:supabase_flutter/supabase_flutter.dart';

import '../shelf/shelf.dart';
import 'feed_repository.dart';

class SupabaseFeedRepository implements FeedRepository {
  SupabaseFeedRepository(this._db);

  final SupabaseClient _db;

  // The feed view applies row-level security: friends' visible entries.
  @override
  Future<List<FeedItem>> page({FeedItem? after}) async {
    var query = _db
        .from('feed')
        .select(
          'entry_id, user_id, kind, at, cursor, rating, album_id, musicbrainz_id, '
          'title, artist, year, cover_url, name',
        );
    if (after != null) {
      // Keyset paging: items sharing a time are ordered by entry.
      final at = '"${after.cursor}"';
      query = query.or('at.lt.$at,and(at.eq.$at,entry_id.gt.${after.entryId})');
    }
    final rows = await query
        .order('at', ascending: false)
        .order('entry_id', ascending: true)
        .limit(FeedRepository.pageSize);
    return [
      for (final r in rows)
        FeedItem(
          kind: FeedKind.values.byName(r['kind']),
          at: DateTime.parse(r['at']),
          cursor: r['cursor'],
          entryId: r['entry_id'],
          friendId: r['user_id'],
          friendName: r['name'],
          rating: r['rating'],
          album: Album(
            id: r['album_id'],
            musicbrainzId: r['musicbrainz_id'],
            title: r['title'],
            artist: r['artist'],
            year: r['year'],
            coverUrl: r['cover_url'],
          ),
        ),
    ];
  }
}
