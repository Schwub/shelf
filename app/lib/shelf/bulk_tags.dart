import 'package:flutter/foundation.dart';

import 'shelf.dart';

/// Whether the selected albums have a tag: all, some or none of them.
enum TagState { all, some, none }

/// Tags for several albums at once (TASK-40): each tag of the visible
/// [groups] is put on all [entries], taken off all, or left as it is. The
/// rules of one album hold: in a one-per-album group a tag replaces the
/// others, a sub-tag puts its parent on, and a tag taken off takes its
/// sub-tags with it.
@immutable
class BulkTags {
  const BulkTags(this.groups, this.entries, [this._wanted = const {}]);

  final List<TagGroup> groups;
  final List<ShelfEntry> entries;

  /// True: on all; false: off all; missing: as it is.
  final Map<String, bool> _wanted;

  /// How many of [entries] have [tagId] now.
  int count(String tagId) =>
      entries.where((e) => e.tagIds.contains(tagId)).length;

  /// After the changes so far.
  TagState state(String tagId) => switch (_wanted[tagId]) {
    true => TagState.all,
    false => TagState.none,
    null => switch (count(tagId)) {
      0 => TagState.none,
      final n when n == entries.length => TagState.all,
      _ => TagState.some,
    },
  };

  bool get changed => _wanted.isNotEmpty;

  /// The same changes, with [group] as the Add sheet left it (new tags).
  BulkTags withGroup(TagGroup group) => BulkTags(
    [for (final g in groups) g.id == group.id ? group : g],
    entries,
    _wanted,
  );

  /// On all of them, unless it already is: then off all.
  BulkTags toggle(String tagId) {
    final wanted = {..._wanted};
    if (state(tagId) == TagState.all) {
      _off(tagId, wanted);
    } else {
      _on(tagId, wanted);
    }
    return BulkTags(groups, entries, wanted);
  }

  TagGroup _groupOf(String tagId) =>
      groups.firstWhere((g) => g.tags.any((t) => t.id == tagId));

  void _on(String tagId, Map<String, bool> wanted) {
    wanted[tagId] = true;
    final group = _groupOf(tagId);
    if (group.exclusive) {
      for (final t in group.tags) {
        if (t.id != tagId) _off(t.id, wanted);
      }
    }
    if (group.parentTagId case final parent?) _on(parent, wanted);
  }

  void _off(String tagId, Map<String, bool> wanted) {
    // Only what some album has needs taking off.
    if (count(tagId) > 0) {
      wanted[tagId] = false;
    } else {
      wanted.remove(tagId);
    }
    for (final g in groups) {
      if (g.parentTagId == tagId) {
        for (final t in g.tags) {
          _off(t.id, wanted);
        }
      }
    }
  }

  /// What Apply does: tags to take off, then tags to put on, parents before
  /// their sub-tags.
  ({Set<String> remove, List<String> add}) get changes {
    int depth(String tagId) => switch (_groupOf(tagId).parentTagId) {
      final parent? => depth(parent) + 1,
      null => 0,
    };
    return (
      remove: {
        for (final MapEntry(:key, :value) in _wanted.entries)
          if (!value) key,
      },
      add: [
        for (final MapEntry(:key, :value) in _wanted.entries)
          if (value) key,
      ]..sort((a, b) => depth(a).compareTo(depth(b))),
    );
  }
}
