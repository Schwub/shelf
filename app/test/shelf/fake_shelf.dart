import 'dart:async';

import 'package:shelf_app/shelf/shelf_data.dart';

const own = ShelfFilter(tagId: 'own', label: 'Own');
const want = ShelfFilter(tagId: 'want', label: 'Want');

Tag tag(String group, String name) =>
    Tag(id: name.toLowerCase(), groupId: group, name: name);

/// The groups new users start with (docs/features/tags.md), plus genres.
final suggestedGroups = [
  TagGroup(
    id: 'collection',
    name: 'Collection',
    exclusive: true,
    builtin: true,
    tags: [tag('collection', 'Want'), tag('collection', 'Own')],
  ),
  TagGroup(
    id: 'format',
    name: 'Format',
    exclusive: false,
    parentTagId: 'own',
    tags: [
      for (final f in ['Vinyl', 'CD', 'Tape', 'File']) tag('format', f),
    ],
  ),
  TagGroup(
    id: 'listening',
    name: 'Listening',
    exclusive: true,
    builtin: true,
    tags: [tag('listening', 'Want to listen'), tag('listening', 'Listened')],
  ),
  TagGroup(
    id: 'genre',
    name: 'Genre',
    exclusive: false,
    tags: [
      for (final g in [
        'Alternative',
        'Ambient',
        'Art rock',
        'Electronic',
        'Jazz',
        'Krautrock',
        'Pop',
      ])
        tag('genre', g),
    ],
  ),
];

ShelfEntry entry(String id, String title, {int? rating, Set<String>? tags}) =>
    ShelfEntry(
      id: id,
      album: Album(
        id: 'a$id',
        musicbrainzId: 'mb$id',
        title: title,
        artist: 'Artist $id',
        year: 1997,
      ),
      rating: rating,
      tagIds: tags ?? const {},
    );

/// An in-memory shelf; the fail flags make the next call fail. Records the
/// tag changes it was asked for.
class FakeShelf implements ShelfRepository {
  FakeShelf(
    List<ShelfEntry> entries, {
    this.filters = const [own, want],
    List<TagGroup>? groups,
  }) : entries = [...entries],
       groups = [...(groups ?? suggestedGroups)];

  final List<ShelfEntry> entries;
  final List<ShelfFilter> filters;
  final List<TagGroup> groups;
  final removed = <String>[];
  Set<String> removedTags = {};
  List<String> addedTags = [];
  bool failLoad = false, failSave = false, failAdd = false, failCreate = false;
  int loads = 0;

  @override
  Future<Shelf> load() async {
    loads++;
    if (failLoad) {
      failLoad = false;
      throw Exception('offline');
    }
    return Shelf(entries: [...entries], filters: filters, groups: groups);
  }

  @override
  Future<void> save(
    String entryId, {
    int? rating,
    String? comment,
    Set<String> removeTags = const {},
    List<String> addTags = const [],
  }) async {
    if (failSave) {
      failSave = false;
      throw Exception('offline');
    }
    removedTags = removeTags;
    addedTags = addTags;
    final i = entries.indexWhere((e) => e.id == entryId);
    final e = entries[i];
    entries[i] = ShelfEntry(
      id: e.id,
      album: e.album,
      rating: rating,
      comment: comment == null || comment.isEmpty ? null : comment,
      tagIds: {...e.tagIds.difference(removeTags), ...addTags},
    );
  }

  @override
  Future<void> add(
    String musicbrainzId, {
    int? rating,
    String? comment,
    List<String> tags = const [],
  }) async {
    if (failAdd) {
      failAdd = false;
      throw Exception('offline');
    }
    addedTags = tags;
    entries.insert(
      0,
      ShelfEntry(
        id: 'new-$musicbrainzId',
        album: Album(
          id: 'album-$musicbrainzId',
          musicbrainzId: musicbrainzId,
          title: 'Added $musicbrainzId',
          artist: 'Someone',
        ),
        rating: rating,
        comment: comment == null || comment.isEmpty ? null : comment,
        tagIds: tags.toSet(),
      ),
    );
  }

  @override
  Future<Tag> createTag(String groupId, String name) async {
    if (failCreate) {
      failCreate = false;
      throw Exception('offline');
    }
    final created = tag(groupId, name);
    final i = groups.indexWhere((g) => g.id == groupId);
    groups[i] = groups[i].withTag(created);
    return created;
  }

  @override
  Future<void> remove(String entryId) async {
    removed.add(entryId);
    entries.removeWhere((e) => e.id == entryId);
  }
}
