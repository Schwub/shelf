import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/cover.dart';
import '../widgets/hidden_mark.dart';
import '../widgets/rating_meter.dart';
import '../widgets/select_mark.dart';
import '../widgets/shelf_board.dart';
import 'shelf.dart';

/// Covers in rows of three, each row standing on a teak board, with title,
/// artist and rating under the board. While [selected] is set, covers show
/// whether they are in it (TASK-40).
class CoversView extends StatelessWidget {
  const CoversView({
    super.key,
    required this.entries,
    required this.onOpen,
    this.onHold,
    this.selected,
  });

  final List<ShelfEntry> entries;
  final ValueChanged<ShelfEntry> onOpen;
  final ValueChanged<ShelfEntry>? onHold;
  final Set<String>? selected;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (var i = 0; i < entries.length; i += 3)
        entries.sublist(i, (i + 3).clamp(0, entries.length)),
    ];
    return ListView.builder(
      // Room between the filter bar's board and the first row.
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: rows.length,
      itemBuilder: (context, i) => _row(context, rows[i]),
    );
  }

  Widget _row(BuildContext context, List<ShelfEntry> row) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    Widget cells(Widget Function(ShelfEntry) cell) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: i < row.length ? cell(row[i]) : const SizedBox()),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        cells(
          (e) => GestureDetector(
            onTap: () => onOpen(e),
            onLongPress: onHold == null ? null : () => onHold!(e),
            child: SelectMark(
              selected: selected?.contains(e.id),
              child: DecoratedBox(
                // Contact shadow where the cover stands on the board.
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      offset: const Offset(0, 2),
                      blurRadius: 2,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Cover(e.album),
              ),
            ),
          ),
        ),
        const ShelfBoard(),
        const SizedBox(height: 12),
        cells(
          (e) => MergeSemantics(
            child: Semantics(
              selected: selected?.contains(e.id),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onOpen(e),
                onLongPress: onHold == null ? null : () => onHold!(e),
                child: ConstrainedBox(
                  // A full tap target even with one line of text.
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium,
                      ),
                      Text(
                        e.album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall!.copyWith(color: c.muted),
                      ),
                      if (e.hidden) const HiddenMark(),
                      const SizedBox(height: 8),
                      if (e.rating case final rating?)
                        RatingMeter(rating)
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
