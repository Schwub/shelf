import 'package:flutter/foundation.dart';

import 'shelf.dart';
import 'shelf_repository.dart';

/// Where one of the friend's tags would go on the user's side: an existing
/// tag of theirs ([tag]), or a new tag of the same name in [group], or in a
/// new group like the friend's when [group] is null.
@immutable
class TagTarget {
  const TagTarget({this.group, this.tag});

  final TagGroup? group;
  final Tag? tag;

  /// The user has this tag already.
  bool get matches => tag != null;

  @override
  bool operator ==(Object other) =>
      other is TagTarget &&
      other.group?.id == group?.id &&
      other.tag?.id == tag?.id;

  @override
  int get hashCode => Object.hash(group?.id, tag?.id);
}

/// Adding a friend's album: their tags on it, each with a suggested target
/// among the user's groups (docs/features/tags.md, "Copy a friend's tags").
/// Nothing is set or copied until the user ticks it.
class TagImport {
  TagImport({
    required this.from,
    required this.theirs,
    required this.tagIds,
    required this.mine,
    this.destinations = const {},
  });

  final AddedFrom from;

  /// The friend's shelf and their tags on the album.
  final Shelf theirs;
  final Set<String> tagIds;

  /// The user's shelf the suggestions are made for.
  final Shelf mine;

  /// The user's group for each of the friend's top-level groups, as chosen
  /// before (remembered per friend).
  final Map<String, String> destinations;

  late final _groupOfTag = {
    for (final g in theirs.allGroups)
      for (final t in g.tags) t.id: g,
  };

  /// The friend's group of their tag [tagId].
  TagGroup groupOf(String tagId) => _groupOfTag[tagId]!;

  /// The album's tags in the friend's shown groups, in their order, each
  /// parent tag before the tags of its sub-groups. Left out: tags in a
  /// built-in group the user hides, and sub-tags whose parent tag isn't a
  /// row.
  late final List<Tag> rows = () {
    int depth(TagGroup g) => switch (_groupOfTag[g.parentTagId]) {
      final parent? => depth(parent) + 1,
      null => 0,
    };
    // A stable sort by depth: top-level groups first, each in order.
    final levels = <int, List<TagGroup>>{};
    for (final g in theirs.groups) {
      (levels[depth(g)] ??= []).add(g);
    }
    final rows = <Tag>[];
    final ids = <String>{};
    for (final d in levels.keys.toList()..sort()) {
      for (final g in levels[d]!) {
        if (g.builtin case final key?
            when !mine.groups.any((m) => m.builtin == key)) {
          continue;
        }
        if (g.parentTagId case final p? when !ids.contains(p)) continue;
        for (final t in g.tags) {
          if (tagIds.contains(t.id) && ids.add(t.id)) rows.add(t);
        }
      }
    }
    return rows;
  }();

  /// The suggested target for the friend's tag [tag], given the targets the
  /// user picked for other rows ([picked], by the friend's tag ID): a
  /// sub-tag follows its parent tag's.
  TagTarget suggest(Tag tag, [Map<String, TagTarget> picked = const {}]) {
    final group = _groupFor(groupOf(tag.id), picked);
    return TagTarget(
      group: group,
      tag: group?.tags.where((t) => _same(t, tag)).firstOrNull,
    );
  }

  /// The user's group for the friend's [group]: as chosen before, by
  /// built-in key, else by name (under the target of the parent tag for a
  /// sub-group); null for a new group. Only the user's shown groups: tags
  /// set in hidden ones wouldn't show on the album.
  TagGroup? _groupFor(TagGroup group, Map<String, TagTarget> picked) {
    if (group.parentTagId case final parent?) {
      final parentTag =
          (picked[parent] ??
                  suggest(
                    groupOf(parent).tags.firstWhere((t) => t.id == parent),
                    picked,
                  ))
              .tag;
      if (parentTag == null) return null;
      return mine.groups
          .where((g) => g.parentTagId == parentTag.id && _sameName(g, group))
          .firstOrNull;
    }
    final chosen = destinations[group.id];
    if (mine.groups.where((g) => g.id == chosen).firstOrNull case final g?) {
      return g;
    }
    if (group.builtin case final key?) {
      return mine.groups.where((g) => g.builtin == key).firstOrNull;
    }
    return mine.groups
        .where((g) => g.parentTagId == null && _sameName(g, group))
        .firstOrNull;
  }

  static bool _sameName(TagGroup a, TagGroup b) =>
      a.name.toLowerCase() == b.name.toLowerCase();

  static bool _same(Tag mine, Tag theirs) =>
      (theirs.builtin != null && mine.builtin == theirs.builtin) ||
      mine.name.toLowerCase() == theirs.name.toLowerCase();

  TagImport withDestination(String friendGroupId, String groupId) => TagImport(
    from: from,
    theirs: theirs,
    tagIds: tagIds,
    mine: mine,
    destinations: {...destinations, friendGroupId: groupId},
  );

  TagImport withMine(Shelf mine) => TagImport(
    from: from,
    theirs: theirs,
    tagIds: tagIds,
    mine: mine,
    destinations: destinations,
  );

  /// Puts the friend's ticked tags ([targets], by their tag ID) where their
  /// targets say, creating what is new, and returns the user's shelf after
  /// with the tags to set on the album (parent tags of sub-groups too).
  /// Starts from the shelf as it is, and reuses what an earlier, failed try
  /// created, so trying again creates nothing twice.
  Future<({Shelf mine, Set<String> tagIds})> apply(
    ShelfRepository shelf,
    Map<String, TagTarget> targets,
  ) async {
    var current = await shelf.load();
    final made = <String, String>{}; // the friend's tag ID → the user's
    for (final tag in rows) {
      final target = targets[tag.id];
      if (target == null) continue;
      if (target.tag case final existing?) {
        made[tag.id] = existing.id;
        continue;
      }
      final theirGroup = groupOf(tag.id);
      var groupId = target.group?.id;
      if (groupId == null) {
        // A new group like the friend's, under the parent tag's copy.
        final parent = switch (theirGroup.parentTagId) {
          final p? => made[p],
          null => null,
        };
        if (theirGroup.parentTagId != null && parent == null) continue;
        groupId =
            current.allGroups
                .where(
                  (g) => g.parentTagId == parent && _sameName(g, theirGroup),
                )
                .firstOrNull
                ?.id ??
            await shelf.createGroup(
              theirGroup.name,
              exclusive: theirGroup.exclusive,
              pickFromList: theirGroup.pickFromList,
              parentTagId: parent,
            );
        current = await shelf.load();
      }
      final group = current.allGroups.firstWhere((g) => g.id == groupId);
      final there = group.tags
          .where((t) => t.name.toLowerCase() == tag.name.toLowerCase())
          .firstOrNull;
      made[tag.id] =
          there?.id ?? (await shelf.createTag(group.id, tag.name)).id;
      current = await shelf.load();
    }
    // A tag in a sub-group needs its parent tag on the album too.
    final groupOfMine = {
      for (final g in current.allGroups)
        for (final t in g.tags) t.id: g,
    };
    final set = <String>{};
    for (final id in made.values) {
      for (
        String? t = id;
        t != null && set.add(t);
        t = groupOfMine[t]?.parentTagId
      ) {}
    }
    return (mine: current, tagIds: set);
  }
}
