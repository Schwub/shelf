import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class Album {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.musicbrainzId,
    this.year,
    this.coverUrl,
  });

  final String id, title, artist;
  final String? musicbrainzId;
  final int? year;
  final String? coverUrl;
}

/// An album on the user's shelf. [rating] is in half stars (1–10).
@immutable
class ShelfEntry {
  const ShelfEntry({
    required this.id,
    required this.album,
    this.rating,
    this.comment,
    this.tagIds = const {},
  });

  final String id;
  final Album album;
  final int? rating;
  final String? comment;
  final Set<String> tagIds;
}

/// A key of the shelf's filter bar: one of the user's tags.
@immutable
class ShelfFilter {
  const ShelfFilter({required this.tagId, required this.label});

  final String tagId, label;
}

@immutable
class Shelf {
  const Shelf({required this.entries, this.filters = const []});

  /// Newest first.
  final List<ShelfEntry> entries;

  /// In the user's order; "All" is implicit.
  final List<ShelfFilter> filters;

  /// Entries with [filter]'s tag, or all of them for null ("All").
  List<ShelfEntry> matching(ShelfFilter? filter) => filter == null
      ? entries
      : entries.where((e) => e.tagIds.contains(filter.tagId)).toList();
}

/// The signed-in user's shelf. An interface so the screens can be tested
/// without a server.
abstract class ShelfRepository {
  Future<Shelf> load();

  /// Rating in half stars or null; an empty comment is stored as none.
  Future<void> save(String entryId, {int? rating, String? comment});

  Future<void> remove(String entryId);

  /// Adds the album with this MusicBrainz ID to the shelf: the add-album
  /// function puts it in the shared catalog (with its cover) if needed.
  Future<void> add(String musicbrainzId, {int? rating, String? comment});
}

class SupabaseShelfRepository implements ShelfRepository {
  SupabaseShelfRepository(this._db);

  final SupabaseClient _db;

  @override
  Future<Shelf> load() async {
    // Row-level security limits every table to the signed-in user.
    final (entries, filters, tags, groups) = await (
      _db
          .from('shelf_entries')
          .select(
            'id, rating, comment, '
            'album:albums(id, musicbrainz_id, title, artist, year, cover_url), '
            'entry_tags(tag_id)',
          )
          .order('created_at', ascending: false),
      _db
          .from('shelf_filters')
          .select('tag_id')
          .order('position', ascending: true),
      _db.from('tags').select('id, name, group_id'),
      _db.from('tag_groups').select('id, hidden'),
    ).wait;
    final hidden = {
      for (final g in groups)
        if (g['hidden'] == true) g['id'] as String,
    };
    final tagNames = {
      for (final t in tags)
        if (!hidden.contains(t['group_id'])) t['id'] as String: t['name'],
    };
    return Shelf(
      entries: [
        for (final e in entries)
          ShelfEntry(
            id: e['id'],
            album: _album(e['album']),
            rating: e['rating'],
            comment: e['comment'],
            tagIds: {for (final t in e['entry_tags']) t['tag_id'] as String},
          ),
      ],
      filters: [
        for (final f in filters)
          if (tagNames[f['tag_id']] case final String name)
            ShelfFilter(tagId: f['tag_id'], label: name),
      ],
    );
  }

  static Album _album(Map<String, dynamic> a) => Album(
    id: a['id'],
    musicbrainzId: a['musicbrainz_id'],
    title: a['title'],
    artist: a['artist'],
    year: a['year'],
    coverUrl: a['cover_url'],
  );

  @override
  Future<void> save(String entryId, {int? rating, String? comment}) => _db
      .from('shelf_entries')
      .update({'rating': rating, 'comment': _comment(comment)})
      .eq('id', entryId);

  static String? _comment(String? c) =>
      c == null || c.trim().isEmpty ? null : c.trim();

  @override
  Future<void> add(String musicbrainzId, {int? rating, String? comment}) async {
    final response = await _db.functions.invoke(
      'add-album',
      body: {'musicbrainz_id': musicbrainzId},
    );
    await _db.from('shelf_entries').insert({
      'album_id': (response.data as Map<String, dynamic>)['id'],
      'rating': rating,
      'comment': _comment(comment),
    });
  }

  @override
  Future<void> remove(String entryId) =>
      _db.from('shelf_entries').delete().eq('id', entryId);
}
