import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tracks/track_source.dart';
import 'shelf.dart';
import 'shelf_repository.dart';

class SupabaseShelfRepository implements ShelfRepository {
  SupabaseShelfRepository(this._db, this._tracks);

  final SupabaseClient _db;
  final TrackSource _tracks;

  String get _me => _db.auth.currentUser!.id;

  final _changes = ValueNotifier(0);

  @override
  Listenable get changes => _changes;

  @override
  Future<List<Track>> trackList(String musicbrainzId) =>
      _tracks.trackList(musicbrainzId);

  @override
  Future<Shelf> load() => _load(_me);

  @override
  Future<Shelf> loadFriend(String userId) => _load(userId);

  /// [userId]'s shelf. Every query filters by owner: friends can read each
  /// other's entries, tags, groups and filters (row-level security leaves
  /// out hidden entries).
  Future<Shelf> _load(String userId) async {
    final (entries, filters, tags, groups) = await (
      _db
          .from('shelf_entries')
          .select(
            'id, created_at, rating, comment, hidden, added_from_name, '
            'album:albums(id, musicbrainz_id, title, artist, year, cover_url), '
            'entry_tags(tag_id), '
            'entry_tracks(disc, position, title, length_ms, favorite)',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false),
      _db
          .from('shelf_filters')
          .select(
            'id, name, tags_match, min_rating, unrated, favorite_tracks, '
            'added_within_days, added_from, added_to, shelf_filter_tags(tag_id)',
          )
          .eq('user_id', userId)
          .order('position', ascending: true),
      // New rows and reordered ones can share a position for a moment.
      _db
          .from('tags')
          .select('id, name, group_id, builtin')
          .eq('user_id', userId)
          .order('position', ascending: true)
          .order('created_at', ascending: true),
      _db
          .from('tag_groups')
          .select(
            'id, name, exclusive, parent_tag_id, builtin, hidden, pick_from_list',
          )
          .eq('user_id', userId)
          .order('position', ascending: true)
          .order('created_at', ascending: true),
    ).wait;
    final tagNames = {for (final t in tags) t['id'] as String: t['name']};
    return Shelf(
      entries: [
        for (final e in entries)
          ShelfEntry(
            id: e['id'],
            album: _album(e['album']),
            addedAt: DateTime.parse(e['created_at']),
            rating: e['rating'],
            comment: e['comment'],
            hidden: e['hidden'],
            addedFromName: e['added_from_name'],
            tagIds: {for (final t in e['entry_tags']) t['tag_id'] as String},
            tracks:
                [
                  for (final t in e['entry_tracks'])
                    Track(
                      disc: t['disc'],
                      position: t['position'],
                      title: t['title'],
                      lengthMs: t['length_ms'],
                      favorite: t['favorite'],
                    ),
                ]..sort(
                  (a, b) => a.disc != b.disc
                      ? a.disc - b.disc
                      : a.position - b.position,
                ),
          ),
      ],
      allFilters: [
        for (final f in filters)
          _filter(f, [
            for (final t in f['shelf_filter_tags']) t['tag_id'] as String,
          ], tagNames),
      ],
      allGroups: [
        for (final g in groups)
          TagGroup(
            id: g['id'],
            name: g['name'],
            exclusive: g['exclusive'],
            parentTagId: g['parent_tag_id'],
            builtin: g['builtin'],
            hidden: g['hidden'],
            pickFromList: g['pick_from_list'],
            tags: [
              for (final t in tags)
                if (t['group_id'] == g['id'])
                  Tag(
                    id: t['id'],
                    groupId: g['id'],
                    name: t['name'],
                    builtin: t['builtin'],
                  ),
            ],
          ),
      ],
    );
  }

  static ShelfFilter _filter(
    Map<String, dynamic> f,
    List<String> tagIds,
    Map<String, dynamic> tagNames,
  ) {
    final filter = ShelfFilter(
      id: f['id'],
      name: f['name'],
      tagIds: tagIds,
      matchAll: f['tags_match'] == 'all',
      minRating: f['min_rating'],
      unrated: f['unrated'],
      favoriteTracks: f['favorite_tracks'],
      addedWithinDays: f['added_within_days'],
      // A date without a time is local midnight.
      addedFrom: _date(f['added_from']),
      addedTo: _date(f['added_to']),
    );
    return filter.copyWith(
      label: f['name'] ?? (filter.isTag ? tagNames[tagIds.single] : 'Filter'),
    );
  }

  static DateTime? _date(String? d) => d == null ? null : DateTime.parse(d);

  /// 2026-11-26.
  static String? _day(DateTime? d) => d?.toIso8601String().substring(0, 10);

  static Album _album(Map<String, dynamic> a) => Album(
    id: a['id'],
    musicbrainzId: a['musicbrainz_id'],
    title: a['title'],
    artist: a['artist'],
    year: a['year'],
    coverUrl: a['cover_url'],
  );

  @override
  Future<void> save(
    String entryId, {
    int? rating,
    String? comment,
    Set<String> removeTags = const {},
    List<String> addTags = const [],
    List<Track>? tracks,
    bool? hidden,
  }) async {
    await _db
        .from('shelf_entries')
        .update({
          'rating': rating,
          'comment': _comment(comment),
          'hidden': ?hidden,
        })
        .eq('id', entryId);
    await _setTags(entryId, removeTags, addTags);
    if (tracks != null) await _setTracks(entryId, tracks);
    _changes.value++;
  }

  /// Replaces the whole list in one transaction.
  Future<void> _setTracks(String entryId, List<Track> tracks) => _db.rpc(
    'set_entry_tracks',
    params: {
      'entry': entryId,
      'tracks': [for (final t in tracks) t.toJson()],
    },
  );

  /// Off before on, so an exclusive group never holds two tags; one at a
  /// time, so a parent tag is on before its sub-tags (the database checks).
  Future<void> _setTags(
    String entryId,
    Set<String> remove,
    List<String> add,
  ) async {
    if (remove.isNotEmpty) {
      await _db
          .from('entry_tags')
          .delete()
          .eq('entry_id', entryId)
          .inFilter('tag_id', remove.toList());
    }
    for (final tag in add) {
      await _db.from('entry_tags').insert({'entry_id': entryId, 'tag_id': tag});
    }
  }

  static String? _comment(String? c) =>
      c == null || c.trim().isEmpty ? null : c.trim();

  @override
  Future<void> add(
    String musicbrainzId, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
    bool hidden = false,
    AddedFrom? addedFrom,
  }) async {
    await _addEntry(
      {'musicbrainz_id': musicbrainzId},
      rating: rating,
      comment: comment,
      tags: tags,
      tracks: tracks,
      hidden: hidden,
      addedFrom: addedFrom,
    );
  }

  @override
  Future<void> addManual(
    ManualAlbum album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
    bool hidden = false,
    AddedFrom? addedFrom,
  }) => _addEntry(
    album.toJson(),
    rating: rating,
    comment: comment,
    tags: tags,
    tracks: tracks,
    hidden: hidden,
    addedFrom: addedFrom,
  );

  /// The add-album function returns the album; then the entry and its tags.
  Future<void> _addEntry(
    Map<String, dynamic> album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
    bool hidden = false,
    AddedFrom? addedFrom,
  }) async {
    final response = await _db.functions.invoke('add-album', body: album);
    final entry = await _db
        .from('shelf_entries')
        .insert({
          'album_id': (response.data as Map<String, dynamic>)['id'],
          'rating': rating,
          'comment': _comment(comment),
          'hidden': hidden,
          'added_from_user_id': ?addedFrom?.userId,
          'added_from_name': ?addedFrom?.name,
        })
        .select('id')
        .single();
    await _setTags(entry['id'], const {}, tags);
    if (tracks.isNotEmpty) await _setTracks(entry['id'], tracks);
    _changes.value++;
  }

  @override
  Future<Tag> createTag(String groupId, String name) async {
    final position = await _next('tags', 'group_id', groupId);
    final tag = await _unique(
      () => _db
          .from('tags')
          .insert({
            'group_id': groupId,
            'name': name.trim(),
            'position': position,
          })
          .select('id, group_id, name')
          .single(),
    );
    _changes.value++;
    return Tag(id: tag['id'], groupId: tag['group_id'], name: tag['name']);
  }

  /// The position after the last row where [column] is [value] (or null).
  Future<int> _next(String table, String column, String? value) async {
    final query = _db.from(table).select('position').eq('user_id', _me);
    final last =
        await (value == null
                ? query.isFilter(column, null)
                : query.eq(column, value))
            .order('position', ascending: false)
            .limit(1)
            .maybeSingle();
    return last == null ? 0 : (last['position'] as int) + 1;
  }

  /// [write], with a unique-index violation as [DuplicateName].
  static Future<T> _unique<T>(Future<T> Function() write) async {
    try {
      return await write();
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw DuplicateName();
      rethrow;
    }
  }

  @override
  Future<String> createGroup(
    String name, {
    required bool exclusive,
    bool pickFromList = false,
    String? parentTagId,
    List<String> tags = const [],
  }) async {
    final position = await _next('tag_groups', 'parent_tag_id', parentTagId);
    final group = await _unique(
      () => _db
          .from('tag_groups')
          .insert({
            'name': name.trim(),
            'exclusive': exclusive,
            'pick_from_list': pickFromList,
            'parent_tag_id': parentTagId,
            'position': position,
          })
          .select('id')
          .single(),
    );
    if (tags.isNotEmpty) {
      await _unique(
        () => _db.from('tags').insert([
          for (final (i, tag) in tags.indexed)
            {'group_id': group['id'], 'name': tag.trim(), 'position': i},
        ]),
      );
    }
    _changes.value++;
    return group['id'] as String;
  }

  @override
  Future<void> updateGroup(
    String groupId, {
    String? name,
    bool? exclusive,
    bool? hidden,
    bool? pickFromList,
  }) async {
    try {
      await _db
          .from('tag_groups')
          .update({
            'name': ?name?.trim(),
            'exclusive': ?exclusive,
            'hidden': ?hidden,
            'pick_from_list': ?pickFromList,
          })
          .eq('id', groupId);
    } on PostgrestException catch (e) {
      // The only unique indexes an update can hit: the name, and one tag
      // per album in an exclusive group.
      if (e.code == '23505') {
        throw exclusive == true ? SeveralTags() : DuplicateName();
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteGroup(String groupId) =>
      _db.from('tag_groups').delete().eq('id', groupId);

  @override
  Future<void> renameTag(String tagId, String name) => _unique(
    () => _db.from('tags').update({'name': name.trim()}).eq('id', tagId),
  );

  @override
  Future<void> deleteTag(String tagId) =>
      _db.from('tags').delete().eq('id', tagId);

  @override
  Future<void> reorderGroups(List<String> groupIds) =>
      _reorder('tag_groups', groupIds);

  @override
  Future<void> reorderTags(List<String> tagIds) => _reorder('tags', tagIds);

  @override
  Future<void> saveFilter(ShelfFilter filter) async {
    final fields = {
      'name': filter.isTag ? null : filter.name?.trim(),
      'tags_match': filter.matchAll ? 'all' : 'any',
      'min_rating': filter.minRating,
      'unrated': filter.unrated,
      'favorite_tracks': filter.favoriteTracks,
      'added_within_days': filter.addedWithinDays,
      'added_from': _day(filter.addedFrom),
      'added_to': _day(filter.addedTo),
    };
    final String id;
    if (filter.id.isEmpty) {
      final last = await _db
          .from('shelf_filters')
          .select('position')
          .eq('user_id', _me)
          .order('position', ascending: false)
          .limit(1)
          .maybeSingle();
      final row = await _db
          .from('shelf_filters')
          .insert({
            ...fields,
            'position': last == null ? 0 : last['position'] + 1,
          })
          .select('id')
          .single();
      id = row['id'];
    } else {
      id = filter.id;
      await _db.from('shelf_filters').update(fields).eq('id', id);
    }
    // New tags before old ones go: a filter emptied of tags and other
    // conditions is deleted by the database.
    if (filter.tagIds.isNotEmpty) {
      await _db.from('shelf_filter_tags').upsert([
        for (final tag in filter.tagIds) {'filter_id': id, 'tag_id': tag},
      ], ignoreDuplicates: true);
    }
    var gone = _db.from('shelf_filter_tags').delete().eq('filter_id', id);
    if (filter.tagIds.isNotEmpty) {
      gone = gone.not('tag_id', 'in', '(${filter.tagIds.join(',')})');
    }
    await gone;
  }

  @override
  Future<void> deleteFilter(String filterId) =>
      _db.from('shelf_filters').delete().eq('id', filterId);

  @override
  Future<void> reorderFilters(List<String> filterIds) =>
      _reorder('shelf_filters', filterIds);

  Future<void> _reorder(String table, List<String> ids) => [
    for (final (i, id) in ids.indexed)
      _db.from(table).update({'position': i}).eq('id', id),
  ].wait;

  @override
  Future<void> remove(List<String> entryIds) async {
    await _db.from('shelf_entries').delete().inFilter('id', entryIds);
    _changes.value++;
  }

  @override
  Future<void> changeTags(
    List<String> entryIds, {
    Set<String> remove = const {},
    List<String> add = const [],
  }) async {
    try {
      if (remove.isNotEmpty) {
        await _db
            .from('entry_tags')
            .delete()
            .inFilter('entry_id', entryIds)
            .inFilter('tag_id', remove.toList());
      }
      // One insert per tag, in order: the database checks that a sub-tag's
      // parent is on the album already.
      for (final tag in add) {
        await _db.from('entry_tags').upsert([
          for (final id in entryIds) {'entry_id': id, 'tag_id': tag},
        ], ignoreDuplicates: true);
      }
    } finally {
      // Also after a failure halfway, so the shelf shows what did change.
      _changes.value++;
    }
  }

  @override
  Future<Map<String, String>> copyTargets(List<String> friendGroupIds) async {
    final rows = await _db
        .from('tag_group_destinations')
        .select('friend_group_id, group_id')
        .eq('user_id', _me)
        .inFilter('friend_group_id', friendGroupIds)
        // Earlier versions also stored other kinds of target.
        .not('group_id', 'is', null);
    return {
      for (final r in rows)
        r['friend_group_id'] as String: r['group_id'] as String,
    };
  }

  @override
  Future<void> rememberCopy(String friendGroupId, String groupId) =>
      _db.from('tag_group_destinations').upsert({
        'friend_group_id': friendGroupId,
        'group_id': groupId,
        'parent_tag_id': null,
      });

  @override
  Future<void> hide(List<String> entryIds, bool hidden) async {
    await _db
        .from('shelf_entries')
        .update({'hidden': hidden})
        .inFilter('id', entryIds);
    _changes.value++;
  }
}
