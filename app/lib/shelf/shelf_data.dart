import 'dart:convert';

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

@immutable
class Tag {
  const Tag({required this.id, required this.groupId, required this.name});

  final String id, groupId, name;
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
    this.tags = const [],
  });

  final String id, name;
  final bool exclusive, builtin;
  final String? parentTagId;
  final List<Tag> tags;

  TagGroup withTag(Tag tag) => TagGroup(
    id: id,
    name: name,
    exclusive: exclusive,
    parentTagId: parentTagId,
    builtin: builtin,
    tags: [...tags, tag],
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

@immutable
class Shelf {
  const Shelf({
    required this.entries,
    this.filters = const [],
    this.groups = const [],
  });

  /// Newest first.
  final List<ShelfEntry> entries;

  /// In the user's order; "All" is implicit.
  final List<ShelfFilter> filters;

  /// The visible tag groups (hidden ones and their sub-groups left out), in
  /// the user's order.
  final List<TagGroup> groups;

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
  /// after [removeTags] come off.
  Future<void> save(
    String entryId, {
    int? rating,
    String? comment,
    Set<String> removeTags = const {},
    List<String> addTags = const [],
  });

  Future<void> remove(String entryId);

  /// Adds the album with this MusicBrainz ID to the shelf: the add-album
  /// function puts it in the shared catalog (with its cover) if needed.
  Future<void> add(
    String musicbrainzId, {
    int? rating,
    String? comment,
    List<String> tags = const [],
  });

  /// Adds an album by hand: the add-album function adds it as the user's
  /// own, with the photo as its cover.
  Future<void> addManual(
    ManualAlbum album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
  });

  /// A new tag in [groupId]; the name must be new in that group.
  Future<Tag> createTag(String groupId, String name);
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
      _db
          .from('tags')
          .select('id, name, group_id')
          .order('position', ascending: true),
      _db
          .from('tag_groups')
          .select('id, name, exclusive, parent_tag_id, builtin, hidden')
          .order('position', ascending: true),
    ).wait;
    // A hidden group hides its tags, and so the sub-groups under them.
    final groupOfTag = {
      for (final t in tags) t['id'] as String: t['group_id'] as String,
    };
    final byId = {for (final g in groups) g['id'] as String: g};
    bool hidden(String groupId) {
      final g = byId[groupId]!;
      if (g['hidden'] == true) return true;
      final parent = g['parent_tag_id'] as String?;
      return parent != null && hidden(groupOfTag[parent]!);
    }

    final visible = [
      for (final g in groups)
        if (!hidden(g['id']))
          TagGroup(
            id: g['id'],
            name: g['name'],
            exclusive: g['exclusive'],
            parentTagId: g['parent_tag_id'],
            builtin: g['builtin'] != null,
            tags: [
              for (final t in tags)
                if (t['group_id'] == g['id'])
                  Tag(id: t['id'], groupId: g['id'], name: t['name']),
            ],
          ),
    ];
    final tagNames = {
      for (final g in visible)
        for (final t in g.tags) t.id: t.name,
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
      groups: visible,
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
  }) async {
    await _db
        .from('shelf_entries')
        .update({'rating': rating, 'comment': _comment(comment)})
        .eq('id', entryId);
    await _setTags(entryId, removeTags, addTags);
  }

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
  }) async {
    await _addEntry(
      {'musicbrainz_id': musicbrainzId},
      rating: rating,
      comment: comment,
      tags: tags,
    );
  }

  @override
  Future<void> addManual(
    ManualAlbum album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
  }) => _addEntry(album.toJson(), rating: rating, comment: comment, tags: tags);

  /// The add-album function returns the album; then the entry and its tags.
  Future<void> _addEntry(
    Map<String, dynamic> album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
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
  }

  @override
  Future<Tag> createTag(String groupId, String name) async {
    final tag = await _db
        .from('tags')
        .insert({'group_id': groupId, 'name': name.trim()})
        .select('id, group_id, name')
        .single();
    return Tag(id: tag['id'], groupId: tag['group_id'], name: tag['name']);
  }

  @override
  Future<void> remove(String entryId) =>
      _db.from('shelf_entries').delete().eq('id', entryId);
}
