import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/filters/filter_editor_page.dart';
import 'package:shelf_app/filters/filters_page.dart';
import 'package:shelf_app/shelf/shelf_data.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import '../shelf/fake_shelf.dart';

ShelfEntry rated(
  String id,
  String title, {
  int? rating,
  Set<String> tags = const {},
  bool favorite = false,
}) => ShelfEntry(
  id: id,
  album: Album(id: 'a$id', title: title, artist: 'Artist $id'),
  rating: rating,
  tagIds: tags,
  tracks: [Track(title: 'Song', position: 1, favorite: favorite)],
);

void main() {
  final albums = [
    rated(
      '1',
      'OK Computer',
      rating: 9,
      tags: {'own', 'vinyl'},
      favorite: true,
    ),
    rated('2', 'Blue', rating: 6, tags: {'own', 'cd'}),
    rated('3', 'Promises', tags: {'want'}),
  ];

  group('ShelfFilter.matches', () {
    List<String> titles(ShelfFilter f) => [
      for (final e in albums)
        if (f.matches(e)) e.album.title,
    ];

    test('tags: any or all of them', () {
      expect(titles(const ShelfFilter(tagIds: ['vinyl', 'want'])), [
        'OK Computer',
        'Promises',
      ]);
      expect(
        titles(const ShelfFilter(tagIds: ['own', 'vinyl'], matchAll: true)),
        ['OK Computer'],
      );
    });

    test('a minimum rating, or none', () {
      expect(titles(const ShelfFilter(minRating: 8)), ['OK Computer']);
      expect(titles(const ShelfFilter(unrated: true)), ['Promises']);
    });

    test('favorite tracks, and conditions together', () {
      expect(titles(const ShelfFilter(favoriteTracks: true)), ['OK Computer']);
      expect(titles(const ShelfFilter(tagIds: ['own'], minRating: 6)), [
        'OK Computer',
        'Blue',
      ]);
    });

    test('a hidden group hides the filters on its tags', () {
      final groups = [
        for (final g in suggestedGroups)
          g.id == 'listening' ? g.copyWith(hidden: true) : g,
      ];
      final shelf = Shelf(
        entries: albums,
        allGroups: groups,
        allFilters: [
          ShelfFilter.tag('own', 'Own'),
          ShelfFilter.tag('listened', 'Listened'),
          const ShelfFilter(id: 'best', label: 'Best', minRating: 8),
        ],
      );
      expect([for (final f in shelf.filters) f.label], ['Own', 'Best']);
    });
  });

  late FakeShelf shelf;

  Future<void> pumpFilters(WidgetTester tester, {FakeShelf? fake}) async {
    shelf = fake ?? FakeShelf(albums);
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(ShelfColors.tobacco),
        home: FiltersPage(shelf: shelf),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('lists All first, then the filters with their group', (
    tester,
  ) async {
    await pumpFilters(tester);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Always first'), findsOneWidget);
    expect(find.text('Own'), findsOneWidget);
    expect(find.text('Collection'), findsNWidgets(2));
  });

  testWidgets('adds a filter for a tag', (tester) async {
    await pumpFilters(tester);

    await tapText(tester, 'Add filter');
    await tapText(tester, 'Vinyl');

    expect(shelf.filters.last.tagIds, ['vinyl']);
    expect(find.text('Vinyl'), findsOneWidget);
    expect(find.text('Format'), findsOneWidget);
  });

  testWidgets('removes and reorders filters', (tester) async {
    await pumpFilters(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_handle).at(1)),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect([for (final f in shelf.filters) f.label], ['Want', 'Own']);

    await tester.tap(find.bySemanticsLabel('Remove Own'));
    await tester.pumpAndSettle();
    expect([for (final f in shelf.filters) f.label], ['Want']);
  });

  testWidgets('without filters, says what they are for', (tester) async {
    await pumpFilters(tester, fake: FakeShelf(albums, filters: []));
    expect(
      find.text('Add filters to find albums on your shelf quickly.'),
      findsOneWidget,
    );
  });

  testWidgets('a load error offers to try again', (tester) async {
    await pumpFilters(tester, fake: FakeShelf(albums)..failLoad = true);
    expect(find.text('Couldn’t load your filters'), findsOneWidget);

    await tapText(tester, 'Try again');
    expect(find.text('Own'), findsOneWidget);
  });

  group('A custom filter', () {
    Future<void> openNew(WidgetTester tester) async {
      await pumpFilters(tester);
      await tapText(tester, 'Add filter');
      await tapText(tester, 'Custom filter…');
      expect(find.byType(FilterEditorPage), findsOneWidget);
    }

    testWidgets('needs a condition and a name', (tester) async {
      await openNew(tester);

      await tapText(tester, 'Save');
      expect(find.text('Choose at least one condition.'), findsWidgets);

      await tapText(tester, 'Has favorite tracks');
      await tapText(tester, 'Save');
      expect(find.text('Give the filter a name.'), findsOneWidget);
    });

    testWidgets('combines tags, rating and counts the albums', (tester) async {
      await openNew(tester);

      await tester.enterText(find.byType(TextField), 'Best of mine');
      await tapText(tester, 'Add');
      await tapText(tester, 'Own');
      await tapText(tester, 'Vinyl');
      await tapText(tester, 'Done');
      expect(find.text('Matches 2 albums'), findsOneWidget);

      await tapText(tester, 'All of them');
      expect(find.text('Matches 1 album'), findsOneWidget);
      await tapText(tester, 'Save');

      final saved = shelf.filters.last;
      expect(saved.label, 'Best of mine');
      expect(saved.tagIds, ['own', 'vinyl']);
      expect(saved.matchAll, isTrue);
      expect(find.text('Own and Vinyl'), findsOneWidget);
    });

    testWidgets('rating: at least, or unrated', (tester) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField), 'Unrated');

      await tapText(tester, 'Unrated');
      expect(find.text('Matches 1 album'), findsOneWidget);
      await tapText(tester, 'Save');

      expect(shelf.filters.last.unrated, isTrue);
      expect(find.text('unrated'), findsOneWidget);
    });

    testWidgets('can be edited and deleted', (tester) async {
      await pumpFilters(
        tester,
        fake: FakeShelf(
          albums,
          filters: [
            const ShelfFilter(
              id: 'best',
              name: 'Best',
              label: 'Best',
              minRating: 8,
            ),
          ],
        ),
      );
      expect(find.text('4 stars and up'), findsOneWidget);

      await tapText(tester, 'Best');
      await tapText(tester, 'Has favorite tracks');
      await tapText(tester, 'Save');
      expect(shelf.filters.single.favoriteTracks, isTrue);
      expect(find.text('4 stars and up · favorite tracks'), findsOneWidget);

      await tapText(tester, 'Best');
      await tapText(tester, 'Delete filter');
      await tapText(tester, 'Delete');
      expect(shelf.filters, isEmpty);
    });
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpFilters(tester);
    Future<void> check() async {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }

    await check();
    await tapText(tester, 'Add filter');
    await tapText(tester, 'Custom filter…');
    await check();
    semantics.dispose();
  });
}
