import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../theme/shelf_theme.dart';
import '../widgets/filter_bar.dart';
import '../widgets/rating_keys.dart';
import '../widgets/shelf_board.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';

/// Every component in both themes (development builds: ⋮ → Components).
class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
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
                  Text(
                    'Components',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            for (final theme in AppTheme.values)
              Theme(
                data: shelfTheme(theme.colors),
                child: _Components(title: theme.label),
              ),
          ],
        ),
      ),
    );
  }
}

class _Components extends StatefulWidget {
  const _Components({required this.title});

  final String title;

  @override
  State<_Components> createState() => _ComponentsState();
}

class _ComponentsState extends State<_Components> {
  String? _collection = 'Own';
  final _formats = {'Vinyl'};
  int _filter = 1;
  int _moreFilter = 0;
  int? _rating = 7;

  static const _filters = [
    (label: 'All', count: 128),
    (label: 'Own', count: 54),
    (label: 'Want', count: 17),
    (label: 'Want to listen', count: 23),
    (label: 'Listened', count: 96),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(s, style: text.labelSmall!.copyWith(color: c.muted)),
    );
    return ColoredBox(
      color: c.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: text.headlineSmall),
            label('Keys'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ShelfKey(onPressed: () {}, child: const Text('Cancel')),
                ShelfKey(
                  primary: true,
                  onPressed: () {},
                  child: const Text('Save'),
                ),
                ShelfKey(
                  semanticLabel: 'Close',
                  padding: EdgeInsets.zero,
                  onPressed: () {},
                  child: const Icon(Icons.close),
                ),
                const ShelfKey(child: Text('Disabled')),
              ],
            ),
            label('Collection'),
            Row(
              children: [
                for (final (i, tag) in ['Want', 'Own'].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: ShelfKey(
                      light: true,
                      selected: _collection == tag,
                      onPressed: () => setState(
                        () => _collection = _collection == tag ? null : tag,
                      ),
                      child: Text(tag),
                    ),
                  ),
                ],
              ],
            ),
            label('Format'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final format in ['Vinyl', 'CD', 'Tape', 'File'])
                  ShelfKey(
                    light: true,
                    selected: _formats.contains(format),
                    onPressed: () => setState(
                      () => _formats.contains(format)
                          ? _formats.remove(format)
                          : _formats.add(format),
                    ),
                    child: Text(format),
                  ),
              ],
            ),
            label('Rating'),
            RatingKeys(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            label('Filter bar'),
            FilterBar(
              filters: _filters,
              selected: _filter,
              onSelected: (i) => setState(() => _filter = i),
            ),
            label('Filter bar with more than five'),
            FilterBar(
              filters: [
                ..._filters,
                (label: 'Vinyl', count: 31),
                (label: 'Jazz', count: 12),
              ],
              selected: _moreFilter,
              onSelected: (i) => setState(() => _moreFilter = i),
            ),
            label('Shelf board'),
            Row(
              children: [
                for (final (i, colors) in const [
                  [Color(0xFF9FB7C9), Color(0xFF5D7D95)],
                  [Color(0xFFF1D35A), Color(0xFFC0392B)],
                  [Color(0xFF777777), Color(0xFF222222)],
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const ShelfBoard(),
            label('Fields'),
            const ShelfField(hintText: 'Album or artist', icon: Icons.search),
            const SizedBox(height: 12),
            const ShelfField(
              hintText: 'Comment (optional)',
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
      ),
    );
  }
}
