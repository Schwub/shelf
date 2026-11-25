import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/widgets/rating_meter.dart';

import 'harness.dart';

void main() {
  List<Color> barHalves(WidgetTester tester) => [
    for (final box in tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(RatingMeter),
        matching: find.byType(DecoratedBox),
      ),
    ))
      for (final i in [0, 2])
        ((box.decoration as BoxDecoration).gradient! as LinearGradient)
            .colors[i],
  ];

  testWidgets('five 6 px bars, half a star fills half a bar', (tester) async {
    await tester.pumpWidget(
      themed(const Center(child: RatingMeter(7)), theme: AppTheme.evening),
    );
    final c = ShelfColors.evening;

    final bars = find.descendant(
      of: find.byType(RatingMeter),
      matching: find.byType(DecoratedBox),
    );
    expect(bars, findsNWidgets(5));
    for (final bar in bars.evaluate()) {
      expect(tester.getSize(find.byWidget(bar.widget)).height, 6);
    }
    expect(barHalves(tester), [
      ...[
        for (final m in c.meter.take(3)) ...[m, m],
      ],
      c.meter[3],
      c.off,
      c.off,
      c.off,
    ]);
  });
}
