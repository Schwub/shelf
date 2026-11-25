import 'package:material_ui/material_ui.dart';

import '../shelf/shelf_data.dart';
import '../theme/shelf_colors.dart';
import '../widgets/list_row.dart';
import '../widgets/note.dart';
import '../widgets/shelf_key.dart';
import 'tag_group_page.dart';

/// The user's tag groups in their order, built-in ones marked; opens the
/// editor of one, or a new group. Changes save as they're made.
class TagsPage extends StatefulWidget {
  const TagsPage({super.key, required this.shelf});

  final ShelfRepository shelf;

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  Shelf? _shelf;
  bool _failed = false, _reorderFailed = false;

  /// Top-level groups; sub-groups are edited from their parent tag.
  late List<TagGroup> _groups;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final shelf = await widget.shelf.load();
      if (!mounted) return;
      setState(() {
        _shelf = shelf;
        _groups = [
          for (final g in shelf.allGroups)
            if (g.parentTagId == null) g,
        ];
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) await _load();
  }

  Future<void> _reorder(int from, int to) async {
    setState(() {
      _reorderFailed = false;
      _groups.insert(to, _groups.removeAt(from));
    });
    try {
      await widget.shelf.reorderGroups([for (final g in _groups) g.id]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reorderFailed = true);
      await _load();
    }
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
                  Flexible(child: Text('Tags', style: text.headlineSmall)),
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
    final shelf = _shelf;
    if (_failed) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 96, 28, 24),
        children: [
          Text(
            'Couldn’t load your tags',
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: text.bodyMedium!.copyWith(color: c.muted),
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
    if (shelf == null) return const _Loading();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (_reorderFailed)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Note(
              child: Text(
                'Couldn’t save the new order. Check your connection and '
                'try again.',
              ),
            ),
          ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: _reorder,
          children: [
            for (final (i, g) in _groups.indexed)
              ListRow(
                key: ValueKey(g.id),
                title: g.hidden ? '${g.name} · hidden' : g.name,
                subtitle:
                    '${g.exclusive ? 'One' : 'Several'} per album · '
                    '${_count(g.tags.length, 'tag')}',
                mark: g.builtin ? 'Built-in' : null,
                dim: g.hidden,
                leading: ReorderableDragStartListener(
                  index: i,
                  child: Semantics(
                    label: 'Reorder ${g.name}',
                    child: const Icon(Icons.drag_handle),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _open(TagGroupPage(shelf: widget.shelf, groupId: g.id)),
              ),
          ],
        ),
        ListRow(
          title: 'New group',
          leading: const Icon(Icons.add, size: 16),
          onTap: () => _open(TagGroupPage.create(shelf: widget.shelf)),
        ),
        if (_groups.any((g) => g.hidden)) ...[
          const SizedBox(height: 16),
          Text(
            'Open a hidden group to show it again.',
            style: text.bodySmall!.copyWith(color: c.muted),
          ),
        ],
      ],
    );
  }
}

/// "1 tag", "34 tags".
String _count(int n, String noun) => n == 1 ? '1 $noun' : '$n ${noun}s';

/// Placeholder rows and a progress line while the tags load.
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
      label: 'Loading your tags',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: c.off,
            color: c.signal,
          ),
          for (var i = 0; i < 4; i++)
            Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(120, 12),
                  const SizedBox(height: 8),
                  block(80, 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
