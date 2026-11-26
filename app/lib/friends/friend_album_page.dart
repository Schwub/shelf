import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../search/album_search.dart';
import '../shelf/entry_page.dart';
import '../shelf/shelf.dart';
import '../shelf/shelf_repository.dart';
import '../shelf/tag_import.dart';
import '../theme/shelf_colors.dart';
import '../widgets/cover.dart';
import '../widgets/rating_keys.dart';
import '../widgets/rating_meter.dart';
import '../widgets/shelf_key.dart';
import 'friends_repository.dart';

/// One album as a friend has it: their rating, comment, tags and favorite
/// tracks. Adds it to the user's shelf, or opens their own entry.
class FriendAlbumPage extends StatelessWidget {
  const FriendAlbumPage({
    super.key,
    required this.friend,
    required this.entry,
    required this.theirs,
    required this.mine,
    required this.shelf,
  });

  final Friend friend;
  final ShelfEntry entry;

  /// The friend's shelf, for their tag names; the user's, to find the album.
  final Shelf theirs, mine;
  final ShelfRepository shelf;

  /// The same catalog album, or the user's copy of one the friend added by
  /// hand (a separate album with the same title and artist).
  ShelfEntry? get _myEntry {
    final album = entry.album;
    bool same(Album a) =>
        a.id == album.id ||
        (album.musicbrainzId == null &&
            a.musicbrainzId == null &&
            a.title.toLowerCase() == album.title.toLowerCase() &&
            a.artist.toLowerCase() == album.artist.toLowerCase());
    return mine.entries.where((e) => same(e.album)).firstOrNull;
  }

  Future<void> _addOrOpen(BuildContext context) async {
    final album = entry.album;
    final fromFriend = TagImport(
      from: (userId: friend.id, name: friend.name),
      theirs: theirs,
      tagIds: entry.tagIds,
      mine: mine,
    );
    // Their track list, without their favorites.
    final tracks = [for (final t in entry.tracks) t.copyWith(favorite: false)];
    final page = switch ((_myEntry, album.musicbrainzId)) {
      (final own?, _) => EntryPage(
        entry: own,
        shelf: shelf,
        groups: mine.groups,
      ),
      (null, final id?) => EntryPage.add(
        result: SearchResult(
          musicbrainzId: id,
          title: album.title,
          artist: album.artist,
          year: album.year,
        ),
        shelf: shelf,
        groups: mine.groups,
        fromFriend: fromFriend,
        tracks: tracks,
      ),
      // Added by hand: the user gets their own copy.
      (null, null) => EntryPage.manual(
        manual: ManualAlbum(
          title: album.title,
          artist: album.artist,
          year: album.year,
        ),
        shelf: shelf,
        groups: mine.groups,
        fromFriend: fromFriend,
        tracks: tracks,
      ),
    };
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await navigator.push(
      MaterialPageRoute<EntryResult>(builder: (_) => page),
    );
    switch (result) {
      case EntryResult.added:
        messenger.showSnackBar(
          const SnackBar(content: Text('Added to your shelf')),
        );
        navigator.pop();
      case EntryResult.removed:
        // As on My shelf: removed once the snackbar closes without Undo.
        final removing = _myEntry!.id;
        navigator.pop();
        final reason = await messenger
            .showSnackBar(
              SnackBar(
                content: const Text('Removed from your shelf'),
                action: SnackBarAction(label: 'Undo', onPressed: () {}),
                persist: false,
                duration: const Duration(seconds: 5),
              ),
            )
            .closed;
        if (reason == SnackBarClosedReason.action) return;
        try {
          await shelf.remove(removing);
        } catch (e, stack) {
          reportError(e, stack);
          messenger.showSnackBar(
            const SnackBar(content: Text("Couldn't remove the album.")),
          );
        }
      case EntryResult.saved:
        navigator.pop();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final label = text.labelSmall!.copyWith(color: c.muted);
    final album = entry.album;
    final name = friend.name;
    final tags = [
      for (final g in theirs.allGroups)
        for (final t in g.tags)
          if (entry.tagIds.contains(t.id)) t.name,
    ];
    final favorites = [
      for (final t in entry.tracks)
        if (t.favorite) t,
    ];
    final myEntry = _myEntry;
    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: label),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 96, child: Cover(album)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(album.title, style: text.titleLarge),
                    Text(album.artist, style: text.bodyMedium),
                    if (album.year case final year?)
                      Text(
                        '$year',
                        style: text.bodySmall!.copyWith(color: c.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (entry.rating case final rating?)
            section(
              "$name's rating",
              Semantics(
                label: RatingKeys.describe(rating),
                excludeSemantics: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RatingMeter(rating),
                ),
              ),
            ),
          if (entry.comment case final comment?)
            section("$name's comment", Text(comment)),
          if (tags.isNotEmpty)
            section(
              "$name's tags",
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(tag, style: text.bodySmall),
                      ),
                    ),
                ],
              ),
            ),
          if (favorites.isNotEmpty)
            section(
              "$name's favorite tracks",
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in favorites) Text('${t.position}. ${t.title}'),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: ShelfKey(
            primary: myEntry == null,
            onPressed: () => _addOrOpen(context),
            child: Text(
              myEntry == null ? 'Add to my shelf' : 'Open on your shelf',
            ),
          ),
        ),
      ),
    );
  }
}
