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

/// Where a friend's top-level group goes, chosen on the copy screen and
/// remembered per friend: into one of the user's groups ([groupId]), or
/// nowhere. Without one, it goes into the user's group of the same name,
/// or a new group like it.
@immutable
class Destination {
  const Destination.into(String this.groupId);
  const Destination.nowhere() : groupId = null;

  final String? groupId;

  @override
  bool operator ==(Object other) =>
      other is Destination && other.groupId == groupId;

  @override
  int get hashCode => groupId.hashCode;
}

/// Adding a friend's album: which of their tags the user has, which are
/// missing, and where copies go (docs/features/tags.md, "Copy a friend's
/// tags").
class TagImport {
  TagImport({
    required this.from,
    required this.theirs,
    required this.tagIds,
    required this.mine,
    this.destinations = const {},
  }) {
    final album = _plan(tagIds, album: true);
    _matched.addAll(album.matched);
    missing.addAll(album.missing);
  }

  final AddedFrom from;

  /// The friend's shelf and their tags on the album.
  final Shelf theirs;
  final Set<String> tagIds;

  /// The user's shelf the plan was made for.
  final Shelf mine;

  /// By the friend's top-level group ID.
  final Map<String, Destination> destinations;

  /// The friend's tag IDs on the album to the user's matching ones.
  final _matched = <String, String>{};

  /// The album's tags the user doesn't have, in the friend's group order,
  /// parent tags before their sub-tags.
  final missing = <MissingTag>[];

  /// The user's tags to set on the album.
  Set<String> get preset => _matched.values.toSet();

  /// The user's built-in tags among [preset], for the "set like" note.
  List<Tag> get builtins => [
    for (final g in mine.groups)
      for (final t in g.tags)
        if (t.builtin != null && preset.contains(t.id)) t,
  ];

  /// Every tag the friend shows, planned like the album's but without the
  /// one-per-album rule: for the copy screen's marks.
  late final _all = _plan({
    for (final g in theirs.groups)
      for (final t in g.tags) t.id,
  }, album: false);

  /// Whether the user has the friend's tag [tagId] (where it would go).
  bool has(String tagId) => _all.matched.containsKey(tagId);

  /// Whether the friend's tag [tagId] can be copied: it isn't the user's
  /// already and its group goes somewhere.
  bool copyable(String tagId) => _all.missing.any((m) => m.tag.id == tagId);

  /// Where the friend's top-level [group] goes: the user's group, or null
  /// for a new one; [Destination.nowhere] when it isn't copied.
  ({TagGroup? into, bool nowhere}) target(TagGroup group) {
    final into = _groupFor(group, null);
    return (into: into, nowhere: _nowhere(group));
  }

  bool _nowhere(TagGroup group) =>
      group.builtin == null &&
      group.parentTagId == null &&
      destinations[group.id] == const Destination.nowhere();

  TagImport withDestination(TagGroup group, Destination destination) =>
      _replan(mine, {...destinations, group.id: destination});

  ({Map<String, String> matched, List<MissingTag> missing}) _plan(
    Set<String> ids, {
    required bool album,
  }) {
    final matched = <String, String>{};
    final missing = <MissingTag>[];
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
    final skipped = <String>{};
    for (final group in groups) {
      if (_nowhere(group) || skipped.contains(group.parentTagId)) {
        skipped.addAll(group.tags.map((t) => t.id));
        continue;
      }
      for (final tag in group.tags) {
        if (!ids.contains(tag.id)) continue;
        String? parent;
        if (group.parentTagId case final theirParent?) {
          parent = matched[theirParent];
          final offered = missing.any((m) => m.tag.id == theirParent);
          if (parent == null && !offered) continue;
        }
        final into = _groupFor(group, parent);
        if (into != null) {
          if (!shown.contains(into.id)) continue;
          // One per album only matters on the album; copies may share.
          if (album && into.exclusive && !filled.add(into.id)) continue;
        }
        final match = into?.tags.where((t) => _same(t, tag)).firstOrNull;
        if (match != null) {
          matched[tag.id] = match.id;
        } else {
          missing.add(MissingTag(tag, group, into: into, parentTagId: parent));
        }
      }
    }
    return (matched: matched, missing: missing);
  }

  /// The user's group for the friend's [group]: by built-in key, by the
  /// chosen destination, else by name (under the user's [parent] tag for a
  /// sub-group); null for a new group.
  TagGroup? _groupFor(TagGroup group, String? parent) {
    if (group.builtin case final key?) {
      return mine.allGroups.where((g) => g.builtin == key).firstOrNull;
    }
    if (group.parentTagId != null && parent == null) return null;
    if (group.parentTagId == null) {
      if (destinations[group.id]?.groupId case final id?) {
        if (mine.allGroups.where((g) => g.id == id).firstOrNull
            case final chosen?) {
          return chosen;
        }
      }
    }
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

  TagImport _replan(Shelf mine, [Map<String, Destination>? destinations]) =>
      TagImport(
        from: from,
        theirs: theirs,
        tagIds: tagIds,
        mine: mine,
        destinations: destinations ?? this.destinations,
      );

  /// Copies the friend's tags [picked] (their IDs, from anywhere in their
  /// tree) to their destinations and returns the plan for the user's shelf
  /// after, which matches the copies. Goes in rounds, parents first; each
  /// starts from the shelf as it is, so trying again after a failure copies
  /// only what is still missing.
  Future<TagImport> copy(ShelfRepository shelf, Set<String> picked) async {
    var plan = _replan(await shelf.load());
    var left = picked;
    while (true) {
      final ready = [
        // All of them, so tags copied in earlier rounds count as parents.
        for (final m in plan._plan(picked, album: false).missing)
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
