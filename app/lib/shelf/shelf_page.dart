import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth.dart';
import '../auth/sign_out.dart';
import '../preview/preview_page.dart';
import '../search/album_search.dart';
import '../search/search_page.dart';
import '../theme/shelf_colors.dart';
import '../widgets/filter_bar.dart';
import '../widgets/shelf_board.dart';
import '../widgets/shelf_key.dart';
import 'covers_view.dart';
import 'entry_page.dart';
import 'shelf_data.dart';
import 'spines_view.dart';

/// The signed-in user's albums as covers or spines, with the filter bar.
class ShelfPage extends StatefulWidget {
  const ShelfPage({
    super.key,
    required this.auth,
    required this.shelf,
    required this.search,
  });

  final Auth auth;
  final ShelfRepository shelf;
  final AlbumSearch search;

  @override
  State<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends State<ShelfPage> {
  Shelf? _shelf;
  bool _failed = false;

  /// The selected filter's tag; null for All.
  String? _filterId;

  /// Covers or spines, remembered on the device.
  bool _spines = false;
  static const _spinesKey = 'shelf.spines';

  /// Removed but still undoable: hidden until the snackbar closes.
  final _removing = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
    SharedPreferences.getInstance().then((prefs) {
      final spines = prefs.getBool(_spinesKey);
      if (mounted && spines != null) setState(() => _spines = spines);
    });
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final shelf = await widget.shelf.load();
      if (!mounted) return;
      setState(() => _shelf = shelf);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Null for All, and when the filter was removed meanwhile.
  ShelfFilter? get _filter =>
      _shelf?.filters.where((f) => f.tagId == _filterId).firstOrNull;

  List<ShelfEntry> get _visible =>
      _shelf!.entries.where((e) => !_removing.contains(e.id)).toList();

  Future<void> _open(ShelfEntry entry) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute<EntryResult>(
        builder: (_) => EntryPage(entry: entry, shelf: widget.shelf),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case EntryResult.saved || EntryResult.added:
        await _load();
      case EntryResult.removed:
        _remove(entry);
      case null:
        break;
    }
  }

  Future<void> _addAlbum() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute<EntryResult>(
        builder: (_) => SearchPage(
          search: widget.search,
          shelf: widget.shelf,
          onShelf: {
            for (final e in _shelf?.entries ?? const <ShelfEntry>[])
              ?e.album.musicbrainzId: e,
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    await _load();
    if (result == EntryResult.added && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added to your shelf')));
    }
  }

  void _remove(ShelfEntry entry) {
    setState(() => _removing.add(entry.id));
    final messenger = ScaffoldMessenger.of(context);
    messenger
        .showSnackBar(
          SnackBar(
            content: const Text('Removed from your shelf'),
            action: SnackBarAction(label: 'Undo', onPressed: () {}),
            // Snackbars with an action stay open by default; the removal
            // happens when this one closes.
            persist: false,
            duration: const Duration(seconds: 5),
          ),
        )
        .closed
        .then((reason) async {
          if (reason == SnackBarClosedReason.action) {
            if (mounted) setState(() => _removing.remove(entry.id));
            return;
          }
          try {
            await widget.shelf.remove(entry.id);
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text("Couldn't remove the album.")),
            );
          }
          if (!mounted) return;
          _removing.remove(entry.id);
          await _load();
        });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final shelf = _shelf;
    final text = Theme.of(context).textTheme;
    final count = shelf == null ? null : _visible.length;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text('My shelf', style: text.headlineSmall)),
                  if (count != null)
                    Text(
                      count == 1 ? '1 album' : '$count albums',
                      style: text.labelMedium!.copyWith(color: c.muted),
                    ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) => ShelfKey(
                      semanticLabel: 'Menu',
                      padding: EdgeInsets.zero,
                      onPressed: () => _menu(context),
                      child: const Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (shelf != null && !_failed) _filterBar(shelf),
            Expanded(child: _body(context)),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _filterBar(Shelf shelf) {
    final visible = Shelf(entries: _visible, filters: shelf.filters);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FilterBar(
        filters: [
          (label: 'All', count: visible.entries.length),
          for (final f in shelf.filters)
            (label: f.label, count: visible.matching(f).length),
        ],
        selected: shelf.filters.indexWhere((f) => f.tagId == _filterId) + 1,
        onSelected: (i) => setState(
          () => _filterId = i == 0 ? null : shelf.filters[i - 1].tagId,
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final shelf = _shelf;
    if (_failed) {
      return _Message(
        title: "Couldn't load your shelf",
        text: 'Check your connection and try again.',
        action: ShelfKey(
          primary: true,
          onPressed: _load,
          child: const Text('Try again'),
        ),
      );
    }
    if (shelf == null) return const _Loading();
    final visible = Shelf(entries: _visible, filters: shelf.filters);
    final filter = _filter;
    final entries = visible.matching(filter);
    if (visible.entries.isEmpty) {
      return _Message(
        title: 'Your shelf is empty',
        text:
            'Search for an album, or share one from Spotify or Bandcamp: '
            'tap Share, then shelf.',
        action: ShelfKey(
          primary: true,
          onPressed: _addAlbum,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search),
              SizedBox(width: 8),
              Text('Search for an album'),
            ],
          ),
        ),
      );
    }
    if (entries.isEmpty) {
      return _Message(
        title: 'No albums marked ${filter!.label} yet',
        action: ShelfKey(
          onPressed: () => setState(() => _filterId = null),
          child: const Text('Show all albums'),
        ),
      );
    }
    return _spines
        ? SpinesView(entries: entries, onOpen: _open)
        : CoversView(entries: entries, onOpen: _open);
  }

  Future<void> _setSpines(bool spines) async {
    setState(() => _spines = spines);
    await (await SharedPreferences.getInstance()).setBool(_spinesKey, spines);
  }

  Widget _bottomBar(BuildContext context) {
    final c = context.shelf;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              for (final (spines, icon, label) in [
                (false, Icons.grid_view, 'Covers'),
                (true, Icons.view_week_outlined, 'Spines'),
              ]) ...[
                ShelfKey(
                  semanticLabel: label,
                  selected: _spines == spines,
                  padding: EdgeInsets.zero,
                  onPressed: () => _setSpines(spines),
                  child: Icon(icon),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ShelfKey(
                  primary: true,
                  onPressed: _addAlbum,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Add album'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context) async {
    final c = context.shelf;
    final key = context.findRenderObject()! as RenderBox;
    final corner = key.localToGlobal(key.size.bottomRight(Offset.zero));
    final style = Theme.of(context).textTheme.titleMedium;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(corner.dx, corner.dy + 4, 20, 0),
      color: c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: c.line),
      ),
      items: [
        // The component preview is for development builds only.
        if (!kReleaseMode)
          PopupMenuItem(
            value: 'components',
            height: 48,
            child: Text('Components', style: style),
          ),
        PopupMenuItem(
          value: 'sign out',
          height: 48,
          child: Text('Sign out', style: style),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'components':
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const PreviewPage()));
      case 'sign out':
        await confirmSignOut(context, widget.auth);
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.text, this.action});

  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final style = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 96, 28, 24),
      children: [
        Text(title, style: style.titleLarge, textAlign: TextAlign.center),
        if (text != null) ...[
          const SizedBox(height: 8),
          Text(
            text!,
            style: style.bodyMedium!.copyWith(color: c.muted),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 20),
          Center(child: action),
        ],
      ],
    );
  }
}

/// Placeholder covers on boards and a progress line while the shelf loads.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    Widget block(double height) => Container(
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Semantics(
      label: 'Loading your shelf',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: c.off,
            color: c.signal,
          ),
          for (var row = 0; row < 2; row++) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: AspectRatio(aspectRatio: 1, child: block(0)),
                    ),
                  ],
                ],
              ),
            ),
            const ShelfBoard(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: 0.8,
                            child: block(10),
                          ),
                          const SizedBox(height: 6),
                          FractionallySizedBox(
                            widthFactor: 0.5,
                            child: block(8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
