import 'shelf.dart';
import 'shelf_repository.dart';

/// A place in the user's tags for one of the friend's groups: one of the
/// user's groups ([existing]), or a new group [name] under [parent] (at the
/// root when null). [from] is the friend's group it was worked out for.
class GroupPlace {
  GroupPlace._({
    this.existing,
    required this.name,
    required this.exclusive,
    this.pickFromList = false,
    this.parent,
    this.from,
  });

  final TagGroup? existing;
  final String name;
  final bool exclusive, pickFromList;
  final TagPlace? parent;
  final String? from;

  bool get isNew => existing == null;

  /// The same for the same place, new or not.
  String get key => switch (existing) {
    final g? => 'g:${g.id}',
    null => 'new:${parent?.key ?? 'root'}\u0000${name.toLowerCase()}',
  };
}

/// A place in the user's tags for one of the friend's tags: one of the
/// user's tags ([existing]), or a new tag [name] in [group]. [from] is the
/// friend's tag it was worked out for.
class TagPlace {
  TagPlace._({
    this.existing,
    required this.name,
    required this.group,
    this.from,
  });

  final Tag? existing;
  final String name;
  final GroupPlace group;
  final String? from;

  bool get isNew => existing == null;

  String get key => switch (existing) {
    final t? => 't:${t.id}',
    null => 'new:${group.key}\u0000${name.toLowerCase()}',
  };

  /// The tag places above this one, nearest first: the parent tags of its
  /// sub-groups.
  Iterable<TagPlace> get ancestors sync* {
    for (var p = group.parent; p != null; p = p.group.parent) {
      yield p;
    }
  }

  /// "Own › Format › Vinyl": the names from the top down.
  String get path => [
    for (final a in ancestors.toList().reversed) a.name,
    group.name,
    name,
  ].join(' › ');
}

/// A row of the friend's tree on the copy screen: one of their groups or
/// tags on the way to the album's tags, at [depth] (0 for a top-level group).
typedef CopyRow = ({TagGroup? group, Tag? tag, int depth});

/// Adding a friend's album: their tags on it in their tree, and where each
/// goes in the user's tags (TASK-49, docs/features/tags.md). Nothing is set
/// or created until the user ticks it and applies.
class TagImport {
  TagImport({
    required this.from,
    required this.theirs,
    required this.tagIds,
    required this.mine,
    this.memory = (targets: const {}, taken: const {}),
  });

  final AddedFrom from;

  /// The friend's shelf and their tags on the album.
  final Shelf theirs;
  final Set<String> tagIds;

  /// The user's shelf the places are worked out in.
  final Shelf mine;

  /// What the user chose before for this friend's groups and tags.
  final CopyMemory memory;

  late final _theirGroupOfTag = {
    for (final g in theirs.allGroups)
      for (final t in g.tags) t.id: g,
  };
  late final _theirTags = {
    for (final g in theirs.allGroups)
      for (final t in g.tags) t.id: t,
  };
  late final _myGroups = {for (final g in mine.groups) g.id: g};
  late final _myGroupOfTag = {
    for (final g in mine.groups)
      for (final t in g.tags) t.id: g,
  };

  /// The friend's group of their tag [tagId].
  TagGroup groupOf(String tagId) => _theirGroupOfTag[tagId]!;

  /// The friend's tag [tagId].
  Tag theirTag(String tagId) => _theirTags[tagId]!;

  /// The friend's tree down to the album's tags, in their order: groups,
  /// their tags, and the sub-groups under each tag. Left out: the friend's
  /// hidden groups and the built-in groups the user hides.
  late final List<CopyRow> rows = () {
    final rows = <CopyRow>[];
    bool leads(TagGroup g) => g.tags.any(_leadsToAlbum);
    void group(TagGroup g, int depth) {
      if (!leads(g)) return;
      rows.add((group: g, tag: null, depth: depth));
      for (final t in g.tags) {
        if (!_leadsToAlbum(t)) continue;
        rows.add((group: null, tag: t, depth: depth + 1));
        for (final sub in theirs.groups) {
          if (sub.parentTagId == t.id) group(sub, depth + 2);
        }
      }
    }

    for (final g in theirs.groups) {
      if (g.parentTagId != null) continue;
      if (g.builtin case final key?
          when !mine.groups.any((m) => m.builtin == key)) {
        continue;
      }
      group(g, 0);
    }
    return rows;
  }();

  bool _leadsToAlbum(Tag t) =>
      tagIds.contains(t.id) ||
      theirs.groups.any(
        (g) => g.parentTagId == t.id && g.tags.any(_leadsToAlbum),
      );

  /// The friend's tags in [rows].
  late final List<Tag> tags = [for (final r in rows) ?r.tag];

  /// The target chosen for the friend's group or tag [id]: picked here
  /// ([picked]), else remembered; null for the default.
  CopyTarget? chosen(String id, Map<String, CopyTarget> picked) =>
      picked[id] ?? memory.targets[id];

  /// Where the friend's group [g] goes, given the targets [picked] here.
  GroupPlace groupPlace(
    TagGroup g, [
    Map<String, CopyTarget> picked = const {},
  ]) {
    GroupPlace into(TagGroup mine) => _existingGroup(mine, from: g.id);
    GroupPlace under(TagPlace? parent) {
      final there = mine.groups.where(
        (m) =>
            m.parentTagId == parent?.existing?.id &&
            (parent == null || parent.existing != null) &&
            (_sameGroup(m, g)),
      );
      if (there.firstOrNull case final m?) {
        return GroupPlace._(
          existing: m,
          name: m.name,
          exclusive: m.exclusive,
          parent: parent,
          from: g.id,
        );
      }
      return GroupPlace._(
        name: g.name,
        exclusive: g.exclusive,
        pickFromList: g.pickFromList,
        parent: parent,
        from: g.id,
      );
    }

    switch (chosen(g.id, picked)) {
      case IntoGroup(:final groupId) when _myGroups.containsKey(groupId):
        return into(_myGroups[groupId]!);
      case UnderTag(:final tagId) when _myGroupOfTag.containsKey(tagId):
        return under(_existingTag(tagId));
      case AtRoot():
        return under(null);
      default:
        return under(switch (g.parentTagId) {
          final p? => tagPlace(theirTag(p), picked),
          null => null,
        });
    }
  }

  /// Where the friend's tag [t] goes, given the targets [picked] here: as
  /// chosen, else as Copy would put it, unless that is new and the user has
  /// a tag of that name elsewhere.
  TagPlace tagPlace(Tag t, [Map<String, CopyTarget> picked = const {}]) {
    TagPlace inGroup(GroupPlace group) {
      final there = group.existing?.tags
          .where((m) => _sameTag(m, t))
          .firstOrNull;
      return TagPlace._(
        existing: there,
        name: there?.name ?? t.name,
        group: group,
        from: t.id,
      );
    }

    final target = chosen(t.id, picked);
    switch (target) {
      case OntoTag(:final tagId) when _myGroupOfTag.containsKey(tagId):
        return _existingTag(tagId, from: t.id);
      case IntoGroup(:final groupId) when _myGroups.containsKey(groupId):
        return inGroup(_existingGroup(_myGroups[groupId]!));
      case _:
        break;
    }
    final theirGroup = groupOf(t.id);
    final copy = inGroup(groupPlace(theirGroup, picked));
    if (!copy.isNew || target is CopyAsIs || _chosenAbove(t, picked)) {
      return copy;
    }
    final elsewhere = [
      for (final g in mine.groups)
        for (final m in g.tags)
          if (_sameTag(m, t)) m,
    ].firstOrNull;
    return elsewhere == null ? copy : _existingTag(elsewhere.id, from: t.id);
  }

  /// Whether a target was chosen for a group or tag above the friend's tag
  /// [t]: then it follows that, not a same-name tag elsewhere.
  bool _chosenAbove(Tag t, Map<String, CopyTarget> picked) {
    for (TagGroup? g = groupOf(t.id); g != null;) {
      if (chosen(g.id, picked) != null) return true;
      final parent = g.parentTagId;
      if (parent == null) return false;
      if (chosen(parent, picked) != null) return true;
      g = _theirGroupOfTag[parent];
    }
    return false;
  }

  GroupPlace _existingGroup(TagGroup g, {String? from}) => GroupPlace._(
    existing: g,
    name: g.name,
    exclusive: g.exclusive,
    parent: switch (g.parentTagId) {
      final p? when _myGroupOfTag.containsKey(p) => _existingTag(p),
      _ => null,
    },
    from: from,
  );

  TagPlace _existingTag(String id, {String? from}) {
    final g = _myGroupOfTag[id]!;
    final t = g.tags.firstWhere((t) => t.id == id);
    return TagPlace._(
      existing: t,
      name: t.name,
      group: _existingGroup(g),
      from: from,
    );
  }

  static bool _sameGroup(TagGroup mine, TagGroup theirs) =>
      (theirs.builtin != null && mine.builtin == theirs.builtin) ||
      // Names are unique among a user's groups, built-in ones included.
      mine.name.toLowerCase() == theirs.name.toLowerCase();

  static bool _sameTag(Tag mine, Tag theirs) =>
      (theirs.builtin != null && mine.builtin == theirs.builtin) ||
      mine.name.toLowerCase() == theirs.name.toLowerCase();

  /// The friend's tags that come along with the ticked ones ([ticked]): those
  /// whose places are above a ticked tag's place.
  Set<String> along(Set<String> ticked, Map<String, CopyTarget> picked) => {
    for (final t in tags)
      if (ticked.contains(t.id))
        for (final a in tagPlace(t, picked).ancestors)
          if (a.from case final f? when !ticked.contains(f)) f,
  };

  /// What applying the ticked tags creates, in order: new groups and tags.
  List<String> creates(Set<String> ticked, Map<String, CopyTarget> picked) {
    final seen = <String>{};
    final out = <String>[];
    late void Function(TagPlace) tag;
    void group(GroupPlace g) {
      if (!g.isNew || !seen.add(g.key)) return;
      if (g.parent case final p?) tag(p);
      out.add(
        g.parent == null
            ? 'group ${g.name}'
            : 'sub-group ${g.name} under ${g.parent!.name}',
      );
    }

    tag = (t) {
      group(t.group);
      if (t.isNew && seen.add(t.key)) {
        out.add('tag ${t.name} in ${t.group.name}');
      }
    };

    for (final t in tags) {
      if (ticked.contains(t.id)) tag(tagPlace(t, picked));
    }
    return out;
  }

  TagImport withMine(Shelf mine) => TagImport(
    from: from,
    theirs: theirs,
    tagIds: tagIds,
    mine: mine,
    memory: memory,
  );

  /// Puts the friend's ticked tags ([ticked]) where they go, creating what is
  /// new, and returns the user's shelf after with the tags to set on the
  /// album (the parent tags above them too). Reuses same-name groups and tags
  /// on the shelf as it is now, so trying again creates nothing twice.
  Future<({Shelf mine, Set<String> tagIds})> apply(
    ShelfRepository shelf,
    Set<String> ticked,
    Map<String, CopyTarget> picked,
  ) async {
    final current = await shelf.load();
    final made = <String, String>{}; // place key → the user's ID
    late Future<String> Function(TagPlace) tag;

    Future<String> group(GroupPlace g) async {
      if (g.existing case final e?) return e.id;
      if (made[g.key] case final id?) return id;
      final parent = switch (g.parent) {
        final p? => await tag(p),
        null => null,
      };
      final there = current.allGroups.where(
        (m) =>
            m.parentTagId == parent &&
            m.name.toLowerCase() == g.name.toLowerCase(),
      );
      return made[g.key] =
          there.firstOrNull?.id ??
          await shelf.createGroup(
            g.name,
            exclusive: g.exclusive,
            pickFromList: g.pickFromList,
            parentTagId: parent,
          );
    }

    tag = (t) async {
      if (t.existing case final e?) return e.id;
      if (made[t.key] case final id?) return id;
      final groupId = await group(t.group);
      final there = current.allGroups
          .where((g) => g.id == groupId)
          .expand((g) => g.tags)
          .where((m) => m.name.toLowerCase() == t.name.toLowerCase());
      return made[t.key] =
          there.firstOrNull?.id ?? (await shelf.createTag(groupId, t.name)).id;
    };

    final set = <String>{};
    for (final t in tags) {
      if (!ticked.contains(t.id)) continue;
      final place = tagPlace(t, picked);
      set.add(await tag(place));
      for (final a in place.ancestors) {
        set.add(await tag(a));
      }
    }
    return (mine: await shelf.load(), tagIds: set);
  }

  /// Remembers this time's choices for the friend: the groups picked here
  /// (Copy too, so it replaces an earlier choice) and the ticked tags with
  /// the ones that came along, each with its target.
  Future<void> remember(
    ShelfRepository shelf,
    Set<String> ticked,
    Map<String, CopyTarget> picked,
  ) => shelf.rememberCopy(
    groups: {
      for (final MapEntry(:key, :value) in picked.entries)
        if (theirs.allGroups.any((g) => g.id == key)) key: value,
    },
    tags: {
      for (final id in {...ticked, ...along(ticked, picked)})
        id: switch (chosen(id, picked)) {
          final OntoTag t => t,
          final IntoGroup g => g,
          _ => null,
        },
    },
  );
}
