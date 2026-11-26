import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/search/search_page.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import '../shelf/fake_shelf.dart';
import 'fake_search.dart';

void main() {
  late FakeSearch search;
  late FakeShelf shelf;
  EntryResult? outcome;

  final okComputer = result('mb-ok', 'OK Computer');
  final kidA = result('mb-kid', 'Kid A');

  Future<void> pumpSearch(
    WidgetTester tester, {
    Map<String, ShelfEntry> onShelf = const {},
  }) async {
    search = FakeSearch({
      'radiohead': [okComputer, kidA],
    });
    shelf = FakeShelf([]);
    outcome = null;
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(ShelfColors.tobacco),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              outcome = await Navigator.of(context).push(
                MaterialPageRoute<EntryResult>(
                  builder: (_) => SearchPage(
                    search: search,
                    shelf: shelf,
                    onShelf: onShelf,
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(SearchPage.pause);
    await tester.pumpAndSettle();
  }

  testWidgets('searches once typing pauses and lists the results', (
    tester,
  ) async {
    await pumpSearch(tester);
    expect(find.text('Search by album title or artist.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'radio');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'radiohead');
    await tester.pump(SearchPage.pause);
    await tester.pumpAndSettle();

    expect(search.queries, ['radiohead']);
    expect(find.text('OK Computer'), findsOneWidget);
    expect(find.text('Kid A'), findsOneWidget);
    expect(find.text('Radiohead · 1997'), findsNWidgets(2));
  });

  testWidgets('shows a spinner from the first letter, searching after 0.5 s', (
    tester,
  ) async {
    await pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'radiohead');
    await tester.pump();
    expect(find.bySemanticsLabel('Searching'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 499));
    expect(search.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(search.queries, ['radiohead']);
    expect(find.bySemanticsLabel('Searching'), findsNothing);
  });

  testWidgets('typing back to the last search stops the spinner', (
    tester,
  ) async {
    await pumpSearch(tester);
    await type(tester, 'radiohead');

    await tester.enterText(find.byType(TextField), 'radiohea');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'radiohead');
    await tester.pump(SearchPage.pause);
    await tester.pumpAndSettle();

    expect(search.queries, ['radiohead']);
    expect(find.bySemanticsLabel('Searching'), findsNothing);
    expect(find.text('OK Computer'), findsOneWidget);
  });

  testWidgets('no results says so', (tester) async {
    await pumpSearch(tester);

    await type(tester, 'ok computr');

    expect(find.textContaining('No albums found for'), findsOneWidget);
    expect(find.textContaining('ok computr'), findsWidgets);
  });

  testWidgets('a failed search offers to try again', (tester) async {
    await pumpSearch(tester);
    search.fail = true;

    await type(tester, 'radiohead');
    expect(find.text("Couldn't search"), findsOneWidget);
    expect(find.text('Add it yourself'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('OK Computer'), findsOneWidget);
  });

  testWidgets('a result adds the album with rating and comment', (
    tester,
  ) async {
    await pumpSearch(tester);
    await type(tester, 'radiohead');

    await tester.tap(find.text('OK Computer'));
    await tester.pumpAndSettle();
    expect(find.text('Add to shelf'), findsOneWidget);
    expect(find.text('Remove from shelf'), findsNothing);

    await tester.enterText(find.byType(TextField), 'First listen');
    await tester.tap(find.text('Add to shelf'));
    await tester.pumpAndSettle();

    expect(outcome, EntryResult.added);
    expect(shelf.entries.single.album.musicbrainzId, 'mb-ok');
    expect(shelf.entries.single.comment, 'First listen');
  });

  testWidgets('a failed add says so and stays', (tester) async {
    await pumpSearch(tester);
    await type(tester, 'radiohead');
    await tester.tap(find.text('Kid A'));
    await tester.pumpAndSettle();
    shelf.failAdd = true;

    await tester.tap(find.text('Add to shelf'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't add the album. Try again."), findsOneWidget);
    expect(outcome, isNull);
  });

  testWidgets('an album on the shelf is marked and opens to edit', (
    tester,
  ) async {
    final mine = ShelfEntry(
      id: 'e1',
      addedAt: added,
      album: const Album(
        id: 'a1',
        musicbrainzId: 'mb-ok',
        title: 'OK Computer',
        artist: 'Radiohead',
      ),
      rating: 9,
    );
    await pumpSearch(tester, onShelf: {'mb-ok': mine});
    await type(tester, 'radiohead');

    expect(find.text('On your shelf'), findsOneWidget);
    await tester.tap(find.text('OK Computer'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('4.5 of 5 stars'), findsOneWidget);
  });
}
