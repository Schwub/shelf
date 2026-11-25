import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/widgets/shelf_key.dart';

import 'harness.dart';

void main() {
  group('KeyGeometry', () {
    void expectGeometry(double depth, double right, double front) {
      final g = KeyGeometry(depth);
      expect(g.right, closeTo(right, 1e-9));
      expect(g.front, closeTo(front, 1e-9));
      // The face moves by what the sides lose.
      expect(g.faceOffset.dx, closeTo(5 - right, 1e-9));
      expect(g.faceOffset.dy, closeTo(6 - front, 1e-9));
    }

    test('sides shrink together in the 5:6 ratio', () {
      expectGeometry(KeyGeometry.rest, 5, 6);
      expectGeometry(KeyGeometry.half, 3.5, 4.2);
      expectGeometry(KeyGeometry.pressed, 2, 2.4);
    });

    test('the shadow shrinks with the height', () {
      final rest = const KeyGeometry(KeyGeometry.rest).shadow(Colors.black);
      expect(rest.offset, const Offset(3, 4));
      expect(rest.blurRadius, 5);
      final half = const KeyGeometry(KeyGeometry.half).shadow(Colors.black);
      expect(half.offset.dx, closeTo(2.1, 1e-9));
      expect(half.offset.dy, closeTo(2.8, 1e-9));
      expect(half.blurRadius, closeTo(3.5, 1e-9));
    });
  });

  testWidgets('a tap calls onPressed with a haptic click', (tester) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    var taps = 0;
    await tester.pumpWidget(
      themed(ShelfKey(onPressed: () => taps++, child: const Text('Save'))),
    );

    await tester.tap(find.text('Save'));

    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('an action key goes down only while held', (tester) async {
    await tester.pumpWidget(
      themed(ShelfKey(onPressed: () {}, child: const Text('Save'))),
    );
    expect(keyDepths(tester), [KeyGeometry.rest]);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Save')),
    );
    await tester.pump();
    expect(keyDepths(tester), [KeyGeometry.pressed]);

    await gesture.up();
    await tester.pump();
    expect(keyDepths(tester), [KeyGeometry.rest]);
  });

  testWidgets('a selected key stays pressed and says so', (tester) async {
    await tester.pumpWidget(
      themed(
        ShelfKey(
          selected: true,
          light: true,
          onPressed: () {},
          child: const Text('Own'),
        ),
      ),
    );

    expect(keyDepths(tester), [KeyGeometry.pressed]);
    expect(
      tester.getSemantics(find.byType(ShelfKey)),
      isSemantics(
        label: 'Own',
        isButton: true,
        isSelected: true,
        isEnabled: true,
      ),
    );
  });

  testWidgets('a disabled key ignores taps', (tester) async {
    await tester.pumpWidget(themed(const ShelfKey(child: Text('Add'))));

    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(keyDepths(tester), [KeyGeometry.rest]);
    expect(
      tester.getSemantics(find.byType(ShelfKey)),
      isSemantics(isButton: true, isEnabled: false),
    );
  });

  testWidgets('the key looks 44 × 44 and touches 48 × 48', (tester) async {
    await tester.pumpWidget(
      themed(
        Row(
          children: [
            ShelfKey(
              semanticLabel: 'Close',
              padding: EdgeInsets.zero,
              onPressed: () {},
              child: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );

    final key = find.byType(ShelfKey);
    expect(tester.getSize(key), const Size(48, 48));
    expect(
      tester.getSize(
        find.descendant(of: key, matching: find.byType(CustomPaint)),
      ),
      const Size(44, 44),
    );
  });

  group('themes', () {
    Color label(WidgetTester tester) =>
        DefaultTextStyle.of(tester.element(find.text('Own'))).style.color!;

    testWidgets('without lights a chosen key shows in its label', (
      tester,
    ) async {
      await tester.pumpWidget(
        themed(
          ShelfKey(
            light: true,
            selected: true,
            onPressed: () {},
            child: const Text('Own'),
          ),
        ),
      );
      expect(label(tester), ShelfColors.tobacco.signal);
    });

    testWidgets('with lights the label stays in text colour', (tester) async {
      await tester.pumpWidget(
        themed(
          ShelfKey(
            light: true,
            selected: true,
            onPressed: () {},
            child: const Text('Own'),
          ),
          theme: AppTheme.evening,
        ),
      );
      expect(label(tester), ShelfColors.evening.text);
    });
  });
}
