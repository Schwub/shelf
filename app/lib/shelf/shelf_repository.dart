import 'package:flutter/foundation.dart';

import 'shelf.dart';

/// The signed-in user's shelf. An interface so the screens can be tested
/// without a server.
abstract class ShelfRepository {
  Future<Shelf> load();

  /// Notified after an entry is added, saved or removed and after a tag or
  /// group is created, so My shelf reloads after edits made from another
  /// tab (a friend's album, and tags copied from it).
  Listenable get changes;

  /// A friend's shelf with their filters, without the entries they hide
  /// from friends.
  Future<Shelf> loadFriend(String userId);

  /// Rating in half stars or null; an empty comment is stored as none.
  /// [addTags] go on in their order (parent tags before their sub-tags),
  /// after [removeTags] come off. [tracks] replace the track list and
  /// [hidden] hides the entry from friends; null leaves them.
  Future<void> save(
    String entryId, {
    int? rating,
    String? comment,
    Set<String> removeTags = const {},
    List<String> addTags = const [],
    List<Track>? tracks,
    bool? hidden,
  });

  Future<void> remove(List<String> entryIds);

  /// Several albums at once (TASK-40): [remove] comes off each, then [add]
  /// goes on each (parents before their sub-tags; tags an album has stay).
  Future<void> changeTags(
    List<String> entryIds, {
    Set<String> remove = const {},
    List<String> add = const [],
  });

  /// Hides [entryIds] from friends, or shows them.
  Future<void> hide(List<String> entryIds, bool hidden);

  /// Where the friend's groups [friendGroupIds] go when copying their tags,
  /// as chosen before (TASK-48); groups never chosen are left out.
  Future<Map<String, Destination>> destinations(List<String> friendGroupIds);

  /// [destination] null forgets the choice.
  Future<void> saveDestination(String friendGroupId, Destination? destination);

  /// Adds the album with this MusicBrainz ID to the shelf: the add-album
  /// function puts it in the shared catalog (with its cover) if needed.
  /// [addedFrom] is the friend whose shelf it came from.
  Future<void> add(
    String musicbrainzId, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
    bool hidden = false,
    AddedFrom? addedFrom,
  });

  /// Adds an album by hand: the add-album function adds it as the user's
  /// own, with the photo as its cover.
  Future<void> addManual(
    ManualAlbum album, {
    int? rating,
    String? comment,
    List<String> tags = const [],
    List<Track> tracks = const [],
    bool hidden = false,
    AddedFrom? addedFrom,
  });

  /// The track list MusicBrainz has for the album [musicbrainzId], to
  /// suggest; empty when it has none.
  Future<List<Track>> trackList(String musicbrainzId);

  /// A new tag at the end of [groupId]; the name must be new in that group
  /// ([DuplicateName] otherwise).
  Future<Tag> createTag(String groupId, String name);

  // The tag editor. Names must be new on their level ([DuplicateName]).

  /// A new group at the end, or the sub-group shown while [parentTagId] is
  /// chosen, with [tags] in their order.
  Future<void> createGroup(
    String name, {
    required bool exclusive,
    bool pickFromList = false,
    String? parentTagId,
    List<String> tags = const [],
  });

  /// Making a group exclusive while an album has several of its tags throws
  /// [SeveralTags]. Only built-in groups can be hidden.
  Future<void> updateGroup(
    String groupId, {
    String? name,
    bool? exclusive,
    bool? hidden,
    bool? pickFromList,
  });

  /// Also removes its tags from albums, its sub-groups and their filters.
  Future<void> deleteGroup(String groupId);

  Future<void> renameTag(String tagId, String name);

  /// Also removes it from albums, and its sub-group and filters.
  Future<void> deleteTag(String tagId);

  /// Groups or tags in this new order.
  Future<void> reorderGroups(List<String> groupIds);
  Future<void> reorderTags(List<String> tagIds);

  // Filters (docs/features/filters.md).

  /// Adds [filter] at the end (no [ShelfFilter.id]) or saves its changes.
  Future<void> saveFilter(ShelfFilter filter);
  Future<void> deleteFilter(String filterId);
  Future<void> reorderFilters(List<String> filterIds);
}

/// A tag or group name already used on its level, ignoring case.
class DuplicateName implements Exception {}

/// A group can't become one per album while albums have several of its tags.
class SeveralTags implements Exception {}
