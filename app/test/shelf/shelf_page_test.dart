import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/search/search_page.dart';
import 'package:shelf_app/share/link_resolver.dart';
import 'package:shelf_app/share/resolve_page.dart';
import 'package:shelf_app/share/shared_link_inbox.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/tags/tags_page.dart';
import 'package:shelf_app/shelf/shelf_page.dart';
import 'package:shelf_app/shelf/spines_view.dart';
import 'package:shelf_app/theme/shelf_theme.dart';
import 'package:shelf_app/widgets/filter_bar.dart';
import 'package:shelf_app/widgets/rating_keys.dart';
import 'package:shelf_app/widgets/rating_meter.dart';
import 'package:shelf_app/widgets/shelf_key.dart';

import '../auth/fake_auth.dart';
import 'fake_shelf.dart';
import '../search/fake_search.dart';
import '../share/fake_links.dart';

void main() {
  late FakeShelf shelf;
  late SharedLinkInbox inbox;
  late FakeLinks links;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpShelf(
    WidgetTester tester,
    FakeShelf fake, {
    Brightness brightness = Brightness.dark,
    Uri? shared,
    Resolved? resolved,
  }) async {
    shelf = fake;
    inbox = SharedLinkInbox(const Stream.empty())..value = shared;
    links = FakeLinks(resolved ?? UnsupportedLink());
    tester.view.physicalSize = const Size(412, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(brightness),
        home: ShelfPage(
          auth: FakeAuth(signedIn: true),
          shelf: fake,
          search: FakeSearch({}),
          links: links,
          inbox: inbox,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder filterKey(int i) => find
      .descendant(of: find.byType(FilterBar), matching: find.byType(ShelfKey))
      .at(i);

  final three = [
    entry('1', 'OK Computer', rating: 9, tags: {'own'}),
    entry('2', 'Discovery', tags: {'want'}),
    entry('3', 'Blue', rating: 8, tags: {'own'}),
  ];

  testWidgets('lists the albums with title, artist and count', (tester) async {
    await pumpShelf(tester, FakeShelf(three));

    expect(find.text('3 albums'), findsOneWidget);
    for (final title in ['OK Computer', 'Discovery', 'Blue']) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Artist 1'), findsOneWidget);
  });

  testWidgets('the filter bar counts and filters by tag', (tester) async {
    await pumpShelf(tester, FakeShelf(three));

    // All, Own, Want with their counts.
    for (final count in ['3', '2', '1']) {
      expect(
        find.descendant(of: find.byType(FilterBar), matching: find.text(count)),
        findsOneWidget,
      );
    }

    await tester.tap(filterKey(1));
    await tester.pumpAndSettle();
    expect(find.text('OK Computer'), findsOneWidget);
    expect(find.text('Discovery'), findsNothing);
  });

  testWidgets('a filter with no albums says so and offers all', (tester) async {
    await pumpShelf(tester, FakeShelf([three.first]));

    await tester.tap(filterKey(2));
    await tester.pumpAndSettle();
    expect(find.text('No albums marked Want yet'), findsOneWidget);

    await tester.tap(find.text('Show all albums'));
    await tester.pumpAndSettle();
    expect(find.text('OK Computer'), findsOneWidget);
  });

  testWidgets('an empty shelf says how to add albums', (tester) async {
    await pumpShelf(tester, FakeShelf([]));

    expect(find.text('Your shelf is empty'), findsOneWidget);
    expect(find.text('0 albums'), findsOneWidget);
  });

  testWidgets('a load error offers to try again', (tester) async {
    await pumpShelf(tester, FakeShelf(three)..failLoad = true);

    expect(find.text("Couldn't load your shelf"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('OK Computer'), findsOneWidget);
  });

  testWidgets('spines pull up on the first tap and open on the second', (
    tester,
  ) async {
    await pumpShelf(tester, FakeShelf(three));

    await tester.tap(find.byIcon(Icons.view_week_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SpinesView), findsOneWidget);

    final spine = find.text('Artist 2 · Discovery');
    await tester.tap(spine);
    await tester.pumpAndSettle();
    expect(find.text('Artist 2, 1997'), findsOneWidget);
    expect(find.byType(EntryPage), findsNothing);

    await tester.tap(spine);
    await tester.pumpAndSettle();
    expect(find.byType(EntryPage), findsOneWidget);
  });

  testWidgets('saving a rating and comment updates the shelf', (tester) async {
    await pumpShelf(tester, FakeShelf(three));

    await tester.tap(find.text('Discovery'));
    await tester.pumpAndSettle();
    expect(find.text('None'), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byType(RatingKeys),
            matching: find.byType(ShelfKey),
          )
          .at(2), // The third star.
    );
    await tester.enterText(find.byType(TextField), '  Great on vinyl ');
    await tester.pumpAndSettle();
    expect(find.text('3 of 5 stars'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(ShelfPage), findsOneWidget);
    expect(shelf.entries[1].rating, 6);
    expect(shelf.entries[1].comment, 'Great on vinyl');
    expect(
      find.byWidgetPredicate((w) => w is RatingMeter && w.value == 6),
      findsOneWidget,
    );
  });

  testWidgets('removing can be undone', (tester) async {
    await pumpShelf(tester, FakeShelf(three));

    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from shelf'));
    await tester.pumpAndSettle();
    expect(find.text('Blue'), findsNothing);
    expect(find.text('2 albums'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Blue'), findsOneWidget);
    expect(shelf.removed, isEmpty);
  });

  testWidgets('removing takes effect when the snackbar closes', (tester) async {
    await pumpShelf(tester, FakeShelf(three));

    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from shelf'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(shelf.removed, ['3']);
    expect(find.text('Blue'), findsNothing);
    expect(find.text('2 albums'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('meets the accessibility guidelines ($brightness)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpShelf(tester, FakeShelf(three), brightness: brightness);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }

  testWidgets('remembers covers or spines on the device', (tester) async {
    await pumpShelf(tester, FakeShelf(three));
    expect(find.byType(SpinesView), findsNothing);

    await tester.tap(find.byIcon(Icons.view_week_outlined));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('shelf.spines'), isTrue);

    // A new start of the app.
    await tester.pumpWidget(const SizedBox());
    await pumpShelf(tester, FakeShelf(three));
    expect(find.byType(SpinesView), findsOneWidget);
  });

  testWidgets('the menu opens the tags, and the shelf reloads after', (
    tester,
  ) async {
    await pumpShelf(tester, FakeShelf(three));
    final loads = shelf.loads;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tags'));
    await tester.pumpAndSettle();
    expect(find.byType(TagsPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(shelf.loads, loads + 2);
  });

  testWidgets('Add album opens the search', (tester) async {
    await pumpShelf(tester, FakeShelf([]));

    await tester.tap(find.text('Add album'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsOneWidget);
  });

  final shared = Uri.parse(
    'https://open.spotify.com/album/6dVIqQ8qmQ5GBnJ9shOYGE',
  );

  testWidgets('a shared link opens once the shelf has loaded', (tester) async {
    await pumpShelf(
      tester,
      FakeShelf([]),
      shared: shared,
      resolved: FoundAlbum(result('mb-ok', 'OK Computer')),
    );

    expect(links.links, [shared]);
    expect(find.byType(EntryPage), findsOneWidget);
    await tester.tap(find.text('Add to shelf'));
    await tester.pumpAndSettle();

    expect(find.text('Added to your shelf'), findsOneWidget);
    expect(find.text('Added mb-ok'), findsOneWidget);
    expect(inbox.value, isNull);
  });

  testWidgets('a link shared while the app runs opens too', (tester) async {
    await pumpShelf(tester, FakeShelf([]));

    inbox.value = shared;
    await tester.pumpAndSettle();

    expect(find.byType(ResolvePage), findsOneWidget);
  });

  testWidgets('a shared album already on the shelf opens its entry', (
    tester,
  ) async {
    await pumpShelf(
      tester,
      FakeShelf(three),
      shared: shared,
      resolved: FoundAlbum(result('mb2', 'Discovery')),
    );

    expect(find.byType(ResolvePage), findsNothing);
    expect(find.byType(EntryPage), findsOneWidget);
    expect(find.text('Remove from shelf'), findsOneWidget);
    expect(find.text('Already on your shelf'), findsOneWidget);
  });
}
