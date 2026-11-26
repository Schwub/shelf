import 'package:flutter/foundation.dart';

import 'shelf.dart';
import 'shelf_repository.dart';

/// A friend's tag the user doesn't have, and where its copy goes.
@immutable
class MissingTag {
  const MissingTag(this.tag, this.group, {this.into, this.parentTagId});

  /// The friend's tag and group.
  final Tag tag;
  final TagGroup group;

  /// The user's group the copy goes into; null for a new group like [group].
  final TagGroup? into;

  /// For a new sub-group: the user's tag it goes under.
  final String? parentTagId;

  /// False while the tag it hangs under is missing too.
  bool get ready =>
      into != null || group.parentTagId == null || parentTagId != null;
}

/// Adding a friend's album: which of their tags on it the user has, and
/// which are missing (docs/features/tags.md, "Import from a friend").
class TagImport {
  TagImport({
    required this.from,
    required this.theirs,
    required this.tagIds,
    required this.mine,
  }) {
    _plan();
  }

  final AddedFrom from;

  /// The friend's shelf and their tags on the album.
  final Shelf theirs;
  final Set<String> tagIds;

  /// The user's shelf the plan was made for.
  final Shelf mine;

  /// The friend's tag IDs to the user's matching ones.
  final _matched = <String, String>{};

  /// In the friend's group order, parent tags before their sub-tags.
  final missing = <MissingTag>[];

  /// The user's tags to set on the album.
  Set<String> get preset => _matched.values.toSet();

  /// The user's built-in tags among [preset], for the "set like" note.
  List<Tag> get builtins => [
    for (final g in mine.groups)
      for (final t in g.tags)
        if (t.builtin != null && preset.contains(t.id)) t,
  ];

  void _plan() {
    final groupOfTag = {
      for (final g in theirs.allGroups)
        for (final t in g.tags) t.id: g,
    };
    int depth(TagGroup g) => switch (groupOfTag[g.parentTagId]) {
      final parent? => depth(parent) + 1,
      null => 0,
    };
    // Top-level groups, then sub-groups, each in the friend's order (a
    // stable sort); groups hidden by the friend are left out of
    // theirs.groups.
    final levels = <int, List<TagGroup>>{};
    for (final g in theirs.groups) {
      (levels[depth(g)] ??= []).add(g);
    }
    final groups = [
      for (final d in levels.keys.toList()..sort()) ...levels[d]!,
    ];
    final shown = {for (final g in mine.groups) g.id};
    final filled = <String>{};
    for (final group in groups) {
      for (final tag in group.tags) {
        if (!tagIds.contains(tag.id)) continue;
        String? parent;
        if (group.parentTagId case final theirParent?) {
          parent = _matched[theirParent];
          final offered = missing.any((m) => m.tag.id == theirParent);
          if (parent == null && !offered) continue;
        }
        final into = _groupFor(group, parent);
        if (into != null) {
          if (!shown.contains(into.id)) continue;
          if (into.exclusive && !filled.add(into.id)) continue;
        }
        final match = into?.tags.where((t) => _same(t, tag)).firstOrNull;
        if (match != null) {
          _matched[tag.id] = match.id;
        } else {
          missing.add(MissingTag(tag, group, into: into, parentTagId: parent));
        }
      }
    }
  }

  /// The user's group matching the friend's [group], under the user's
  /// [parent] tag for a sub-group.
  TagGroup? _groupFor(TagGroup group, String? parent) {
    if (group.builtin case final key?) {
      return mine.allGroups.where((g) => g.builtin == key).firstOrNull;
    }
    if (group.parentTagId != null && parent == null) return null;
    return mine.allGroups
        .where(
          (g) =>
              g.parentTagId == parent &&
              g.name.toLowerCase() == group.name.toLowerCase(),
        )
        .firstOrNull;
  }

  static bool _same(Tag mine, Tag theirs) => theirs.builtin != null
      ? mine.builtin == theirs.builtin
      : mine.name.toLowerCase() == theirs.name.toLowerCase();

  TagImport _replan(Shelf mine) =>
      TagImport(from: from, theirs: theirs, tagIds: tagIds, mine: mine);

  /// Copies the friend's tags [picked] (their IDs) to the user's groups and
  /// returns the plan for the user's shelf after, which matches the copies.
  /// Goes in rounds, parents first; each starts from the shelf as it is, so
  /// trying again after a failure copies only what is still missing.
  Future<TagImport> copy(ShelfRepository shelf, Set<String> picked) async {
    var plan = _replan(await shelf.load());
    var left = picked;
    while (true) {
      final ready = [
        for (final m in plan.missing)
          if (left.contains(m.tag.id) && m.ready) m,
      ];
      if (ready.isEmpty) return plan;
      final newGroups = <String, List<MissingTag>>{};
      for (final m in ready) {
        if (m.into case final into?) {
          await shelf.createTag(into.id, m.tag.name);
        } else {
          (newGroups[m.group.id] ??= []).add(m);
        }
      }
      for (final tags in newGroups.values) {
        final group = tags.first.group;
        await shelf.createGroup(
          group.name,
          exclusive: group.exclusive,
          pickFromList: group.pickFromList,
          parentTagId: tags.first.parentTagId,
          tags: [for (final m in tags) m.tag.name],
        );
      }
      left = left.difference({for (final m in ready) m.tag.id});
      plan = _replan(await shelf.load());
    }
  }
}
