import 'dart:async';

import 'package:shelf_app/shelf/shelf_data.dart';

const own = ShelfFilter(tagId: 'own', label: 'Own');
const want = ShelfFilter(tagId: 'want', label: 'Want');

Tag tag(String group, String name, {bool builtin = false}) =>
    Tag(id: name.toLowerCase(), groupId: group, name: name, builtin: builtin);

/// The groups new users start with (docs/features/tags.md), plus genres.
final suggestedGroups = [
  TagGroup(
    id: 'collection',
    name: 'Collection',
    exclusive: true,
    builtin: true,
    tags: [
      tag('collection', 'Want', builtin: true),
      tag('collection', 'Own', builtin: true),
    ],
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
    tags: [
      tag('listening', 'Want to listen', builtin: true),
      tag('listening', 'Listened', builtin: true),
    ],
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
    List<ShelfFilter> filters = const [own, want],
    List<TagGroup>? groups,
  }) : entries = [...entries],
       filters = [...filters],
       groups = [...(groups ?? suggestedGroups)];

  final List<ShelfEntry> entries;
  final List<ShelfFilter> filters;
  final List<TagGroup> groups;
  final removed = <String>[];
  Set<String> removedTags = {};
  List<String> addedTags = [];
  bool failLoad = false, failSave = false, failAdd = false, failCreate = false;

  /// Makes the next tag editor change fail.
  bool failEdit = false;
  int loads = 0;

  @override
  Future<Shelf> load() async {
    loads++;
    if (failLoad) {
      failLoad = false;
      throw Exception('offline');
    }
    return Shelf(
      entries: [...entries],
      allFilters: [...filters],
      allGroups: [...groups],
    );
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

  final manual = <ManualAlbum>[];

  @override
  Future<void> addManual(
    ManualAlbum album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
  }) async {
    if (failAdd) {
      failAdd = false;
      throw Exception('offline');
    }
    manual.add(album);
    addedTags = tags;
    entries.insert(
      0,
      ShelfEntry(
        id: 'manual-${manual.length}',
        album: Album(
          id: 'm${manual.length}',
          title: album.title,
          artist: album.artist,
          year: album.year,
        ),
        rating: rating,
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
    _checkTagName(groupId, name);
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

  void _edit() {
    if (failEdit) {
      failEdit = false;
      throw Exception('offline');
    }
  }

  int _group(String id) => groups.indexWhere((g) => g.id == id);

  void _checkTagName(String groupId, String name, {String? except}) {
    if (groups[_group(groupId)].tags.any(
      (t) => t.id != except && t.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw DuplicateName();
    }
  }

  void _checkGroupName(String? parentTagId, String name, {String? except}) {
    if (groups.any(
      (g) =>
          g.id != except &&
          g.parentTagId == parentTagId &&
          g.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw DuplicateName();
    }
  }

  @override
  Future<void> createGroup(
    String name, {
    required bool exclusive,
    String? parentTagId,
    List<String> tags = const [],
  }) async {
    _edit();
    _checkGroupName(parentTagId, name);
    final id = name.toLowerCase();
    groups.add(
      TagGroup(
        id: id,
        name: name,
        exclusive: exclusive,
        parentTagId: parentTagId,
        tags: [for (final t in tags) tag(id, t)],
      ),
    );
  }

  @override
  Future<void> updateGroup(
    String groupId, {
    String? name,
    bool? exclusive,
    bool? hidden,
  }) async {
    _edit();
    final i = _group(groupId);
    final group = groups[i];
    if (name != null) {
      _checkGroupName(group.parentTagId, name, except: groupId);
    }
    if (exclusive == true) {
      final ids = {for (final t in group.tags) t.id};
      if (entries.any((e) => e.tagIds.intersection(ids).length > 1)) {
        throw SeveralTags();
      }
    }
    groups[i] = group.copyWith(
      name: name,
      exclusive: exclusive,
      hidden: hidden,
    );
  }

  /// Like the database's cascades: tags off albums, sub-groups, filters.
  void _dropTags(Iterable<String> tagIds) {
    final ids = tagIds.toSet();
    for (final (i, e) in entries.indexed) {
      entries[i] = ShelfEntry(
        id: e.id,
        album: e.album,
        rating: e.rating,
        comment: e.comment,
        tagIds: e.tagIds.difference(ids),
      );
    }
    filters.removeWhere((f) => ids.contains(f.tagId));
    for (final sub
        in groups.where((g) => ids.contains(g.parentTagId)).toList()) {
      _dropGroup(sub.id);
    }
  }

  void _dropGroup(String groupId) {
    final group = groups.removeAt(_group(groupId));
    _dropTags(group.tags.map((t) => t.id));
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    _edit();
    _dropGroup(groupId);
  }

  int _groupOfTag(String tagId) =>
      groups.indexWhere((g) => g.tags.any((t) => t.id == tagId));

  @override
  Future<void> renameTag(String tagId, String name) async {
    _edit();
    final i = _groupOfTag(tagId);
    _checkTagName(groups[i].id, name, except: tagId);
    groups[i] = groups[i].copyWith(
      tags: [
        for (final t in groups[i].tags)
          t.id == tagId
              ? Tag(
                  id: t.id,
                  groupId: t.groupId,
                  name: name,
                  builtin: t.builtin,
                )
              : t,
      ],
    );
  }

  @override
  Future<void> deleteTag(String tagId) async {
    _edit();
    final i = _groupOfTag(tagId);
    groups[i] = groups[i].copyWith(
      tags: [
        for (final t in groups[i].tags)
          if (t.id != tagId) t,
      ],
    );
    _dropTags([tagId]);
  }

  @override
  Future<void> reorderGroups(List<String> groupIds) async {
    _edit();
    final byId = {for (final g in groups) g.id: g};
    // The ones not named (sub-groups) keep their place after them.
    final rest = [
      for (final g in groups)
        if (!groupIds.contains(g.id)) g,
    ];
    groups
      ..clear()
      ..addAll([for (final id in groupIds) byId[id]!, ...rest]);
  }

  @override
  Future<void> reorderTags(List<String> tagIds) async {
    _edit();
    final i = _groupOfTag(tagIds.first);
    final byId = {for (final t in groups[i].tags) t.id: t};
    groups[i] = groups[i].copyWith(tags: [for (final id in tagIds) byId[id]!]);
  }
}
