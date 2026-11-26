import 'package:flutter/foundation.dart';

import '../errors.dart';
import '../filters/filters_page.dart';

import 'package:material_ui/material_ui.dart';

import '../auth/auth.dart';
import '../auth/sign_out.dart';
import '../preview/preview_page.dart';
import '../search/album_search.dart';
import '../search/search_page.dart';
import '../settings/settings.dart';
import '../share/link_resolver.dart';
import '../tags/tags_page.dart';
import '../share/resolve_page.dart';
import '../share/shared_link_inbox.dart';
import '../theme/shelf_colors.dart';
import '../theme/theme_sheet.dart';
import '../widgets/filter_bar.dart';
import '../widgets/counts.dart';
import '../widgets/message.dart';
import '../widgets/shelf_board.dart';
import '../widgets/shelf_key.dart';
import 'albums_list_view.dart';
import 'bulk_tags.dart';
import 'bulk_tags_sheet.dart';
import 'covers_view.dart';
import 'entry_page.dart';
import 'selection_bar.dart';
import 'shelf.dart';
import 'shelf_repository.dart';
import 'sort_sheet.dart';

/// The signed-in user's albums as covers or a list, with the filter bar.
/// Opens links shared into the app once the shelf has loaded.
class ShelfPage extends StatefulWidget {
  const ShelfPage({
    super.key,
    required this.auth,
    required this.shelf,
    required this.search,
    required this.links,
    required this.inbox,
    required this.settings,
  });

  final Auth auth;
  final ShelfRepository shelf;
  final AlbumSearch search;
  final LinkResolver links;
  final SharedLinkInbox inbox;
  final Settings settings;

  @override
  State<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends State<ShelfPage> {
  Shelf? _shelf;
  bool _failed = false;

  /// The selected filter; null for All.
  String? _filterId;

  /// The albums selected to change together (TASK-40); null when not
  /// selecting.
  Set<String>? _selected;

  /// Removed but still undoable: hidden until the snackbar closes.
  final _removing = <String>{};

  /// A shared link's screen is open; the next link waits in the inbox.
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    widget.inbox.addListener(_openSharedLink);
    _load();
    widget.settings.list.addListener(_rebuild);
    widget.settings.sort.addListener(_rebuild);
    // Also after this page's own edits, which reload anyway: an extra
    // request, but no wiring from the other tabs.
    widget.shelf.changes.addListener(_load);
    widget.settings.sync();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final shelf = await widget.shelf.load();
      if (!mounted) return;
      setState(() => _shelf = shelf);
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
      return;
    }
    _openSharedLink();
  }

  @override
  void dispose() {
    widget.inbox.removeListener(_openSharedLink);
    widget.settings.list.removeListener(_rebuild);
    widget.settings.sort.removeListener(_rebuild);
    widget.shelf.changes.removeListener(_load);
    super.dispose();
  }

  /// The user's entries by MusicBrainz ID, to open instead of adding twice.
  Map<String, ShelfEntry> get _onShelf => {
    for (final e in _shelf?.entries ?? const <ShelfEntry>[])
      ?e.album.musicbrainzId: e,
  };

  Future<void> _openSharedLink() async {
    // Waits for the shelf, which tells which albums are on it already.
    if (_shelf == null || _resolving || !mounted) return;
    final link = widget.inbox.take();
    if (link == null) return;
    _resolving = true;
    final result = await Navigator.of(context).push(
      MaterialPageRoute<EntryResult>(
        builder: (_) => ResolvePage(
          link: link,
          resolver: widget.links,
          shelf: widget.shelf,
          search: widget.search,
          groups: _shelf?.groups ?? const [],
          onShelf: _onShelf,
          openEntry: (entry) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Already on your shelf')),
            );
            _open(entry);
          },
        ),
      ),
    );
    _resolving = false;
    if (!mounted) return;
    if (result == null) {
      _openSharedLink();
    } else {
      // Loading opens the next link.
      await _added(result);
    }
  }

  /// Null for All, and when the filter was removed meanwhile.
  ShelfFilter? get _filter =>
      _shelf?.filters.where((f) => f.id == _filterId).firstOrNull;

  List<ShelfEntry> get _visible =>
      _shelf!.entries.where((e) => !_removing.contains(e.id)).toList();

  /// Opens the album, or while selecting, adds it to the selection or
  /// takes it out.
  Future<void> _open(ShelfEntry entry) async {
    if (_selected case final selected?) {
      setState(
        () => selected.contains(entry.id)
            ? selected.remove(entry.id)
            : selected.add(entry.id),
      );
      return;
    }
    final result = await Navigator.of(context).push(
      MaterialPageRoute<EntryResult>(
        builder: (_) => EntryPage(
          entry: entry,
          shelf: widget.shelf,
          groups: _shelf?.groups ?? const [],
        ),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case EntryResult.saved || EntryResult.added:
        await _load();
      case EntryResult.removed:
        _remove([entry]);
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
          groups: _shelf?.groups ?? const [],
          onShelf: _onShelf,
        ),
      ),
    );
    if (mounted && result != null) await _added(result);
  }

  /// Reloads after a search or shared link led to [result].
  Future<void> _added(EntryResult result) async {
    await _load();
    if (result == EntryResult.added && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added to your shelf')));
    }
  }

  void _remove(List<ShelfEntry> entries) {
    final ids = [for (final e in entries) e.id];
    setState(() => _removing.addAll(ids));
    final messenger = ScaffoldMessenger.of(context);
    messenger
        .showSnackBar(
          SnackBar(
            content: Text(
              ids.length == 1
                  ? 'Removed from your shelf'
                  : '${albumCount(ids.length)} removed',
            ),
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
            if (mounted) setState(() => _removing.removeAll(ids));
            return;
          }
          try {
            await widget.shelf.remove(ids);
          } catch (e, stack) {
            reportError(e, stack);
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  ids.length == 1
                      ? "Couldn't remove the album."
                      : "Couldn't remove the albums.",
                ),
              ),
            );
          }
          if (!mounted) return;
          _removing.removeAll(ids);
          await _load();
        });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final shelf = _shelf;
    final text = Theme.of(context).textTheme;
    final count = shelf == null ? null : _visible.length;
    return PopScope(
      // Back ends selecting first.
      canPop: _selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selected = null);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selected case final selected? when shelf != null)
                SelectionHeader(
                  count: _chosen.length,
                  all: _inFilter.every((e) => selected.contains(e.id)),
                  onDone: () => setState(() => _selected = null),
                  onAll: (all) => setState(() {
                    final ids = [for (final e in _inFilter) e.id];
                    all ? selected.addAll(ids) : selected.removeAll(ids);
                  }),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('My shelf', style: text.headlineSmall),
                      ),
                      if (count != null)
                        Text(
                          albumCount(count),
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
              if (_selected != null && shelf != null)
                SelectionBar(
                  count: _chosen.length,
                  allHidden:
                      _chosen.isNotEmpty && _chosen.every((e) => e.hidden),
                  onTags: _changeTags,
                  onHide: _hideChosen,
                  onRemove: () {
                    _remove(_chosen);
                    setState(() => _selected = null);
                  },
                )
              else
                _bottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  /// The selected albums shown in the current filter: only those are
  /// changed; others stay selected for when their filter is back.
  List<ShelfEntry> get _chosen => [
    for (final e in _inFilter)
      if (_selected?.contains(e.id) ?? false) e,
  ];

  List<ShelfEntry> get _inFilter => Shelf(entries: _visible).matching(_filter);

  /// The tags sheet for the selection, then the changes on all of it.
  Future<void> _changeTags() async {
    final chosen = _chosen;
    final changes = await showBulkTagsSheet(
      context,
      tags: BulkTags(_shelf!.groups, chosen),
      onCreate: (group, name) => widget.shelf.createTag(group.id, name),
    );
    if (changes == null || !mounted) return;
    final (:remove, :add) = changes.changes;
    await _changeAll(
      chosen,
      () => widget.shelf.changeTags(
        [for (final e in chosen) e.id],
        remove: remove,
        add: add,
      ),
      done: 'Tags changed on ${albumCount(chosen.length)}',
    );
  }

  /// Hides the selection from friends, or shows it when all of it is
  /// hidden; Undo turns back only the albums that changed.
  Future<void> _hideChosen() async {
    final hide = !_chosen.every((e) => e.hidden);
    final changed = [
      for (final e in _chosen)
        if (e.hidden != hide) e,
    ];
    final ids = [for (final e in changed) e.id];
    await _changeAll(
      changed,
      () => widget.shelf.hide(ids, hide),
      done:
          '${albumCount(changed.length)} ${hide ? 'hidden from' : 'shown to'} '
          'friends',
      undo: () => widget.shelf.hide(ids, !hide),
    );
  }

  /// Runs [change] on [entries], then says so ([undo] offers to turn it
  /// back), or that it failed, with Try again. The selection stays.
  Future<void> _changeAll(
    List<ShelfEntry> entries,
    Future<void> Function() change, {
    required String done,
    Future<void> Function()? undo,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await change();
    } catch (e, stack) {
      reportError(e, stack);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't change ${albumCount(entries.length)}. "
            'Check your connection.',
          ),
          action: SnackBarAction(
            label: 'Try again',
            onPressed: () =>
                _changeAll(entries, change, done: done, undo: undo),
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(done),
        action: undo == null
            ? null
            : SnackBarAction(
                label: 'Undo',
                onPressed: () => _changeAll(entries, undo, done: 'Undone'),
              ),
        persist: false,
      ),
    );
  }

  Widget _filterBar(Shelf shelf) {
    final visible = Shelf(entries: _visible, allFilters: shelf.filters);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FilterBar(
        filters: [
          (label: 'All', count: visible.entries.length),
          for (final f in shelf.filters)
            (label: f.label, count: visible.matching(f).length),
        ],
        selected: shelf.filters.indexWhere((f) => f.id == _filterId) + 1,
        onSelected: (i) =>
            setState(() => _filterId = i == 0 ? null : shelf.filters[i - 1].id),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final shelf = _shelf;
    if (_failed) {
      return Message(
        title: "Couldn't load your shelf",
        text: 'Check your connection and try again.',
        actions: [
          ShelfKey(
            primary: true,
            onPressed: _load,
            child: const Text('Try again'),
          ),
        ],
      );
    }
    if (shelf == null) return const _Loading();
    final visible = Shelf(entries: _visible, allFilters: shelf.filters);
    final filter = _filter;
    final entries = widget.settings.sort.value.apply(visible.matching(filter));
    if (visible.entries.isEmpty) {
      return Message(
        title: 'Your shelf is empty',
        text:
            'Search for an album, or share one from Spotify or Bandcamp: '
            'tap Share, then shelf.',
        actions: [
          ShelfKey(
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
        ],
      );
    }
    if (entries.isEmpty) {
      return Message(
        title: 'No albums marked ${filter!.label} yet',
        actions: [
          ShelfKey(
            onPressed: () => setState(() => _filterId = null),
            child: const Text('Show all albums'),
          ),
        ],
      );
    }
    // Press and hold starts selecting with that album.
    void hold(ShelfEntry e) => setState(() => (_selected ??= {}).add(e.id));
    return _list
        ? AlbumsListView(
            entries: entries,
            onOpen: _open,
            onHold: hold,
            selected: _selected,
          )
        : CoversView(
            entries: entries,
            onOpen: _open,
            onHold: hold,
            selected: _selected,
          );
  }

  /// Covers or a list.
  bool get _list => widget.settings.list.value;

  void _rebuild() => setState(() {});

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
              for (final (list, icon, label) in [
                (false, Icons.grid_view, 'Covers'),
                (true, Icons.view_list_outlined, 'List'),
              ]) ...[
                ShelfKey(
                  semanticLabel: label,
                  selected: _list == list,
                  padding: EdgeInsets.zero,
                  onPressed: () => widget.settings.chooseList(list),
                  child: Icon(icon),
                ),
                const SizedBox(width: 8),
              ],
              SortKey(
                sort: widget.settings.sort.value,
                onChanged: widget.settings.chooseSort,
              ),
              const SizedBox(width: 8),
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
          value: 'select',
          height: 48,
          child: Text('Select albums', style: style),
        ),
        PopupMenuItem(
          value: 'tags',
          height: 48,
          child: Text('Tags', style: style),
        ),
        PopupMenuItem(
          value: 'filters',
          height: 48,
          child: Text('Filters', style: style),
        ),
        PopupMenuItem(
          value: 'theme',
          height: 48,
          child: Text('Theme', style: style),
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
      case 'select':
        setState(() => _selected = {});
      case 'tags':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TagsPage(shelf: widget.shelf),
          ),
        );
        // Names, filters and hidden groups may have changed.
        await _load();
      case 'filters':
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FiltersPage(shelf: widget.shelf),
          ),
        );
        await _load();
      case 'theme':
        await showThemeSheet(context, widget.settings);
      case 'sign out':
        await confirmSignOut(context, widget.auth);
    }
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
