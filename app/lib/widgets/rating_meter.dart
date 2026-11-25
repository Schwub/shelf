import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import 'rating_keys.dart';

/// The small rating meter under a cover: five bars, half a star fills half a
/// bar. [value] is in half stars (1–10).
class RatingMeter extends StatelessWidget {
  const RatingMeter(this.value, {super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    return Semantics(
      label: 'Rating, ${RatingKeys.describe(value)}',
      excludeSemantics: true,
      child: SizedBox(
        width: 76,
        height: 6,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var star = 1; star <= 5; star++) ...[
              if (star > 1) const SizedBox(width: 4),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: LinearGradient(
                      stops: const [0, 0.5, 0.5, 1],
                      colors: [
                        for (final half in [1, 1, 2, 2])
                          value >= 2 * star - 2 + half
                              ? c.meter[star - 1]
                              : c.off,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
