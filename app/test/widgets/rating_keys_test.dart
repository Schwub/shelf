import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/widgets/rating_keys.dart';
import 'package:shelf_app/widgets/shelf_key.dart';

import 'harness.dart';

void main() {
  int? rating;

  Future<void> pumpRating(WidgetTester tester, int? initial) async {
    rating = initial;
    await tester.pumpWidget(
      themed(
        StatefulBuilder(
          builder: (context, setState) => RatingKeys(
            value: rating,
            onChanged: (v) => setState(() => rating = v),
          ),
        ),
      ),
    );
  }

  Future<void> tapKey(WidgetTester tester, int star) async {
    await tester.tap(find.byType(ShelfKey).at(star - 1));
    await tester.pump();
  }

  testWidgets('a key sets stars, then a half, then clears', (tester) async {
    await pumpRating(tester, null);

    await tapKey(tester, 3);
    expect(rating, 6);
    await tapKey(tester, 3);
    expect(rating, 5);
    await tapKey(tester, 3);
    expect(rating, null);
  });

  testWidgets('another key sets its number of stars', (tester) async {
    await pumpRating(tester, 6);

    await tapKey(tester, 2);

    expect(rating, 4);
  });

  testWidgets('full stars are pressed, a half star halfway', (tester) async {
    await pumpRating(tester, 7);

    expect(keyDepths(tester), [
      KeyGeometry.pressed,
      KeyGeometry.pressed,
      KeyGeometry.pressed,
      KeyGeometry.half,
      KeyGeometry.rest,
    ]);
  });

  testWidgets('screen readers get the value and half-star steps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpRating(tester, 7);
    final node = find.semantics.byLabel('Rating');

    expect(
      node.evaluate().single,
      isSemantics(
        label: 'Rating',
        value: '3.5 of 5 stars',
        increasedValue: '4 of 5 stars',
        decreasedValue: '3 of 5 stars',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    tester.semantics.increase(node);
    await tester.pump();
    expect(rating, 8);

    tester.semantics.decrease(node);
    await tester.pump();
    tester.semantics.decrease(node);
    await tester.pump();
    expect(rating, 6);
    semantics.dispose();
  });

  test('describe', () {
    expect(RatingKeys.describe(null), 'No rating');
    expect(RatingKeys.describe(1), '0.5 of 5 stars');
    expect(RatingKeys.describe(10), '5 of 5 stars');
  });
}
