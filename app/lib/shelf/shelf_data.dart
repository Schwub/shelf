import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tracks/track_source.dart';

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

/// A track on the user's own track list of an album (docs/features/tracks.md).
@immutable
class Track {
  const Track({
    required this.title,
    this.disc = 1,
    required this.position,
    this.lengthMs,
    this.favorite = false,
  });

  final String title;
  final int disc, position;
  final int? lengthMs;
  final bool favorite;

  Track copyWith({String? title, int? disc, int? position, bool? favorite}) =>
      Track(
        title: title ?? this.title,
        disc: disc ?? this.disc,
        position: position ?? this.position,
        lengthMs: lengthMs,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
    'disc': disc,
    'position': position,
    'title': title.trim(),
    'length_ms': lengthMs,
    'favorite': favorite,
  };

  @override
  bool operator ==(Object other) =>
      other is Track &&
      other.title == title &&
      other.disc == disc &&
      other.position == position &&
      other.lengthMs == lengthMs &&
      other.favorite == favorite;

  @override
  int get hashCode => Object.hash(title, disc, position, lengthMs, favorite);
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
    this.tracks = const [],
  });

  final String id;
  final Album album;
  final int? rating;
  final String? comment;
  final Set<String> tagIds;

  /// The user's track list, disc by disc; empty until they approve or enter
  /// one.
  final List<Track> tracks;
}

@immutable
class Tag {
  const Tag({
    required this.id,
    required this.groupId,
    required this.name,
    this.builtin = false,
  });

  final String id, groupId, name;

  /// Want, Own, Want to listen, Listened: can't be deleted.
  final bool builtin;
}

/// One of the user's tag groups with its tags, in their order. A group with
/// [parentTagId] is a sub-group, shown while that tag is chosen.
@immutable
class TagGroup {
  const TagGroup({
    required this.id,
    required this.name,
    required this.exclusive,
    this.parentTagId,
    this.builtin = false,
    this.hidden = false,
    this.tags = const [],
  });

  final String id, name;

  /// Built-in groups (Collection, Listening) can be renamed and hidden, not
  /// deleted; only they can be hidden.
  final bool exclusive, builtin, hidden;
  final String? parentTagId;
  final List<Tag> tags;

  TagGroup withTag(Tag tag) => copyWith(tags: [...tags, tag]);

  TagGroup copyWith({
    String? name,
    bool? exclusive,
    bool? hidden,
    List<Tag>? tags,
  }) => TagGroup(
    id: id,
    name: name ?? this.name,
    exclusive: exclusive ?? this.exclusive,
    parentTagId: parentTagId,
    builtin: builtin,
    hidden: hidden ?? this.hidden,
    tags: tags ?? this.tags,
  );
}

/// An album to add by hand (not on MusicBrainz), with an optional photo as
/// its cover (JPEG or PNG bytes).
@immutable
class ManualAlbum {
  const ManualAlbum({
    required this.title,
    required this.artist,
    this.year,
    this.cover,
  });

  final String title, artist;
  final int? year;
  final Uint8List? cover;

  /// What the add-album function expects.
  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'year': year,
    if (cover case final bytes?)
      'cover': {
        'data': base64Encode(bytes),
        // PNG files start with 0x89 'P'; the picker gives JPEG otherwise.
        'type': bytes.length > 1 && bytes[0] == 0x89 && bytes[1] == 0x50
            ? 'image/png'
            : 'image/jpeg',
      },
  };
}

/// A key of the shelf's filter bar: one of the user's tags.
@immutable
class ShelfFilter {
  const ShelfFilter({required this.tagId, required this.label});

  final String tagId, label;
}

class Shelf {
  Shelf({
    required this.entries,
    this.allFilters = const [],
    this.allGroups = const [],
  });

  /// Newest first.
  final List<ShelfEntry> entries;

  /// Every filter and tag group, hidden ones included, in the user's order
  /// (sub-groups among them).
  final List<ShelfFilter> allFilters;
  final List<TagGroup> allGroups;

  /// The groups shown on albums: hidden ones and the sub-groups under their
  /// tags left out.
  late final List<TagGroup> groups = () {
    final groupOfTag = {
      for (final g in allGroups)
        for (final t in g.tags) t.id: g,
    };
    bool hidden(TagGroup g) {
      if (g.hidden) return true;
      final parent = groupOfTag[g.parentTagId];
      return parent != null && hidden(parent);
    }

    return [
      for (final g in allGroups)
        if (!hidden(g)) g,
    ];
  }();

  /// The filter bar's filters, on tags that are shown; "All" is implicit.
  late final List<ShelfFilter> filters = () {
    final shown = {
      for (final g in groups)
        for (final t in g.tags) t.id,
    };
    return [
      for (final f in allFilters)
        if (shown.contains(f.tagId)) f,
    ];
  }();

  /// The sub-group shown while [tagId] is chosen, if any.
  TagGroup? subGroupOf(String tagId) =>
      allGroups.where((g) => g.parentTagId == tagId).firstOrNull;

  /// How many albums have [tagId].
  int albumsWith(String tagId) =>
      entries.where((e) => e.tagIds.contains(tagId)).length;

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
  /// [addTags] go on in their order (parent tags before their sub-tags),
  /// after [removeTags] come off. [tracks] replace the track list; null
  /// leaves it.
  Future<void> save(
    String entryId, {
    int? rating,
    String? comment,
    Set<String> removeTags = const {},
    List<String> addTags = const [],
    List<Track>? tracks,
  });

  Future<void> remove(String entryId);

  /// Adds the album with this MusicBrainz ID to the shelf: the add-album
  /// function puts it in the shared catalog (with its cover) if needed.
  Future<void> add(
    String musicbrainzId, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
  });

  /// Adds an album by hand: the add-album function adds it as the user's
  /// own, with the photo as its cover.
  Future<void> addManual(
    ManualAlbum album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
  });

  /// The track list MusicBrainz has for the album [musicbrainzId], to
  /// suggest; empty when it has none.
  Future<List<Track>> trackList(String musicbrainzId);

  /// A new tag at the end of [groupId]; the name must be new in that group
  /// ([DuplicateName] otherwise).
  Future<Tag> createTag(String groupId, String name);

  // The tag editor. Names must be new on their level ([DuplicateName]).

  /// A new group at the end, or the sub-group shown while [parentTagId] is
  /// chosen, with [tags] in their order.
  Future<void> createGroup(
    String name, {
    required bool exclusive,
    String? parentTagId,
    List<String> tags = const [],
  });

  /// Making a group exclusive while an album has several of its tags throws
  /// [SeveralTags]. Only built-in groups can be hidden.
  Future<void> updateGroup(
    String groupId, {
    String? name,
    bool? exclusive,
    bool? hidden,
  });

  /// Also removes its tags from albums, its sub-groups and their filters.
  Future<void> deleteGroup(String groupId);

  Future<void> renameTag(String tagId, String name);

  /// Also removes it from albums, and its sub-group and filters.
  Future<void> deleteTag(String tagId);

  /// Groups or tags in this new order.
  Future<void> reorderGroups(List<String> groupIds);
  Future<void> reorderTags(List<String> tagIds);
}

/// A tag or group name already used on its level, ignoring case.
class DuplicateName implements Exception {}

/// A group can't become one per album while albums have several of its tags.
class SeveralTags implements Exception {}

class SupabaseShelfRepository implements ShelfRepository {
  SupabaseShelfRepository(this._db, this._tracks);

  final SupabaseClient _db;
  final TrackSource _tracks;

  @override
  Future<List<Track>> trackList(String musicbrainzId) =>
      _tracks.trackList(musicbrainzId);

  @override
  Future<Shelf> load() async {
    // Row-level security limits every table to the signed-in user.
    final (entries, filters, tags, groups) = await (
      _db
          .from('shelf_entries')
          .select(
            'id, rating, comment, '
            'album:albums(id, musicbrainz_id, title, artist, year, cover_url), '
            'entry_tags(tag_id), '
            'entry_tracks(disc, position, title, length_ms, favorite)',
          )
          .order('created_at', ascending: false),
      _db
          .from('shelf_filters')
          .select('tag_id')
          .order('position', ascending: true),
      // New rows and reordered ones can share a position for a moment.
      _db
          .from('tags')
          .select('id, name, group_id, builtin')
          .order('position', ascending: true)
          .order('created_at', ascending: true),
      _db
          .from('tag_groups')
          .select('id, name, exclusive, parent_tag_id, builtin, hidden')
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
            rating: e['rating'],
            comment: e['comment'],
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
          ShelfFilter(tagId: f['tag_id'], label: tagNames[f['tag_id']]),
      ],
      allGroups: [
        for (final g in groups)
          TagGroup(
            id: g['id'],
            name: g['name'],
            exclusive: g['exclusive'],
            parentTagId: g['parent_tag_id'],
            builtin: g['builtin'] != null,
            hidden: g['hidden'],
            tags: [
              for (final t in tags)
                if (t['group_id'] == g['id'])
                  Tag(
                    id: t['id'],
                    groupId: g['id'],
                    name: t['name'],
                    builtin: t['builtin'] != null,
                  ),
            ],
          ),
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
  Future<void> save(
    String entryId, {
    int? rating,
    String? comment,
    Set<String> removeTags = const {},
    List<String> addTags = const [],
    List<Track>? tracks,
  }) async {
    await _db
        .from('shelf_entries')
        .update({'rating': rating, 'comment': _comment(comment)})
        .eq('id', entryId);
    await _setTags(entryId, removeTags, addTags);
    if (tracks != null) await _setTracks(entryId, tracks);
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
  }) async {
    await _addEntry(
      {'musicbrainz_id': musicbrainzId},
      rating: rating,
      comment: comment,
      tags: tags,
      tracks: tracks,
    );
  }

  @override
  Future<void> addManual(
    ManualAlbum album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
  }) => _addEntry(
    album.toJson(),
    rating: rating,
    comment: comment,
    tags: tags,
    tracks: tracks,
  );

  /// The add-album function returns the album; then the entry and its tags.
  Future<void> _addEntry(
    Map<String, dynamic> album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
  }) async {
    final response = await _db.functions.invoke('add-album', body: album);
    final entry = await _db
        .from('shelf_entries')
        .insert({
          'album_id': (response.data as Map<String, dynamic>)['id'],
          'rating': rating,
          'comment': _comment(comment),
        })
        .select('id')
        .single();
    await _setTags(entry['id'], const {}, tags);
    if (tracks.isNotEmpty) await _setTracks(entry['id'], tracks);
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
    return Tag(id: tag['id'], groupId: tag['group_id'], name: tag['name']);
  }

  /// The position after the last row where [column] is [value] (or null).
  Future<int> _next(String table, String column, String? value) async {
    final query = _db.from(table).select('position');
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
  Future<void> createGroup(
    String name, {
    required bool exclusive,
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
            'parent_tag_id': parentTagId,
            'position': position,
          })
          .select('id')
          .single(),
    );
    if (tags.isEmpty) return;
    await _unique(
      () => _db.from('tags').insert([
        for (final (i, tag) in tags.indexed)
          {'group_id': group['id'], 'name': tag.trim(), 'position': i},
      ]),
    );
  }

  @override
  Future<void> updateGroup(
    String groupId, {
    String? name,
    bool? exclusive,
    bool? hidden,
  }) async {
    try {
      await _db
          .from('tag_groups')
          .update({
            'name': ?name?.trim(),
            'exclusive': ?exclusive,
            'hidden': ?hidden,
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

  Future<void> _reorder(String table, List<String> ids) => [
    for (final (i, id) in ids.indexed)
      _db.from(table).update({'position': i}).eq('id', id),
  ].wait;

  @override
  Future<void> remove(String entryId) =>
      _db.from('shelf_entries').delete().eq('id', entryId);
}
