import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import 'shelf_key.dart';

/// Five rating keys, each a bar of the rating meter. [value] is in half
/// stars (1–10, as stored), null for no rating.
///
/// Tapping a key sets that many stars, tapping it again makes it a half,
/// a third time clears the rating.
class RatingKeys extends StatelessWidget {
  const RatingKeys({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  void _tap(int star) {
    final v = value ?? 0;
    onChanged(
      v == 2 * star
          ? 2 * star - 1
          : v == 2 * star - 1
          ? null
          : 2 * star,
    );
  }

  static String describe(int? v) {
    if (v == null) return 'No rating';
    final stars = v.isEven ? '${v ~/ 2}' : '${v / 2}';
    return '$stars of 5 stars';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final v = value ?? 0;
    return Semantics(
      label: 'Rating',
      value: describe(value),
      increasedValue: v < 10 ? describe(v + 1) : null,
      decreasedValue: v > 0 ? describe(v > 1 ? v - 1 : null) : null,
      onIncrease: v < 10 ? () => onChanged(v + 1) : null,
      onDecrease: v > 0 ? () => onChanged(v > 1 ? v - 1 : null) : null,
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var star = 1; star <= 5; star++) ...[
              if (star > 1) const SizedBox(width: 8),
              Expanded(child: _key(c, star, v)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _key(ShelfColors c, int star, int v) {
    final full = v >= 2 * star;
    final half = v == 2 * star - 1;
    final color = c.meter[star - 1];
    return ShelfKey(
      depth: full
          ? KeyGeometry.pressed
          : half
          ? KeyGeometry.half
          : KeyGeometry.rest,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onPressed: () => _tap(star),
      child: Container(
        height: 6,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          gradient: LinearGradient(
            stops: const [0, 0.5, 0.5, 1],
            colors: full
                ? [color, color, color, color]
                : half
                ? [color, color, c.off, c.off]
                : [c.off, c.off, c.off, c.off],
          ),
        ),
      ),
    );
  }
}
