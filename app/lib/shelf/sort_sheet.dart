import 'package:material_ui/material_ui.dart';

import '../widgets/help_line.dart';
import '../widgets/shelf_key.dart';
import 'shelf.dart';
import 'tag_sheet.dart';
import '../widgets/shelf_sheet.dart';

/// "Date added", "Title" …
String sortName(SortBy by) => switch (by) {
  SortBy.added => 'Date added',
  SortBy.title => 'Title',
  SortBy.artist => 'Artist',
  SortBy.year => 'Year',
  SortBy.rating => 'Rating',
};

/// "Newest first", "Z–A" …
String sortDirection(ShelfSort sort) => switch ((sort.by, sort.reversed)) {
  (SortBy.added || SortBy.year, false) => 'Newest first',
  (SortBy.added || SortBy.year, true) => 'Oldest first',
  (SortBy.title || SortBy.artist, false) => 'A–Z',
  (SortBy.title || SortBy.artist, true) => 'Z–A',
  (SortBy.rating, false) => 'Highest first',
  (SortBy.rating, true) => 'Lowest first',
};

/// The orders to pick from; the chosen one tapped again turns round. Null
/// when dismissed.
Future<ShelfSort?> showSortSheet(BuildContext context, ShelfSort current) {
  final text = Theme.of(context).textTheme;
  return showShelfSheet<ShelfSort>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sort by', style: text.titleLarge),
            const SizedBox(height: 4),
            const HelpLine('Tap the chosen order again to turn it round.'),
            const SizedBox(height: 8),
            for (final by in SortBy.values)
              TagRow(
                title: sortName(by),
                subtitle: sortDirection(
                  by == current.by ? current : ShelfSort(by),
                ),
                chosen: by == current.by,
                onTap: () => Navigator.of(context).pop(
                  by == current.by
                      ? ShelfSort(by, reversed: !current.reversed)
                      : ShelfSort(by),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The bottom bar's Sort key: says the order to screen readers, opens the
/// sheet.
class SortKey extends StatelessWidget {
  const SortKey({super.key, required this.sort, required this.onChanged});

  final ShelfSort sort;
  final ValueChanged<ShelfSort> onChanged;

  @override
  Widget build(BuildContext context) => ShelfKey(
    semanticLabel: 'Sort: ${sortName(sort.by)}, ${sortDirection(sort)}',
    padding: EdgeInsets.zero,
    onPressed: () async {
      final chosen = await showSortSheet(context, sort);
      if (chosen != null) onChanged(chosen);
    },
    child: const Icon(Icons.sort),
  );
}
