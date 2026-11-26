import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/theme/shelf_theme.dart';
import 'package:shelf_app/widgets/shelf_key.dart';

import 'fake_shelf.dart';

void main() {
  late FakeShelf shelf;
  EntryResult? result;
  var closed = false;

  Future<void> pumpEntry(WidgetTester tester) async {
    shelf = FakeShelf([entry('1', 'Blue', rating: 6)]);
    result = null;
    closed = false;
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(ShelfColors.tobacco),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push(
                MaterialPageRoute<EntryResult>(
                  builder: (_) =>
                      EntryPage(entry: shelf.entries.first, shelf: shelf),
                ),
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapStar(WidgetTester tester, int star) async {
    final keys = find.descendant(
      of: find.byType(EntryPage),
      matching: find.byType(ShelfKey),
    );
    await tester.tap(keys.at(star)); // Close is the first key.
    await tester.pumpAndSettle();
  }

  testWidgets('shows the album and its rating', (tester) async {
    await pumpEntry(tester);

    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Artist 1, 1997'), findsOneWidget);
    expect(find.text('Added 1 Nov 2026'), findsOneWidget);
    expect(find.text('3 of 5 stars'), findsOneWidget);
  });

  testWidgets('cancel without changes leaves at once', (tester) async {
    await pumpEntry(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('leaving with changes asks first', (tester) async {
    await pumpEntry(tester);
    await tapStar(tester, 5);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(closed, isFalse);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(shelf.entries.first.rating, 6);
  });

  testWidgets('a failed save says so and stays', (tester) async {
    await pumpEntry(tester);
    await tapStar(tester, 5);
    shelf.failSave = true;

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't save. Try again."), findsOneWidget);
    expect(closed, isFalse);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, EntryResult.saved);
    expect(shelf.entries.first.rating, 10);
  });

  testWidgets('remove returns to the shelf for the undo', (tester) async {
    await pumpEntry(tester);

    await tester.ensureVisible(find.text('Remove from shelf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from shelf'));
    await tester.pumpAndSettle();

    expect(result, EntryResult.removed);
    expect(shelf.removed, isEmpty);
  });
}
