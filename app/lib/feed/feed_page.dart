import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../friends/friend_album_loader.dart';
import '../friends/friends_repository.dart';
import '../shelf/shelf_repository.dart';
import '../theme/shelf_colors.dart';
import '../widgets/cover.dart';
import '../widgets/message.dart';
import '../widgets/rating_keys.dart';
import '../widgets/rating_meter.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';
import 'feed_repository.dart';

/// What friends added and rated, newest first; more load at the end, pull
/// to refresh. Each item opens the friend's album.
class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.feed,
    required this.friends,
    required this.shelf,
  });

  final FeedRepository feed;
  final FriendsRepository friends;
  final ShelfRepository shelf;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<FeedItem>? _items;

  /// Friends' names, for the empty states: none yet means no friends.
  List<String>? _friendNames;
  bool _failed = false;
  bool _more = true, _loadingMore = false, _moreFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final items = await widget.feed.page();
      final names = items.isEmpty
          ? [for (final f in (await widget.friends.load()).friends) f.name]
          : null;
      if (!mounted) return;
      setState(() {
        _items = items;
        _friendNames = names;
        _more = items.length == FeedRepository.pageSize;
        _moreFailed = false;
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _loadMore() async {
    final items = _items;
    if (items == null || !_more || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    try {
      final next = await widget.feed.page(after: items.last);
      if (!mounted) return;
      setState(() {
        _items = [...items, ...next];
        _more = next.length == FeedRepository.pageSize;
        _loadingMore = false;
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _moreFailed = true;
      });
    }
  }

  void _open(FeedItem item) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FriendAlbumLoader(
        friend: (id: item.friendId, name: item.friendName, albums: 0),
        entryId: item.entryId,
        shelf: widget.shelf,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final Widget body;
    if (_failed) {
      body = Message(
        title: "Couldn't load the feed",
        text: 'Check your connection and try again.',
        actions: [
          ShelfKey(
            primary: true,
            onPressed: _load,
            child: const Text('Try again'),
          ),
        ],
      );
    } else if (items == null) {
      body = Semantics(
        label: 'Loading the feed',
        child: LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: context.shelf.off,
          color: context.shelf.signal,
        ),
      );
    } else if (items.isEmpty) {
      final names = _friendNames ?? const [];
      // A list, so pull to refresh works on the empty states too.
      body = RefreshIndicator(
        onRefresh: _load,
        child: names.isEmpty
            ? const Message(
                title: 'See what friends add and rate',
                text:
                    'Invite a friend under Friends, and their albums show '
                    'up here.',
              )
            : Message(
                title: 'Nothing yet',
                text:
                    'When ${_join(names)} add or rate albums, they show here.',
              ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // After a failure only Try again loads more, not every scroll.
            if (n.metrics.extentAfter < 400 && !_moreFailed) _loadMore();
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length + (_more || _moreFailed ? 1 : 0),
            itemBuilder: (context, i) => i < items.length
                ? _Item(items[i], onOpen: () => _open(items[i]))
                : _end(),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: body,
    );
  }

  /// The last row: loading more, or why it couldn't.
  Widget _end() {
    final c = context.shelf;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _moreFailed
          ? Column(
              children: [
                Text("Couldn't load more", style: TextStyle(color: c.muted)),
                TextLink(label: 'Try again', onPressed: _loadMore),
              ],
            )
          : Semantics(
              label: 'Loading more',
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: c.off,
                color: c.signal,
              ),
            ),
    );
  }
}

/// Anna; Anna or Ben; Anna, Ben or Carol.
String _join(List<String> names) => names.length == 1
    ? names.single
    : '${names.sublist(0, names.length - 1).join(', ')} or ${names.last}';

class _Item extends StatelessWidget {
  const _Item(this.item, {required this.onOpen});

  final FeedItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final verb = item.kind == FeedKind.added ? 'added' : 'rated';
    final bold = text.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    return MergeSemantics(
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              SizedBox(width: 56, child: Cover(item.album)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: item.friendName, style: bold),
                          TextSpan(text: ' $verb '),
                          TextSpan(text: item.album.title, style: bold),
                        ],
                      ),
                      style: text.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.album.artist,
                      style: text.bodySmall!.copyWith(color: c.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.rating case final rating?) ...[
                      const SizedBox(height: 6),
                      Semantics(
                        label: RatingKeys.describe(rating),
                        excludeSemantics: true,
                        child: RatingMeter(rating),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      ago(item.at, DateTime.now()),
                      style: text.bodySmall!.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// How long ago [at] was, for a feed item: "just now", "5 min", "2 h",
/// "yesterday", "3 days ago", then the date.
String ago(DateTime at, DateTime now) {
  final local = at.toLocal();
  final since = now.difference(local);
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (since.inMinutes < 1) return 'just now';
  if (since.inHours < 1) return '${since.inMinutes} min';
  if (days == 0) return '${since.inHours} h';
  if (days == 1) return 'yesterday';
  if (days < 7) return '$days days ago';
  final date = '${local.day} ${_months[local.month - 1]}';
  return local.year == now.year ? date : '$date ${local.year}';
}
