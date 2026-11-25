import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../shelf/shelf_data.dart';
import '../theme/shelf_colors.dart';
import '../widgets/list_row.dart';
import '../widgets/note.dart';
import '../widgets/shelf_key.dart';
import 'filter_editor_page.dart';
import 'tag_picker.dart';

/// The filter bar's filters, All first, in their order: reorder, remove,
/// add one for a tag or a custom one (docs/features/filters.md). Changes
/// save as they're made.
class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key, required this.shelf});

  final ShelfRepository shelf;

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  Shelf? _shelf;
  List<ShelfFilter> _filters = [];
  bool _loadFailed = false, _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    try {
      final shelf = await widget.shelf.load();
      if (!mounted) return;
      setState(() {
        _shelf = shelf;
        _filters = [...shelf.allFilters];
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  /// Saves [change], then shows the filters as they are now.
  Future<void> _save(Future<void> Function() change) async {
    setState(() => _saveFailed = false);
    try {
      await change();
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _saveFailed = true);
    }
    if (mounted) await _load();
  }

  void _reorder(int from, int to) {
    setState(() => _filters.insert(to, _filters.removeAt(from)));
    _save(() => widget.shelf.reorderFilters([for (final f in _filters) f.id]));
  }

  Future<void> _add() async {
    final shelf = _shelf!;
    final tagFilters = {
      for (final f in _filters)
        if (f.isTag) f.tagIds.single,
    };
    var custom = false;
    final picked = await showTagPicker(
      context,
      title: 'Add filter',
      groups: shelf.groups,
      chosen: tagFilters,
      extra: Builder(
        builder: (context) => ListRow(
          title: 'Custom filter…',
          subtitle: 'Combine tags, rating and favorite tracks',
          leading: const Icon(Icons.tune),
          onTap: () {
            custom = true;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (!mounted) return;
    if (custom) return _edit(null);
    final tag = picked?.single;
    if (tag == null || tagFilters.contains(tag)) return;
    await _save(() => widget.shelf.saveFilter(ShelfFilter(tagIds: [tag])));
  }

  Future<void> _edit(ShelfFilter? filter) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FilterEditorPage(
          repository: widget.shelf,
          shelf: _shelf!,
          filter: filter,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  ShelfKey(
                    semanticLabel: 'Back',
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: Text('Filters', style: text.headlineSmall)),
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
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium!.copyWith(color: c.muted);
    if (_loadFailed) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 96, 28, 24),
        children: [
          Text(
            'Couldn’t load your filters',
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: muted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: ShelfKey(
              primary: true,
              onPressed: _load,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }
    final shelf = _shelf;
    if (shelf == null) {
      return Column(
        children: [
          LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: c.off,
            color: c.signal,
            semanticsLabel: 'Loading your filters',
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (_saveFailed)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Note(
              child: Text(
                'Couldn’t save the change. Check your connection and try '
                'again.',
              ),
            ),
          ),
        const ListRow(title: 'All', subtitle: 'Always first', dim: true),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: _reorder,
          children: [
            for (final (i, f) in _filters.indexed)
              ListRow(
                key: ValueKey(f.id),
                title: f.label,
                subtitle: describeFilter(f, shelf),
                leading: ReorderableDragStartListener(
                  index: i,
                  child: Semantics(
                    label: 'Reorder ${f.label}',
                    child: const Icon(Icons.drag_handle),
                  ),
                ),
                trailing: Semantics(
                  button: true,
                  label: 'Remove ${f.label}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _save(() => widget.shelf.deleteFilter(f.id)),
                    child: const SizedBox.expand(child: Icon(Icons.close)),
                  ),
                ),
                onTap: () => _edit(f),
              ),
          ],
        ),
        ListRow(
          title: 'Add filter',
          leading: const Icon(Icons.add, size: 16),
          onTap: _add,
        ),
        const SizedBox(height: 16),
        Text(
          _filters.isEmpty
              ? 'Add filters to find albums on your shelf quickly.'
              : 'Changes are saved as you make them.',
          style: text.bodySmall!.copyWith(color: c.muted),
        ),
      ],
    );
  }
}

/// What a filter matches, in a line: "Collection" for a tag's filter,
/// "Own and Vinyl · 4 stars and up · favorite tracks" for a custom one.
String describeFilter(ShelfFilter f, Shelf shelf) {
  final groupOf = {
    for (final g in shelf.allGroups)
      for (final t in g.tags) t.id: g,
  };
  final names = {
    for (final g in shelf.allGroups)
      for (final t in g.tags) t.id: t.name,
  };
  if (f.isTag) return groupOf[f.tagIds.single]?.name ?? '';
  final tags = [for (final id in f.tagIds) names[id] ?? '?'];
  return [
    if (tags.isNotEmpty)
      tags.length == 1
          ? tags.single
          : '${tags.take(tags.length - 1).join(', ')} '
                '${f.matchAll ? 'and' : 'or'} ${tags.last}',
    if (f.minRating case final r?) '${_stars(r)} and up',
    if (f.unrated) 'unrated',
    if (f.favoriteTracks) 'favorite tracks',
  ].join(' · ');
}

String _stars(int halfStars) {
  final stars = halfStars.isEven ? '${halfStars ~/ 2}' : '${halfStars / 2}';
  return stars == '1' ? '1 star' : '$stars stars';
}
