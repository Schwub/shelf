import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../shelf/albums_list_view.dart';
import '../shelf/covers_view.dart';
import '../settings/settings.dart';
import '../shelf/shelf.dart';
import '../shelf/shelf_repository.dart';
import '../shelf/sort_sheet.dart';
import '../theme/shelf_colors.dart';
import '../widgets/filter_bar.dart';
import '../widgets/message.dart';
import '../widgets/shelf_key.dart';
import 'friend_album_page.dart';
import 'friends_repository.dart';

/// A friend's albums, read-only: covers or a list in the user's own order
/// (sorted here too), with their filters. Loads the user's own shelf too, to tell which albums are
/// on it.
class FriendShelfPage extends StatefulWidget {
  const FriendShelfPage({
    super.key,
    required this.friend,
    required this.shelf,
    required this.settings,
  });

  final Friend friend;
  final ShelfRepository shelf;
  final Settings settings;

  @override
  State<FriendShelfPage> createState() => _FriendShelfPageState();
}

class _FriendShelfPageState extends State<FriendShelfPage> {
  Shelf? _theirs, _mine;
  bool _failed = false;
  bool _list = false;
  String? _filterId;

  @override
  void initState() {
    super.initState();
    _load();
    widget.shelf.changes.addListener(_load);
    widget.settings.sort.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.shelf.changes.removeListener(_load);
    widget.settings.sort.removeListener(_rebuild);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final (theirs, mine) = await (
        widget.shelf.loadFriend(widget.friend.id),
        widget.shelf.load(),
      ).wait;
      if (mounted) {
        setState(() {
          _theirs = theirs;
          _mine = mine;
        });
      }
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
    }
  }

  void _open(ShelfEntry entry) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FriendAlbumPage(
        friend: widget.friend,
        entry: entry,
        theirs: _theirs!,
        mine: _mine!,
        shelf: widget.shelf,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final name = widget.friend.name;
    final theirs = _theirs;
    final Widget body;
    if (_failed) {
      body = Message(
        title: "Couldn't load $name's shelf",
        text: 'Check your connection and try again.',
        actions: [
          ShelfKey(
            primary: true,
            onPressed: _load,
            child: const Text('Try again'),
          ),
        ],
      );
    } else if (theirs == null) {
      body = Semantics(
        label: "Loading $name's shelf",
        child: LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: context.shelf.off,
          color: context.shelf.signal,
        ),
      );
    } else if (theirs.entries.isEmpty) {
      body = Message(
        title: "$name hasn't added any albums yet",
        text: 'When they do, the albums show here.',
      );
    } else {
      final filter = theirs.filters.where((f) => f.id == _filterId).firstOrNull;
      final entries = widget.settings.sort.value.apply(theirs.matching(filter));
      body = Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilterBar(
              filters: [
                (label: 'All', count: theirs.entries.length),
                for (final f in theirs.filters)
                  (label: f.label, count: theirs.matching(f).length),
              ],
              selected: filter == null ? 0 : theirs.filters.indexOf(filter) + 1,
              onSelected: (i) => setState(
                () => _filterId = i == 0 ? null : theirs.filters[i - 1].id,
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Message(title: 'No albums marked ${filter!.label} yet')
                : _list
                ? AlbumsListView(entries: entries, onOpen: _open)
                : CoversView(entries: entries, onOpen: _open),
          ),
          _viewKeys(),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: body,
    );
  }

  Widget _viewKeys() {
    final c = context.shelf;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            for (final (list, icon, label) in [
              (false, Icons.grid_view, 'Covers'),
              (true, Icons.view_list_outlined, 'List'),
            ]) ...[
              ShelfKey(
                semanticLabel: label,
                selected: _list == list,
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _list = list),
                child: Icon(icon),
              ),
              const SizedBox(width: 8),
            ],
            SortKey(
              sort: widget.settings.sort.value,
              onChanged: widget.settings.chooseSort,
            ),
          ],
        ),
      ),
    );
  }
}
