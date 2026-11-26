import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../shelf/shelf.dart';
import '../shelf/shelf_repository.dart';
import '../theme/shelf_colors.dart';
import '../widgets/message.dart';
import '../widgets/shelf_key.dart';
import 'friend_album_page.dart';
import 'friends_repository.dart';

/// A friend's album opened from elsewhere (the feed): loads their shelf and
/// the user's, then shows [FriendAlbumPage] for [entryId].
class FriendAlbumLoader extends StatefulWidget {
  const FriendAlbumLoader({
    super.key,
    required this.friend,
    required this.entryId,
    required this.shelf,
  });

  final Friend friend;
  final String entryId;
  final ShelfRepository shelf;

  @override
  State<FriendAlbumLoader> createState() => _FriendAlbumLoaderState();
}

class _FriendAlbumLoaderState extends State<FriendAlbumLoader> {
  (Shelf, Shelf)? _shelves;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final shelves = await (
        widget.shelf.loadFriend(widget.friend.id),
        widget.shelf.load(),
      ).wait;
      if (mounted) setState(() => _shelves = shelves);
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.friend.name;
    if (_shelves case (final theirs, final mine)?) {
      final entry = theirs.entries
          .where((e) => e.id == widget.entryId)
          .firstOrNull;
      if (entry != null) {
        return FriendAlbumPage(
          friend: widget.friend,
          entry: entry,
          theirs: theirs,
          mine: mine,
          shelf: widget.shelf,
        );
      }
    }
    return Scaffold(
      appBar: AppBar(),
      body: _failed
          ? Message(
              title: "Couldn't load $name's album",
              text: 'Check your connection and try again.',
              actions: [
                ShelfKey(
                  primary: true,
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              ],
            )
          : _shelves == null
          ? Semantics(
              label: "Loading $name's album",
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: context.shelf.off,
                color: context.shelf.signal,
              ),
            )
          // Removed or hidden since the feed loaded.
          : Message(title: "That album isn't on $name's shelf anymore"),
    );
  }
}
