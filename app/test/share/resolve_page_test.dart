import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/search/manual_album_page.dart';
import 'package:shelf_app/search/search_page.dart';
import 'package:shelf_app/share/link_resolver.dart';
import 'package:shelf_app/share/resolve_page.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/shelf_data.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import '../search/fake_search.dart';
import '../shelf/fake_shelf.dart';
import 'fake_links.dart';

// A 1 × 1 PNG, the smallest valid cover.
final photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  late FakeLinks links;
  late FakeShelf shelf;
  EntryResult? outcome;
  final opened = <ShelfEntry>[];
  final link = Uri.parse(
    'https://open.spotify.com/album/6dVIqQ8qmQ5GBnJ9shOYGE',
  );

  Future<void> pumpResolve(
    WidgetTester tester,
    Object answer, {
    Completer<void>? hold,
    Map<String, ShelfEntry> onShelf = const {},
  }) async {
    links = FakeLinks(answer)..hold = hold;
    shelf = FakeShelf([]);
    outcome = null;
    opened.clear();
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(Brightness.dark),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => outcome = await Navigator.of(context).push(
              MaterialPageRoute<EntryResult>(
                builder: (_) => ResolvePage(
                  link: link,
                  resolver: links,
                  shelf: shelf,
                  search: FakeSearch({}),
                  onShelf: onShelf,
                  openEntry: opened.add,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('says it is finding the album', (tester) async {
    final hold = Completer<void>();
    await pumpResolve(
      tester,
      FoundAlbum(result('mb-ok', 'OK Computer')),
      hold: hold,
    );

    expect(find.text('Finding album…'), findsOneWidget);
    expect(find.text(link.toString()), findsOneWidget);
    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byType(EntryPage), findsOneWidget);
  });

  testWidgets('a found album can be added', (tester) async {
    await pumpResolve(tester, FoundAlbum(result('mb-ok', 'OK Computer')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to shelf'));
    await tester.pumpAndSettle();

    expect(shelf.entries.single.album.musicbrainzId, 'mb-ok');
    expect(outcome, EntryResult.added);
    expect(find.byType(ResolvePage), findsNothing);
  });

  testWidgets('going back from the album leaves the link too', (tester) async {
    await pumpResolve(tester, FoundAlbum(result('mb-ok', 'OK Computer')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(outcome, isNull);
  });

  testWidgets('an album on the shelf goes back to open its entry', (
    tester,
  ) async {
    final discovery = entry('2', 'Discovery');
    await pumpResolve(
      tester,
      FoundAlbum(result('mb2', 'Discovery')),
      onShelf: {'mb2': discovery},
    );
    await tester.pumpAndSettle();

    expect(opened, [discovery]);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('an album MusicBrainz lacks is added by hand, prefilled', (
    tester,
  ) async {
    await pumpResolve(
      tester,
      UnknownAlbum(
        title: 'halftone paradise',
        artist: 'Ewan Moore',
        year: 2026,
        cover: photo,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ManualAlbumPage), findsOneWidget);
    expect(find.text('halftone paradise'), findsOneWidget);
    expect(find.text('Ewan Moore'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.bySemanticsLabel('Cover photo'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to shelf'));
    await tester.pumpAndSettle();

    final added = shelf.manual.single;
    expect(
      (added.title, added.artist, added.year),
      ('halftone paradise', 'Ewan Moore', 2026),
    );
    expect(added.cover, photo);
    expect(outcome, EntryResult.added);
  });

  testWidgets('a track says so and offers the search', (tester) async {
    await pumpResolve(tester, const NotAnAlbum('track'));
    await tester.pumpAndSettle();

    expect(find.text('That’s a track, not an album'), findsOneWidget);
    await tester.tap(find.text('Search for an album'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsOneWidget);
  });

  testWidgets('other sites say so', (tester) async {
    await pumpResolve(tester, UnsupportedLink());
    await tester.pumpAndSettle();
    expect(find.text('shelf can’t read that link'), findsOneWidget);
  });

  testWidgets('broken links say so', (tester) async {
    await pumpResolve(tester, LinkNotFound());
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t find that page'), findsOneWidget);
  });

  testWidgets('a failed lookup can be tried again', (tester) async {
    await pumpResolve(tester, Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t look up the link'), findsOneWidget);

    links.answer = FoundAlbum(result('mb-ok', 'OK Computer'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(links.links, [link, link]);
    expect(find.byType(EntryPage), findsOneWidget);
  });
}
