import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/cover.dart';
import '../widgets/dates.dart';
import '../widgets/hidden_mark.dart';
import '../widgets/rating_meter.dart';
import '../widgets/select_mark.dart';
import 'shelf.dart';

/// The shelf as a list: one row per album with a small cover, title, artist
/// and rating; tapping a row opens the album. While [selected] is set, rows
/// show whether they are in it (TASK-40).
class AlbumsListView extends StatelessWidget {
  const AlbumsListView({
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
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return Semantics(
          selected: selected?.contains(e.id),
          child: InkWell(
            onTap: () => onOpen(e),
            onLongPress: onHold == null ? null : () => onHold!(e),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: SelectMark(
                      selected: selected?.contains(e.id),
                      child: Cover(e.album),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.album.title,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.album.artist,
                          style: text.bodySmall!.copyWith(color: c.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Added ${formatDay(e.addedAt)}',
                          style: text.bodySmall!.copyWith(color: c.muted),
                        ),
                        if (e.hidden) const HiddenMark(),
                        if (e.rating case final rating?) ...[
                          const SizedBox(height: 8),
                          RatingMeter(rating),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
