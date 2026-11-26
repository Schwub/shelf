import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/search/album_search.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/theme/shelf_theme.dart';
import 'package:shelf_app/tracks/track_editor_page.dart';

import '../shelf/fake_shelf.dart';

const kidA = [
  Track(title: 'Everything in Its Right Place', position: 1, lengthMs: 251000),
  Track(title: 'Kid A', position: 2, lengthMs: 284000),
  Track(title: 'The National Anthem', position: 3),
];

ShelfEntry withTracks(ShelfEntry e, List<Track> tracks) => ShelfEntry(
  id: e.id,
  addedAt: e.addedAt,
  album: e.album,
  rating: e.rating,
  tagIds: e.tagIds,
  tracks: tracks,
);

void main() {
  late FakeShelf shelf;
  EntryResult? result;

  Future<void> pump(WidgetTester tester, Widget Function() page) async {
    result = null;
    tester.view.physicalSize = const Size(412, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(ShelfColors.tobacco),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.of(context)
                .push(MaterialPageRoute<EntryResult>(builder: (_) => page())),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  const searchResult = SearchResult(
    musicbrainzId: 'mb-kid',
    title: 'Kid A',
    artist: 'Radiohead',
    year: 2000,
  );

  Future<void> pumpAdd(WidgetTester tester) async {
    shelf = FakeShelf([])..trackLists = {'mb-kid': kidA};
    await pump(tester, () => EntryPage.add(result: searchResult, shelf: shelf));
  }

  Future<void> pumpEdit(WidgetTester tester, ShelfEntry entry) async {
    shelf = FakeShelf([entry]);
    await pump(
      tester,
      () => EntryPage(entry: shelf.entries.first, shelf: shelf),
    );
  }

  group('A new album from MusicBrainz', () {
    testWidgets('suggests its track list, used once approved', (tester) async {
      await pumpAdd(tester);

      expect(shelf.trackLookups, ['mb-kid']);
      expect(find.text('Track list from MusicBrainz: '), findsNothing);
      expect(find.textContaining('3 tracks'), findsOneWidget);
      expect(find.text('2. Kid A'), findsOneWidget);

      await tapText(tester, 'Use it');
      expect(find.text('Everything in Its Right Place'), findsOneWidget);
      expect(find.text('4:11'), findsOneWidget);

      await tapText(tester, 'Add to shelf');
      expect(shelf.entries.single.tracks, kidA);
      expect(result, EntryResult.added);
    });

    testWidgets('Not this one leaves it without a track list', (tester) async {
      await pumpAdd(tester);

      await tapText(tester, 'Not this one');
      expect(find.text('No track list yet.'), findsOneWidget);
      await tapText(tester, 'Add to shelf');
      expect(shelf.entries.single.tracks, isEmpty);
    });

    testWidgets('a failed lookup can be tried again', (tester) async {
      shelf = FakeShelf([])
        ..trackLists = {'mb-kid': kidA}
        ..failTracks = true;
      await pump(
        tester,
        () => EntryPage.add(result: searchResult, shelf: shelf),
      );

      expect(
        find.text('Couldn’t get the track list from MusicBrainz.'),
        findsOneWidget,
      );
      await tapText(tester, 'Try again');
      expect(find.textContaining('3 tracks'), findsOneWidget);
    });

    testWidgets('says so when MusicBrainz has none', (tester) async {
      shelf = FakeShelf([]);
      await pump(
        tester,
        () => EntryPage.add(result: searchResult, shelf: shelf),
      );

      expect(
        find.text('MusicBrainz has no track list for this album.'),
        findsOneWidget,
      );
      expect(find.text('Get track list'), findsNothing);
      expect(find.text('Enter tracks'), findsOneWidget);
    });
  });

  group('An album on the shelf', () {
    testWidgets('gets its track list later, on request', (tester) async {
      await pumpEdit(tester, entry('1', 'Kid A'));
      shelf.trackLists = {'mb1': kidA};

      expect(shelf.trackLookups, isEmpty);
      await tapText(tester, 'Get track list');
      await tapText(tester, 'Use it');
      await tapText(tester, 'Save');

      expect(shelf.entries.single.tracks, kidA);
    });

    testWidgets('marks favorites, saved with the entry', (tester) async {
      await pumpEdit(tester, withTracks(entry('1', 'Kid A'), kidA));

      await tester.tap(find.bySemanticsLabel('Favorite: Kid A'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Save');

      expect(
        [for (final t in shelf.entries.single.tracks) t.favorite],
        [false, true, false],
      );
      expect(result, EntryResult.saved);
    });

    testWidgets('leaving with a new favorite asks first', (tester) async {
      await pumpEdit(tester, withTracks(entry('1', 'Kid A'), kidA));

      await tester.tap(find.bySemanticsLabel('Favorite: Kid A'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });

    testWidgets('a long list shows the favorites until Show all', (
      tester,
    ) async {
      final tracks = [
        for (var i = 1; i <= 15; i++)
          Track(title: 'Song $i', position: i, favorite: i == 7),
      ];
      await pumpEdit(tester, withTracks(entry('1', 'Long'), tracks));

      expect(find.text('Song 7'), findsOneWidget);
      expect(find.text('Song 1'), findsNothing);
      await tapText(tester, 'Show all 15 tracks');
      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 15'), findsOneWidget);
    });

    testWidgets('shows a heading per disc', (tester) async {
      await pumpEdit(
        tester,
        withTracks(entry('1', 'Double'), const [
          Track(title: 'One', position: 1),
          Track(title: 'Two', disc: 2, position: 1),
        ]),
      );

      expect(find.text('Disc 1'), findsOneWidget);
      expect(find.text('Disc 2'), findsOneWidget);
    });
  });

  group('Entering tracks', () {
    testWidgets('works for an album added by hand', (tester) async {
      shelf = FakeShelf([]);
      await pump(
        tester,
        () => EntryPage.manual(
          manual: const ManualAlbum(title: 'Tape', artist: 'Me'),
          shelf: shelf,
        ),
      );
      expect(find.text('Get track list'), findsNothing);

      await tapText(tester, 'Enter tracks');
      expect(find.byType(TrackEditorPage), findsOneWidget);
      await tapText(tester, 'Add track');
      await tester.enterText(find.byType(TextField).last, 'Side A');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Side B');
      await tapText(tester, 'Done');

      expect(find.text('Side A'), findsOneWidget);
      await tapText(tester, 'Add to shelf');
      expect(shelf.entries.single.tracks, const [
        Track(title: 'Side A', position: 1),
        Track(title: 'Side B', position: 2),
      ]);
    });

    testWidgets('edits keep favorites, renumber and drop empty tracks', (
      tester,
    ) async {
      await pumpEdit(
        tester,
        withTracks(entry('1', 'Kid A'), [
          kidA[0],
          kidA[1].copyWith(favorite: true),
          kidA[2],
        ]),
      );
      await tapText(tester, 'Edit tracks');

      await tester.tap(
        find
            .descendant(
              of: find.byType(TrackEditorPage),
              matching: find.byIcon(Icons.close),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '  ');
      await tapText(tester, 'Add track');
      await tester.enterText(find.byType(TextField).last, 'Optimistic');
      await tapText(tester, 'Done');
      await tapText(tester, 'Save');

      expect(shelf.entries.single.tracks, [
        kidA[1].copyWith(favorite: true, position: 1),
        const Track(title: 'Optimistic', position: 2),
      ]);
    });

    testWidgets('Cancel keeps the list as it was', (tester) async {
      await pumpEdit(tester, withTracks(entry('1', 'Kid A'), kidA));
      await tapText(tester, 'Edit tracks');

      await tester.tap(
        find
            .descendant(
              of: find.byType(TrackEditorPage),
              matching: find.byIcon(Icons.close),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Cancel');

      expect(find.text('Everything in Its Right Place'), findsOneWidget);
    });
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpEdit(tester, withTracks(entry('1', 'Kid A'), kidA));
    Future<void> check() async {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }

    await check();
    await tapText(tester, 'Edit tracks');
    await check();
    semantics.dispose();
  });
}
