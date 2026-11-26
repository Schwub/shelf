import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../theme/shelf_theme.dart';
import 'shelf_board.dart';
import 'shelf_key.dart';

typedef Filter = ({String label, int count});

/// The shelf's filter bar: labels printed above equal keys that show a count,
/// above a teak board. Up to five fill the width; with more, the keys
/// keep the width of five and the row scrolls, fading out at the end.
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<Filter> filters;
  final int selected;
  final ValueChanged<int> onSelected;

  static const gap = 6.0;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final perRow = filters.length.clamp(1, 5);
            final width = (constraints.maxWidth - (perRow - 1) * gap) / perRow;
            final row = Row(
              children: [
                for (final (i, f) in filters.indexed) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(width: width, child: _filter(c, i, f)),
                ],
              ],
            );
            if (filters.length <= 5) return row;
            return ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                stops: [0, (rect.width - 32) / rect.width, 1],
                colors: const [
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
              ).createShader(rect),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // Room for the last key's shadow.
                padding: const EdgeInsets.only(right: 32),
                child: row,
              ),
            );
          },
        ),
        // A little air between the keys and their board (asked for
        // 2026-11-26; they used to stand on it).
        const Padding(padding: EdgeInsets.only(top: 4), child: ShelfBoard()),
      ],
    );
  }

  Widget _filter(ShelfColors c, int i, Filter f) {
    return Semantics(
      label: '${f.label}, ${f.count}',
      excludeSemantics: true,
      selected: i == selected,
      button: true,
      onTap: () => onSelected(i),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            f.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: archivo(12).copyWith(color: c.muted),
          ),
          const SizedBox(height: 4),
          ShelfKey(
            selected: i == selected,
            light: true,
            padding: const EdgeInsets.only(left: 12, right: 2),
            onPressed: () => onSelected(i),
            child: Text('${f.count}'),
          ),
        ],
      ),
    );
  }
}
