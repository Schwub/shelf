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
  TagPlace._({
    this.existing,
    required this.name,
    required this.group,
    this.from,
  });

  final Tag? existing;
  final String name;
  final GroupPlace group;

  /// The friend's tag this place stands for; null for a tag of the user's
  /// that is only on the way to it.
  final Tag? from;

  /// The names from the top of the user's tags down to this one:
  /// "Collection", "Own", "Format", "Vinyl".
  List<String> get path => [...?group.parent?.path, group.name, name];

  bool get isNew => existing == null;

  /// The tag places above this one, nearest first: the parent tags of its
  /// sub-groups.
  Iterable<TagPlace> get ancestors sync* {
    for (var p = group.parent; p != null; p = p.group.parent) {
      yield p;
    }
  }
}

/// One of the friend's groups or tags as the point a mapping starts at.
typedef Start = ({TagGroup? group, Tag? tag});

/// Adding a friend's album: their tags on it, and where each goes in the
/// user's tags (docs/features/tags.md, "A friend's tags as suggestions").
/// A place is worked out in this order: where the user mapped the tag,
/// where they mapped a group or tag above it, a tag of the same name, and
/// last the friend's structure as it is. Nothing is set or created until
/// the user says so.
class TagImport {
  TagImport({
    required this.from,
    required this.theirs,
    required this.tagIds,
    required this.mine,
    this.targets = const {},
  });

  final AddedFrom from;

  /// The friend's shelf and their tags on the album.
  final Shelf theirs;
  final Set<String> tagIds;

  /// The user's shelf the places are worked out in.
  final Shelf mine;

  /// Where the user mapped the friend's groups and tags (by their IDs).
  final Map<String, CopyTarget> targets;

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

  /// The friend's tag above their group [g], when it is a sub-group.
  Tag? parentOf(TagGroup g) => _theirTags[g.parentTagId];

  /// The names above the friend's tag [t] in their structure, from the top:
  /// "Collection", "Own", "Format" for Vinyl.
  List<String> pathOf(Tag t) => [
    for (final s in chainOf(t))
      if (s.tag?.id != t.id) (s.group?.name ?? s.tag?.name)!,
  ];

  /// The friend's groups and tags from the top down to [t], [t] included:
  /// the points a mapping of [t] can start at.
  List<Start> chainOf(Tag t) {
    final group = groupOf(t.id);
    return [
      if (parentOf(group) case final parent?) ...chainOf(parent),
      (group: group, tag: null),
      (group: null, tag: t),
    ];
  }

  /// The friend's tags below [start] in their shown groups, at any depth
  /// ([start] itself left out).
  List<Tag> below(Start start) {
    List<Tag> under(Tag t) => [
      for (final g in theirs.groups)
        if (g.parentTagId == t.id) ...inGroup(g),
    ];
    return start.group != null ? inGroup(start.group!) : under(start.tag!);
  }

  /// The tags of the friend's group [g], each followed by what is below it.
  List<Tag> inGroup(TagGroup g) => [
    for (final t in g.tags) ...[t, ...below((group: null, tag: t))],
  ];

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

  /// The target for the friend's group or tag [id], when its place in the
  /// user's tags is still there and shown.
  CopyTarget? target(String id) => switch (targets[id]) {
    final IntoGroup t when _myGroups.containsKey(t.groupId) => t,
    final OntoTag t when _myGroupOfTag.containsKey(t.tagId) => t,
    final UnderTag t when _myGroupOfTag.containsKey(t.tagId) => t,
    final AtTop t => t,
    _ => null,
  };

  /// Where the friend's group [g] goes: as mapped, else the user's group of
  /// the same name in the same place, else a new one there.
  GroupPlace groupPlace(TagGroup g) {
    final TagPlace? parent;
    switch (target(g.id)) {
      case IntoGroup(:final groupId):
        return _existingGroup(_myGroups[groupId]!, from: g);
      case UnderTag(:final tagId):
        parent = _existingTag(tagId);
      case AtTop():
        parent = null;
      default:
        parent = switch (parentOf(g)) {
          final p? => tagPlace(p),
          null => null,
        };
    }
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

  /// Where the friend's tag [t] goes: as mapped, else the tag of that name
  /// in its group's place, or a new one there. When nothing above it is
  /// mapped and the user has a tag of that name elsewhere, that one.
  TagPlace tagPlace(Tag t) {
    final GroupPlace group;
    switch (target(t.id)) {
      case OntoTag(:final tagId):
        return _existingTag(tagId, from: t);
      case IntoGroup(:final groupId):
        group = _existingGroup(_myGroups[groupId]!);
      default:
        group = groupPlace(groupOf(t.id));
    }
    final mapped = chainOf(t)
        .any((s) => target((s.group?.id ?? s.tag?.id)!) != null);
    final there = group.existing?.tags.where((m) => _sameTag(m, t)).firstOrNull;
    if (there == null && !mapped) {
      final elsewhere = [
        for (final g in mine.groups)
          for (final m in g.tags)
            if (_sameTag(m, t)) m,
      ].firstOrNull;
      if (elsewhere != null) {
        return _existingTag(elsewhere.id, from: t);
      }
    }
    return TagPlace._(
      existing: there,
      name: there?.name ?? t.name,
      group: group,
      from: t,
    );
  }

  /// The path of [t]'s place in the user's tags, from the top: each part
  /// with whether it is new, and the friend's group or tag to change to
  /// send that part elsewhere (for a part of the user's own on the way,
  /// the next one below it that stands for one of the friend's).
  List<({String name, bool isNew, Start start})> toPath(Tag t) {
    final parts = <({String name, bool isNew, Start? start})>[];
    late void Function(TagPlace) tag;
    void group(GroupPlace g) {
      if (g.parent case final p?) tag(p);
      parts.add((
        name: g.name,
        isNew: g.isNew,
        start: g.from == null ? null : (group: g.from, tag: null),
      ));
    }

    tag = (p) {
      group(p.group);
      parts.add((
        name: p.name,
        isNew: p.isNew,
        start: p.from == null ? null : (group: null, tag: p.from),
      ));
    };
    tag(tagPlace(t));
    Start below = (group: null, tag: t);
    return [
      for (final part in parts.reversed)
        (
          name: part.name,
          isNew: part.isNew,
          start: below = part.start ?? below,
        ),
    ].reversed.toList();
  }

  /// The user's tag for the nearest tag above [t] in the friend's
  /// structure that the user has: their Metal for the friend's Metal ›
  /// Subgenre › Black metal. Null when [t] is top-level or none matches.
  TagPlace? nearestAbove(Tag t) {
    for (
      var parent = parentOf(groupOf(t.id));
      parent != null;
      parent = parentOf(groupOf(parent.id))
    ) {
      final place = tagPlace(parent);
      if (!place.isNew) return place;
    }
    return null;
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

  TagPlace _existingTag(String id, {Tag? from}) {
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

  /// This plan with the user's shown groups as they are now ([shown]):
  /// tags made on the album entry since count as theirs.
  TagImport withMyGroups(List<TagGroup> shown) {
    if (identical(shown, mine.groups)) return this;
    final ids = {for (final g in shown) g.id};
    return withMine(
      Shelf(
        entries: const [],
        allGroups: [
          ...shown,
          for (final g in mine.allGroups)
            if (!ids.contains(g.id)) g,
        ],
      ),
    );
  }

  TagImport withMine(Shelf mine) => TagImport(
    from: from,
    theirs: theirs,
    tagIds: tagIds,
    mine: mine,
    targets: targets,
  );

  /// This plan with the friend's group or tag [id] mapped to [target].
  TagImport withTarget(String id, CopyTarget target) => TagImport(
    from: from,
    theirs: theirs,
    tagIds: tagIds,
    mine: mine,
    targets: {...targets, id: target},
  );

  /// The friend's groups and tags between [start] and [t] ([t] included)
  /// that are mapped on their own: a new mapping at [start] replaces them.
  List<Start> mappedBelow(Start start, Tag t) {
    final chain = chainOf(t);
    return [
      for (final s in chain.sublist(chain.indexOf(start) + 1))
        if (targets.containsKey(s.group?.id ?? s.tag?.id)) s,
    ];
  }

  /// This plan with [start] mapped to [target] on the way to [t].
  TagImport remap(Start start, CopyTarget target, Tag t) => withoutTargets([
    for (final s in mappedBelow(start, t)) (s.group?.id ?? s.tag?.id)!,
  ]).withTarget((start.group?.id ?? start.tag?.id)!, target);

  /// This plan with nothing mapped for the friend's groups or tags [ids].
  TagImport withoutTargets(Iterable<String> ids) => TagImport(
    from: from,
    theirs: theirs,
    tagIds: tagIds,
    mine: mine,
    targets: {...targets}..removeWhere((id, _) => ids.contains(id)),
  );

  /// Puts the friend's [tags] in their places, creating what is new, and
  /// returns the user's shelf after with, for the last of them, the tags to
  /// set on the album: parents first, then the tag. Reuses same-name groups
  /// and tags on the shelf as it is, so trying again creates nothing twice.
  Future<({Shelf mine, List<String> tagIds})> add(
    ShelfRepository shelf,
    List<Tag> tags,
  ) async {
    var plan = withMine(await shelf.load());
    var ids = <String>[];
    for (final t in tags) {
      final place = plan.tagPlace(t);
      final made = <Object, String>{}; // a new place → the user's ID
      late Future<String> Function(TagPlace) tag;

      Future<String> group(GroupPlace g) async {
        if (g.existing case final e?) return e.id;
        if (made[g] case final id?) return id;
        final parent = switch (g.parent) {
          final p? => await tag(p),
          null => null,
        };
        final there = plan.mine.allGroups.where(
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
        final there = plan.mine.allGroups
            .where((g) => g.id == groupId)
            .expand((g) => g.tags)
            .where((m) => m.name.toLowerCase() == t.name.toLowerCase());
        return made[t] =
            there.firstOrNull?.id ??
            (await shelf.createTag(groupId, t.name)).id;
      };

      ids = [
        for (final a in place.ancestors.toList().reversed) await tag(a),
        await tag(place),
      ];
      // The next one builds on what this one made.
      if (made.isNotEmpty) plan = plan.withMine(await shelf.load());
    }
    return (mine: plan.mine, tagIds: ids);
  }
}
