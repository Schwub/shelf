import 'package:material_ui/material_ui.dart';

import '../shelf/shelf.dart';
import '../theme/shelf_colors.dart';
import '../widgets/list_row.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';

/// Enter or edit an album's track list: add, rename, reorder and remove
/// tracks. Pops with the new list for the entry's draft (Done), or null.
class TrackEditorPage extends StatefulWidget {
  const TrackEditorPage({super.key, required this.tracks});

  final List<Track> tracks;

  @override
  State<TrackEditorPage> createState() => _TrackEditorPageState();
}

/// A track being edited; favorites and lengths stay with it.
class _Row {
  _Row(this.track, {this.added = false})
    : title = TextEditingController(text: track.title);

  Track track;
  final TextEditingController title;
  final key = UniqueKey();

  /// Just added: its field takes the focus.
  final bool added;
}

class _TrackEditorPageState extends State<TrackEditorPage> {
  late final _rows = [for (final t in widget.tracks) _Row(t)];

  @override
  void dispose() {
    for (final r in _rows) {
      r.title.dispose();
    }
    super.dispose();
  }

  void _add() {
    setState(
      () => _rows.add(
        _Row(
          Track(
            title: '',
            disc: _rows.lastOrNull?.track.disc ?? 1,
            position: 0,
          ),
          added: true,
        ),
      ),
    );
  }

  void _reorder(int from, int to) {
    setState(() {
      final row = _rows.removeAt(from);
      // A moved track joins the disc of the track above it.
      final neighbour = to > 0 ? _rows[to - 1] : _rows.firstOrNull;
      if (neighbour != null) {
        row.track = row.track.copyWith(disc: neighbour.track.disc);
      }
      _rows.insert(to, row);
    });
  }

  void _remove(_Row row) => setState(() {
    _rows.remove(row);
    row.title.dispose();
  });

  /// Numbered disc by disc, in the order shown; empty rows left out.
  List<Track> get _tracks {
    final tracks = <Track>[];
    for (final r in _rows) {
      final title = r.title.text.trim();
      if (title.isEmpty) continue;
      final previous = tracks.lastOrNull;
      final position = previous != null && previous.disc == r.track.disc
          ? previous.position + 1
          : 1;
      tracks.add(r.track.copyWith(title: title, position: position));
    }
    return tracks;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
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
                  Flexible(child: Text('Tracks', style: text.headlineSmall)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorderItem: _reorder,
                    children: [
                      for (final (i, r) in _rows.indexed)
                        Container(
                          key: r.key,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: c.bg,
                            border: Border(bottom: BorderSide(color: c.line)),
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: Semantics(
                                  label: 'Reorder track ${i + 1}',
                                  child: SizedBox.square(
                                    dimension: 44,
                                    child: Icon(
                                      Icons.drag_handle,
                                      size: 20,
                                      color: c.muted,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ShelfField(
                                  controller: r.title,
                                  autofocus: r.added,
                                  hintText: 'Track ${i + 1}',
                                  onSubmitted: (_) {
                                    if (r == _rows.last) _add();
                                  },
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: 'Remove track ${i + 1}',
                                excludeSemantics: true,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _remove(r),
                                  child: SizedBox.square(
                                    dimension: 48,
                                    child: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: c.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  ListRow(
                    title: 'Add track',
                    leading: const Icon(Icons.add, size: 16),
                    onTap: _add,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Empty tracks are left out. Drag ≡ to reorder.',
                    style: text.bodySmall!.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ShelfKey(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShelfKey(
                        primary: true,
                        onPressed: () => Navigator.of(context).pop(_tracks),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
