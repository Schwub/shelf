import 'dart:async';

import '../errors.dart';

import 'package:material_ui/material_ui.dart';

import '../shelf/entry_page.dart';
import '../shelf/shelf.dart';
import '../shelf/shelf_repository.dart';
import '../theme/shelf_colors.dart';
import '../widgets/shelf_key.dart';
import 'album_search.dart';
import 'manual_album_page.dart';

/// Find an album on MusicBrainz and open it to add it (or, when it's on the
/// shelf already, to edit it). Pops with [EntryResult.added] after adding.
class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.search,
    required this.shelf,
    required this.onShelf,
    this.groups = const [],
  });

  final AlbumSearch search;
  final ShelfRepository shelf;

  /// The user's entries by MusicBrainz ID, to mark and edit them.
  final Map<String, ShelfEntry> onShelf;

  /// The user's tag groups, for the album entry.
  final List<TagGroup> groups;

  /// Searching starts this long after typing stops.
  /// Typing pause before a search, so MusicBrainz isn't asked for every
  /// few letters.
  static const pause = Duration(milliseconds: 500);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  Timer? _timer;
  String _searched = '';
  List<SearchResult>? _results;
  bool _loading = false, _failed = false;

  /// The newest search is waiting for its answer.
  bool _running = false;

  /// Answers to older queries that arrive late are dropped.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _query.addListener(_typed);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _typed() {
    final text = _query.text.trim();
    if (text == _searched) {
      // Typed back to what's shown (or still being searched).
      _timer?.cancel();
      if (!_running && _loading) setState(() => _loading = false);
      return;
    }
    _timer?.cancel();
    if (text.isEmpty) {
      setState(() {
        _searched = '';
        _results = null;
        _loading = _failed = false;
      });
      return;
    }
    // Searching shows from the first letter, through the pause.
    setState(() {
      _loading = true;
      _failed = false;
    });
    _timer = Timer(SearchPage.pause, () => _run(text));
  }

  Future<void> _run(String text) async {
    final request = ++_request;
    setState(() {
      _searched = text;
      _loading = _running = true;
      _failed = false;
    });
    try {
      final results = await widget.search.search(text);
      if (!mounted || request != _request) return;
      setState(() {
        _results = results;
        _loading = _running = false;
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (!mounted || request != _request) return;
      setState(() {
        _loading = _running = false;
        _failed = true;
      });
    }
  }

  Future<void> _addYourself() async {
    final outcome = await Navigator.of(context).push(
      MaterialPageRoute<EntryResult>(
        builder: (_) => ManualAlbumPage(
          shelf: widget.shelf,
          groups: widget.groups,
          title: _searched,
        ),
      ),
    );
    if (outcome != null && mounted) Navigator.of(context).pop(outcome);
  }

  Future<void> _open(SearchResult result) async {
    final entry = widget.onShelf[result.musicbrainzId];
    final outcome = await Navigator.of(context).push(
      MaterialPageRoute<EntryResult>(
        builder: (_) => entry != null
            ? EntryPage(
                entry: entry,
                shelf: widget.shelf,
                groups: widget.groups,
              )
            : EntryPage.add(
                result: result,
                shelf: widget.shelf,
                groups: widget.groups,
              ),
      ),
    );
    if (outcome != null && mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  ShelfKey(
                    semanticLabel: 'Back',
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _field(context)),
                ],
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _field(BuildContext context) {
    final c = context.shelf;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: _query,
      autofocus: true,
      textInputAction: TextInputAction.search,
      onSubmitted: (text) {
        _timer?.cancel();
        if (text.trim().isNotEmpty) _run(text.trim());
      },
      style: Theme.of(context).textTheme.bodyMedium,
      cursorColor: c.signal,
      decoration: InputDecoration(
        hintText: 'Album or artist',
        hintStyle: TextStyle(color: c.muted),
        filled: true,
        fillColor: c.surface,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.all(14),
        prefixIcon: Icon(Icons.search, size: 18, color: c.muted),
        suffixIcon: _loading
            ? Padding(
                padding: const EdgeInsets.all(15),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.signal,
                  semanticsLabel: 'Searching',
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          maxHeight: 48,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        border: border(c.line),
        enabledBorder: border(c.line),
        focusedBorder: border(c.signal),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium!.copyWith(color: c.muted);
    Widget message(List<Widget> lines) => ListView(
      padding: const EdgeInsets.fromLTRB(28, 120, 28, 24),
      children: lines,
    );
    if (_failed) {
      return message([
        Text(
          "Couldn't search",
          style: text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Check your connection.',
          style: muted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: ShelfKey(
            primary: true,
            onPressed: () => _run(_searched),
            child: const Text('Try again'),
          ),
        ),
        // MusicBrainz can be busy for a while; adding stays possible.
        const SizedBox(height: 8),
        Center(
          child: ShelfKey(
            onPressed: _addYourself,
            child: const Text('Add it yourself'),
          ),
        ),
      ]);
    }
    if (_loading) return const _Loading();
    final results = _results;
    if (results == null) {
      return message([
        Text(
          'Search by album title or artist.',
          style: muted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Or share an album from Spotify or Bandcamp to add it directly.',
          style: muted,
          textAlign: TextAlign.center,
        ),
      ]);
    }
    if (results.isEmpty) {
      return message([
        Text.rich(
          TextSpan(
            text: 'No albums found for ',
            children: [
              TextSpan(
                text: '“$_searched”',
                style: TextStyle(
                  color: c.text,
                  fontVariations: const [FontVariation.weight(600)],
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          style: muted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "Check the spelling, or try the artist's name.",
          style: muted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: ShelfKey(
            onPressed: _addYourself,
            child: const Text('Add it yourself'),
          ),
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: results.length + 1,
      itemBuilder: (context, i) => i == results.length
          ? Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(child: Text('Not the right one?', style: muted)),
                  ShelfKey(
                    onPressed: _addYourself,
                    child: const Text('Add it yourself'),
                  ),
                ],
              ),
            )
          : _Result(
              result: results[i],
              onShelf: widget.onShelf.containsKey(results[i].musicbrainzId),
              onTap: () => _open(results[i]),
            ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.result,
    required this.onShelf,
    required this.onTap,
  });

  final SearchResult result;
  final bool onShelf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final blank = ColoredBox(color: c.surface);
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox.square(
                  dimension: 56,
                  child: Image.network(
                    result.thumbnailUrl,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : blank,
                    errorBuilder: (context, error, stack) => blank,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    Text(
                      [
                        result.artist,
                        if (result.year != null) '${result.year}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall!.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              if (onShelf) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.signal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'On your shelf',
                  style: text.labelSmall!.copyWith(color: c.signal),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder rows and a progress line while searching.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Semantics(
      label: 'Searching',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: c.off,
            color: c.signal,
          ),
          for (var i = 0; i < 5; i++)
            Container(
              height: 72,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  block(56, 56),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(160, 10),
                      const SizedBox(height: 8),
                      block(100, 8),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
