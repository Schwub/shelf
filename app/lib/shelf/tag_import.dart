import 'shelf.dart';
import 'shelf_repository.dart';

/// A place in the user's tags for one of the friend's groups: one of the
/// user's groups ([existing]), or a new group [name] under [parent] (at the
/// top level when null). [from] is the friend's group it stands for.
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
  final TagGroup? from;

  bool get isNew => existing == null;
}

/// A place in the user's tags for one of the friend's tags: one of the
/// user's tags ([existing]), or a new tag [name] in [group].
class TagPlace {
  TagPlace._({this.existing, required this.name, required this.group});

  final Tag? existing;
  final String name;
  final GroupPlace group;

  bool get isNew => existing == null;

  /// The tag places above this one, nearest first: the parent tags of its
  /// sub-groups.
  Iterable<TagPlace> get ancestors sync* {
    for (var p = group.parent; p != null; p = p.group.parent) {
      yield p;
    }
  }
}

/// Adding a friend's album: their tags on it, and where each goes in the
/// user's tags (docs/features/tags.md, "A friend's tags on the album
/// entry"). Nothing is set or created until the user taps a tag.
class TagImport {
  TagImport({
    required this.from,
    required this.theirs,
    required this.tagIds,
    required this.mine,
    this.remembered = const {},
  });

  final AddedFrom from;

  /// The friend's shelf and their tags on the album.
  final Shelf theirs;
  final Set<String> tagIds;

  /// The user's shelf the places are worked out in.
  final Shelf mine;

  /// The user's group for the friend's groups (by ID), as answered before.
  final Map<String, String> remembered;

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

  /// The names above the friend's tag [t] in their structure, from the top:
  /// "Collection", "Own", "Format" for Vinyl.
  List<String> pathOf(Tag t) {
    final group = groupOf(t.id);
    return [
      if (_theirTags[group.parentTagId] case final parent?) ...[
        ...pathOf(parent),
        parent.name,
      ],
      group.name,
    ];
  }

  /// The friend's tags on the album, in their order. Left out: tags in
  /// groups the friend hides, and in or under built-in groups the user
  /// hides.
  late final List<Tag> tags = [
    for (final g in theirs.groups)
      if (_offered(g))
        for (final t in g.tags)
          if (tagIds.contains(t.id)) t,
  ];

  bool _offered(TagGroup g) {
    if (g.builtin case final key?) {
      return mine.groups.any((m) => m.builtin == key);
    }
    return switch (_theirGroupOfTag[g.parentTagId]) {
      final parent? => _offered(parent),
      null => true,
    };
  }

  /// The target for the friend's group [id]: answered just now ([picked]),
  /// else remembered; null when never asked.
  CopyTarget? _chosen(String id, Map<String, CopyTarget> picked) =>
      picked[id] ??
      switch (remembered[id]) {
        // A remembered group that is gone or hidden counts as never asked.
        final g? when _myGroups.containsKey(g) => IntoGroup(g),
        _ => null,
      };

  /// Where the friend's group [g] goes: into the chosen group of the
  /// user's, else their group of the same name in the same place, else a
  /// new one there.
  GroupPlace groupPlace(
    TagGroup g, [
    Map<String, CopyTarget> picked = const {},
  ]) {
    if (_chosen(g.id, picked) case IntoGroup(:final groupId)
        when _myGroups.containsKey(groupId)) {
      return _existingGroup(_myGroups[groupId]!, from: g);
    }
    final parent = switch (g.parentTagId) {
      final p? => tagPlace(_theirTags[p]!, picked),
      null => null,
    };
    final there = parent == null || parent.existing != null
        ? mine.groups
              .where(
                (m) =>
                    m.parentTagId == parent?.existing?.id && _sameGroup(m, g),
              )
              .firstOrNull
        : null;
    return GroupPlace._(
      existing: there,
      name: there?.name ?? g.name,
      exclusive: there?.exclusive ?? g.exclusive,
      pickFromList: g.pickFromList,
      parent: parent,
      from: g,
    );
  }

  /// Where the friend's tag [t] goes: the tag of that name in its group's
  /// place, or a new one there. When nothing was chosen for the groups
  /// above it and the user has a tag of that name elsewhere, that one.
  TagPlace tagPlace(Tag t, [Map<String, CopyTarget> picked = const {}]) {
    final group = groupPlace(groupOf(t.id), picked);
    final there = group.existing?.tags.where((m) => _sameTag(m, t)).firstOrNull;
    if (there == null && !_chosenAbove(t, picked)) {
      final elsewhere = [
        for (final g in mine.groups)
          for (final m in g.tags)
            if (_sameTag(m, t)) m,
      ].firstOrNull;
      if (elsewhere != null) return _existingTag(elsewhere.id);
    }
    return TagPlace._(
      existing: there,
      name: there?.name ?? t.name,
      group: group,
    );
  }

  bool _chosenAbove(Tag t, Map<String, CopyTarget> picked) {
    for (TagGroup? g = groupOf(t.id); g != null;) {
      if (_chosen(g.id, picked) != null) return true;
      g = _theirGroupOfTag[g.parentTagId];
    }
    return false;
  }

  GroupPlace _existingGroup(TagGroup g, {TagGroup? from}) => GroupPlace._(
    existing: g,
    name: g.name,
    exclusive: g.exclusive,
    parent: switch (g.parentTagId) {
      final p? when _myGroupOfTag.containsKey(p) => _existingTag(p),
      _ => null,
    },
    from: from,
  );

  TagPlace _existingTag(String id) {
    final g = _myGroupOfTag[id]!;
    final t = g.tags.firstWhere((t) => t.id == id);
    return TagPlace._(existing: t, name: t.name, group: _existingGroup(g));
  }

  static bool _sameGroup(TagGroup mine, TagGroup theirs) =>
      (theirs.builtin != null && mine.builtin == theirs.builtin) ||
      // Names are unique among a user's groups, built-in ones included.
      mine.name.toLowerCase() == theirs.name.toLowerCase();

  static bool _sameTag(Tag mine, Tag theirs) =>
      (theirs.builtin != null && mine.builtin == theirs.builtin) ||
      mine.name.toLowerCase() == theirs.name.toLowerCase();

  /// The friend's group to ask about before the new tag [t] is added: the
  /// topmost group on its way that the user has no place for yet. Null when
  /// [t] can be added without asking.
  TagGroup? groupToAsk(Tag t, [Map<String, CopyTarget> picked = const {}]) {
    final place = tagPlace(t, picked);
    if (!place.isNew) return null;
    TagGroup? top;
    for (GroupPlace? g = place.group; g != null; g = g.parent?.group) {
      if (g.isNew) top = g.from;
    }
    return top == null || _chosen(top.id, picked) != null ? null : top;
  }

  /// The user's group that looks most like the friend's group [g]: the one
  /// that has most of its tags by name. Null when none has any.
  TagGroup? suggestion(TagGroup g) {
    int shared(TagGroup m) =>
        g.tags.where((t) => m.tags.any((mt) => _sameTag(mt, t))).length;
    final best = mine.groups.fold<TagGroup?>(
      null,
      (best, m) => best == null || shared(m) > shared(best) ? m : best,
    );
    return best != null && shared(best) > 0 ? best : null;
  }

  TagImport withMine(Shelf mine) => TagImport(
    from: from,
    theirs: theirs,
    tagIds: tagIds,
    mine: mine,
    remembered: remembered,
  );

  /// Puts the friend's tag [t] in its place, creating what is new, and
  /// returns the user's shelf after with the tags to set on the album: the
  /// tag, parents first. Reuses same-name groups and tags on the shelf as
  /// it is now, so trying again creates nothing twice.
  Future<({Shelf mine, List<String> tagIds})> add(
    ShelfRepository shelf,
    Tag t, [
    Map<String, CopyTarget> picked = const {},
  ]) async {
    final current = await shelf.load();
    final made = <Object, String>{}; // a new place → the user's ID
    late Future<String> Function(TagPlace) tag;

    Future<String> group(GroupPlace g) async {
      if (g.existing case final e?) return e.id;
      if (made[g] case final id?) return id;
      final parent = switch (g.parent) {
        final p? => await tag(p),
        null => null,
      };
      final there = current.allGroups.where(
        (m) =>
            m.parentTagId == parent &&
            m.name.toLowerCase() == g.name.toLowerCase(),
      );
      return made[g] =
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
      if (made[t] case final id?) return id;
      final groupId = await group(t.group);
      final there = current.allGroups
          .where((g) => g.id == groupId)
          .expand((g) => g.tags)
          .where((m) => m.name.toLowerCase() == t.name.toLowerCase());
      return made[t] =
          there.firstOrNull?.id ?? (await shelf.createTag(groupId, t.name)).id;
    };

    final place = tagPlace(t, picked);
    final ids = [
      for (final a in place.ancestors.toList().reversed) await tag(a),
      await tag(place),
    ];
    return (mine: await shelf.load(), tagIds: ids);
  }
}
