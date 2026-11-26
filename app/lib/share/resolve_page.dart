import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../search/album_search.dart';
import '../search/manual_album_page.dart';
import '../search/search_page.dart';
import '../shelf/entry_page.dart';
import '../shelf/shelf.dart';
import '../shelf/shelf_repository.dart';
import '../theme/shelf_colors.dart';
import '../widgets/message.dart';
import '../widgets/shelf_key.dart';
import 'link_resolver.dart';

/// "Finding album…" for a shared link, then the album to add (or the entry
/// via [ResolvePage.openEntry], when it's on the shelf already), the form to add it by hand when
/// MusicBrainz doesn't know it, or what went wrong. Pops with the
/// [EntryResult] of the screen it led to.
class ResolvePage extends StatefulWidget {
  const ResolvePage({
    super.key,
    required this.link,
    required this.resolver,
    required this.shelf,
    required this.search,
    required this.openEntry,
    this.groups = const [],
    this.onShelf = const {},
  });

  final Uri link;
  final LinkResolver resolver;
  final ShelfRepository shelf;
  final AlbumSearch search;
  final List<TagGroup> groups;

  /// The user's entries by MusicBrainz ID.
  final Map<String, ShelfEntry> onShelf;

  /// Opens an entry from the shelf, which also handles its removal.
  final void Function(ShelfEntry entry) openEntry;

  @override
  State<ResolvePage> createState() => _ResolvePageState();
}

class _ResolvePageState extends State<ResolvePage> {
  /// What to show instead of "Finding album…": a [NotAnAlbum] or an error.
  Object? _problem;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    setState(() => _problem = null);
    final Resolved resolved;
    try {
      resolved = await widget.resolver.resolve(widget.link);
    } catch (e, stack) {
      // Other sites and broken links are the user's to fix, not a fault.
      if (e is! UnsupportedLink && e is! LinkNotFound) reportError(e, stack);
      if (mounted) setState(() => _problem = e);
      return;
    }
    if (!mounted) return;
    switch (resolved) {
      case FoundAlbum(:final album):
        if (widget.onShelf[album.musicbrainzId] case final entry?) {
          Navigator.of(context).pop();
          widget.openEntry(entry);
          return;
        }
        await _open(
          EntryPage.add(
            result: album,
            shelf: widget.shelf,
            groups: widget.groups,
          ),
        );
      case UnknownAlbum():
        await _open(
          ManualAlbumPage(
            shelf: widget.shelf,
            groups: widget.groups,
            title: resolved.title,
            artist: resolved.artist,
            year: resolved.year,
            photo: resolved.cover,
          ),
        );
      case NotAnAlbum():
        setState(() => _problem = resolved);
    }
  }

  /// [page] in place of this one: going back from it leaves this too.
  Future<void> _open(Widget page) async {
    final outcome = await Navigator.of(context)
        .push(MaterialPageRoute<EntryResult>(builder: (_) => page));
    if (mounted) Navigator.of(context).pop(outcome);
  }

  void _search() => _open(
    SearchPage(
      search: widget.search,
      shelf: widget.shelf,
      groups: widget.groups,
      onShelf: widget.onShelf,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  ShelfKey(
                    semanticLabel: 'Back',
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text('Shared link', style: text.headlineSmall),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final c = context.shelf;
    final searchKey = ShelfKey(
      onPressed: _search,
      child: const Text('Search for an album'),
    );
    return switch (_problem) {
      null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: c.off,
            color: c.signal,
          ),
          Expanded(
            child: Message(
              title: 'Finding album…',
              text: widget.link.toString(),
            ),
          ),
        ],
      ),
      NotAnAlbum(:final what) => Message(
        title: switch (what) {
          'track' || 'playlist' || 'artist' => 'That’s a $what, not an album',
          _ => 'That link isn’t an album',
        },
        text: 'Share the album itself, or search for it.',
        actions: [searchKey],
      ),
      UnsupportedLink() => Message(
        title: 'shelf can’t read that link',
        text: 'Share an album from Spotify or Bandcamp, or search for it.',
        actions: [searchKey],
      ),
      LinkNotFound() => Message(
        title: 'Couldn’t find that page',
        text: 'The link may be broken. Search for the album instead.',
        actions: [searchKey],
      ),
      _ => Message(
        title: 'Couldn’t look up the link',
        text: 'Check your connection and try again.',
        actions: [
          ShelfKey(
            primary: true,
            onPressed: _resolve,
            child: const Text('Try again'),
          ),
          searchKey,
        ],
      ),
    };
  }
}
