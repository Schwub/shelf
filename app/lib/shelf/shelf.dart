import 'dart:convert';

import 'package:flutter/foundation.dart';

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

/// A track on the user's own track list of an album (docs/features/tracks.md).
@immutable
class Track {
  const Track({
    required this.title,
    this.disc = 1,
    required this.position,
    this.lengthMs,
    this.favorite = false,
  });

  final String title;
  final int disc, position;
  final int? lengthMs;
  final bool favorite;

  Track copyWith({String? title, int? disc, int? position, bool? favorite}) =>
      Track(
        title: title ?? this.title,
        disc: disc ?? this.disc,
        position: position ?? this.position,
        lengthMs: lengthMs,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toJson() => {
    'disc': disc,
    'position': position,
    'title': title.trim(),
    'length_ms': lengthMs,
    'favorite': favorite,
  };

  @override
  bool operator ==(Object other) =>
      other is Track &&
      other.title == title &&
      other.disc == disc &&
      other.position == position &&
      other.lengthMs == lengthMs &&
      other.favorite == favorite;

  @override
  int get hashCode => Object.hash(title, disc, position, lengthMs, favorite);
}

/// An album on the user's shelf. [rating] is in half stars (1–10).
@immutable
class ShelfEntry {
  const ShelfEntry({
    required this.id,
    required this.album,
    required this.addedAt,
    this.rating,
    this.comment,
    this.tagIds = const {},
    this.tracks = const [],
    this.hidden = false,
    this.addedFromName,
  });

  final String id;
  final Album album;

  /// When it went on the shelf.
  final DateTime addedAt;
  final int? rating;
  final String? comment;
  final Set<String> tagIds;

  /// The user's track list, disc by disc; empty until they approve or enter
  /// one.
  final List<Track> tracks;

  /// Hidden from friends: not on the shelf they see, nor in their feed.
  final bool hidden;

  /// The friend whose shelf it was added from, by their name then.
  final String? addedFromName;
}

/// The friend an album is added from.
typedef AddedFrom = ({String userId, String name});

@immutable
class Tag {
  const Tag({
    required this.id,
    required this.groupId,
    required this.name,
    this.builtin,
  });

  final String id, groupId, name;

  /// The key of Want, Own, Want to listen or Listened (`want`, `own`,
  /// `want_to_listen`, `listened`): can't be deleted, and friends' shelves
  /// compare on it.
  final String? builtin;
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
    this.builtin,
    this.hidden = false,
    this.pickFromList = false,
    this.tags = const [],
  });

  final String id, name;

  /// On albums, only the chosen tags show, picked from an alphabetical list
  /// (Genre); otherwise all tags show as keys.
  final bool pickFromList;

  final bool exclusive, hidden;

  /// The key of a built-in group (`collection`, `listening`): it can be
  /// renamed and hidden, not deleted; only built-in groups can be hidden.
  final String? builtin;
  final String? parentTagId;
  final List<Tag> tags;

  TagGroup withTag(Tag tag) => copyWith(tags: [...tags, tag]);

  TagGroup copyWith({
    String? name,
    bool? exclusive,
    bool? hidden,
    bool? pickFromList,
    List<Tag>? tags,
  }) => TagGroup(
    id: id,
    name: name ?? this.name,
    exclusive: exclusive ?? this.exclusive,
    parentTagId: parentTagId,
    builtin: builtin,
    hidden: hidden ?? this.hidden,
    pickFromList: pickFromList ?? this.pickFromList,
    tags: tags ?? this.tags,
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

/// A key of the shelf's filter bar: albums with its tags (any or all of
/// them), a minimum rating or none, favorite tracks, added in the last
/// days or between two dates (docs/features/filters.md). A filter with one tag and nothing else shows
/// the tag's name; others carry their own [name].
@immutable
class ShelfFilter {
  const ShelfFilter({
    this.id = '',
    this.name,
    this.label = '',
    this.tagIds = const [],
    this.matchAll = false,
    this.minRating,
    this.unrated = false,
    this.favoriteTracks = false,
    this.addedWithinDays,
    this.addedFrom,
    this.addedTo,
  });

  /// The simple filter: albums with [tagId].
  ShelfFilter.tag(String tagId, String label, {String? id})
    : this(id: id ?? tagId, label: label, tagIds: [tagId]);

  /// Empty for a filter not saved yet.
  final String id;
  final String? name;

  /// What the filter bar shows: [name], or the tag's name.
  final String label;

  final List<String> tagIds;
  final bool matchAll, unrated, favoriteTracks;

  /// In half stars, like [ShelfEntry.rating].
  final int? minRating;

  /// Added in the last days, or from and to a day (both included, either
  /// open); never both kinds.
  final int? addedWithinDays;
  final DateTime? addedFrom, addedTo;

  bool get _added =>
      addedWithinDays != null || addedFrom != null || addedTo != null;

  /// One tag and nothing else: shown by the tag's name.
  bool get isTag =>
      tagIds.length == 1 &&
      minRating == null &&
      !unrated &&
      !favoriteTracks &&
      !_added;

  bool get hasConditions =>
      tagIds.isNotEmpty ||
      minRating != null ||
      unrated ||
      favoriteTracks ||
      _added;

  ShelfFilter copyWith({
    String? label,
    String? name,
    List<String>? tagIds,
    bool? matchAll,
    int? Function()? minRating,
    bool? unrated,
    bool? favoriteTracks,
    int? Function()? addedWithinDays,
    DateTime? Function()? addedFrom,
    DateTime? Function()? addedTo,
  }) => ShelfFilter(
    id: id,
    name: name ?? this.name,
    label: label ?? this.label,
    tagIds: tagIds ?? this.tagIds,
    matchAll: matchAll ?? this.matchAll,
    minRating: minRating != null ? minRating() : this.minRating,
    unrated: unrated ?? this.unrated,
    favoriteTracks: favoriteTracks ?? this.favoriteTracks,
    addedWithinDays: addedWithinDays != null
        ? addedWithinDays()
        : this.addedWithinDays,
    addedFrom: addedFrom != null ? addedFrom() : this.addedFrom,
    addedTo: addedTo != null ? addedTo() : this.addedTo,
  );

  bool matches(ShelfEntry e) {
    final t = tagIds;
    if (t.isNotEmpty &&
        !(matchAll ? t.every(e.tagIds.contains) : t.any(e.tagIds.contains))) {
      return false;
    }
    if (minRating case final min? when (e.rating ?? 0) < min) return false;
    if (unrated && e.rating != null) return false;
    if (favoriteTracks && !e.tracks.any((t) => t.favorite)) return false;
    final added = e.addedAt.toLocal();
    if (addedWithinDays case final days?
        when added.isBefore(DateTime.now().subtract(Duration(days: days)))) {
      return false;
    }
    final day = DateTime(added.year, added.month, added.day);
    if (addedFrom case final from? when day.isBefore(from)) return false;
    if (addedTo case final to? when day.isAfter(to)) return false;
    return true;
  }
}

class Shelf {
  Shelf({
    required this.entries,
    this.allFilters = const [],
    this.allGroups = const [],
  });

  /// Newest first.
  final List<ShelfEntry> entries;

  /// Every filter and tag group, hidden ones included, in the user's order
  /// (sub-groups among them).
  final List<ShelfFilter> allFilters;
  final List<TagGroup> allGroups;

  /// The groups shown on albums: hidden ones and the sub-groups under their
  /// tags left out.
  late final List<TagGroup> groups = () {
    final groupOfTag = {
      for (final g in allGroups)
        for (final t in g.tags) t.id: g,
    };
    bool hidden(TagGroup g) {
      if (g.hidden) return true;
      final parent = groupOfTag[g.parentTagId];
      return parent != null && hidden(parent);
    }

    return [
      for (final g in allGroups)
        if (!hidden(g)) g,
    ];
  }();

  /// The filter bar's filters: those whose tags are all shown (a hidden
  /// group hides its filters); "All" is implicit.
  late final List<ShelfFilter> filters = () {
    final shown = {
      for (final g in groups)
        for (final t in g.tags) t.id,
    };
    return [
      for (final f in allFilters)
        if (f.tagIds.every(shown.contains)) f,
    ];
  }();

  /// The sub-group shown while [tagId] is chosen, if any.
  TagGroup? subGroupOf(String tagId) =>
      allGroups.where((g) => g.parentTagId == tagId).firstOrNull;

  /// How many albums have [tagId].
  int albumsWith(String tagId) =>
      entries.where((e) => e.tagIds.contains(tagId)).length;

  /// Entries with [filter]'s tag, or all of them for null ("All").
  List<ShelfEntry> matching(ShelfFilter? filter) =>
      filter == null ? entries : entries.where(filter.matches).toList();
}

/// What a shelf can be sorted by (TASK-39).
enum SortBy { added, title, artist, year, rating }

/// How a shelf is sorted: each order starts the way it is usually read
/// (newest, A–Z, highest first), and [reversed] turns it round. Albums
/// without a year or rating go last either way.
@immutable
class ShelfSort {
  const ShelfSort(this.by, {this.reversed = false});

  static const newest = ShelfSort(SortBy.added);

  final SortBy by;
  final bool reversed;

  /// How it is saved: `title`, `title_reversed`; anything else is [newest].
  String get key => reversed ? '${by.name}_reversed' : by.name;

  static ShelfSort parse(String? key) {
    for (final by in SortBy.values) {
      if (key == by.name) return ShelfSort(by);
      if (key == '${by.name}_reversed') return ShelfSort(by, reversed: true);
    }
    return newest;
  }

  /// [entries] (newest first, as loaded) in this order; equal ones stay
  /// newest first.
  List<ShelfEntry> apply(List<ShelfEntry> entries) {
    final added = {for (final (i, e) in entries.indexed) e: i};
    int compare<T extends Comparable<Object>>(T? a, T? b, {bool high = false}) {
      if (a == null || b == null) return a == null ? (b == null ? 0 : 1) : -1;
      final c = a.compareTo(b);
      return high != reversed ? -c : c;
    }

    String lower(String s) => s.toLowerCase();
    int order(ShelfEntry a, ShelfEntry b) => switch (by) {
      SortBy.added => compare(added[b], added[a], high: true),
      SortBy.title => compare(lower(a.album.title), lower(b.album.title)),
      SortBy.artist => switch (compare(
        lower(a.album.artist),
        lower(b.album.artist),
      )) {
        // An artist's albums from the first on.
        0 => (a.album.year ?? 9999).compareTo(b.album.year ?? 9999),
        final c => c,
      },
      SortBy.year => compare(a.album.year, b.album.year, high: true),
      SortBy.rating => compare(a.rating, b.rating, high: true),
    };
    return [...entries]..sort(
      (a, b) => switch (order(a, b)) {
        0 => added[a]!.compareTo(added[b]!),
        final c => c,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShelfSort && other.by == by && other.reversed == reversed;

  @override
  int get hashCode => Object.hash(by, reversed);
}
