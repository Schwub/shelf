import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/widgets/filter_bar.dart';
import 'package:shelf_app/widgets/shelf_key.dart';

import 'harness.dart';

void main() {
  const five = [
    (label: 'All', count: 128),
    (label: 'Own', count: 54),
    (label: 'Want', count: 17),
    (label: 'Want to listen', count: 23),
    (label: 'Listened', count: 96),
  ];
  const seven = [
    ...five,
    (label: 'Vinyl', count: 31),
    (label: 'Jazz', count: 12),
  ];
  // Five keys and four 6 px gaps across 400 px.
  const fiveWidth = (400 - 4 * 6) / 5;

  Future<void> pumpBar(
    WidgetTester tester,
    List<Filter> filters, {
    ValueChanged<int>? onSelected,
  }) => tester.pumpWidget(
    themed(
      FilterBar(
        filters: filters,
        selected: 1,
        onSelected: onSelected ?? (_) {},
      ),
    ),
  );

  testWidgets('tapping a key selects its filter', (tester) async {
    int? selected;
    await pumpBar(tester, five, onSelected: (i) => selected = i);

    await tester.tap(find.text('17'));

    expect(selected, 2);
  });

  testWidgets('the selected filter is pressed with its light on', (
    tester,
  ) async {
    await pumpBar(tester, five);

    expect(keyDepths(tester), [
      KeyGeometry.rest,
      KeyGeometry.pressed,
      KeyGeometry.rest,
      KeyGeometry.rest,
      KeyGeometry.rest,
    ]);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Own, 54')),
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
  });

  testWidgets('up to five filters fill the width', (tester) async {
    await pumpBar(tester, five);

    for (final key in tester.widgetList(find.byType(ShelfKey))) {
      expect(
        tester.getSize(find.byWidget(key)).width,
        closeTo(fiveWidth, 0.01),
      );
    }
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('more than five keep the width of five and scroll', (
    tester,
  ) async {
    await pumpBar(tester, seven);

    expect(
      tester.getSize(find.byType(ShelfKey).first).width,
      closeTo(fiveWidth, 0.01),
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.drag(find.text('128'), const Offset(-300, 0));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Jazz')).dx,
      lessThan(tester.getTopRight(find.byType(FilterBar)).dx),
    );
  });
}
