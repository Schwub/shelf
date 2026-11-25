import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/search/manual_album_page.dart';
import 'package:shelf_app/search/search_page.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/shelf_data.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import '../shelf/fake_shelf.dart';
import 'fake_search.dart';

// A 1 × 1 PNG, the smallest valid photo.
final photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  late FakeShelf shelf;
  EntryResult? outcome;
  final picked = <ImageSource>[];

  Future<void> pumpForm(WidgetTester tester, {String title = ''}) async {
    shelf = FakeShelf([]);
    outcome = null;
    picked.clear();
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
                builder: (_) => ManualAlbumPage(
                  shelf: shelf,
                  groups: shelf.groups,
                  title: title,
                  pick: (source) async {
                    picked.add(source);
                    return Uint8List.fromList(photo);
                  },
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String hint, String text) =>
      tester.enterText(find.widgetWithText(TextField, hint), text);

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('title and artist are required, the year must be a year', (
    tester,
  ) async {
    await pumpForm(tester);

    await tap(tester, 'Continue');
    expect(find.text('Enter the title and the artist.'), findsOneWidget);

    await fill(tester, 'Title', 'Demo tape');
    await fill(tester, 'Artist', 'The Locals');
    await fill(tester, 'Year', '94');
    await tap(tester, 'Continue');
    expect(find.textContaining('four digits'), findsOneWidget);
    expect(find.byType(EntryPage), findsNothing);
  });

  testWidgets('adds the album with photo, year and tags', (tester) async {
    await pumpForm(tester, title: 'Demo tape');
    expect(find.text('Demo tape'), findsOneWidget);

    await fill(tester, 'Artist', 'The Locals');
    await fill(tester, 'Year', '1994');
    await tap(tester, 'Take photo');
    expect(picked, [ImageSource.camera]);
    expect(find.bySemanticsLabel('Cover photo'), findsOneWidget);

    await tap(tester, 'Continue');
    expect(find.text('Add to shelf'), findsOneWidget);
    await tap(tester, 'Own');
    await tap(tester, 'Add to shelf');

    expect(outcome, EntryResult.added);
    final added = shelf.manual.single;
    expect(added.title, 'Demo tape');
    expect(added.artist, 'The Locals');
    expect(added.year, 1994);
    expect(added.cover, photo);
    expect(shelf.addedTags, ['own']);
  });

  testWidgets('works without year and photo', (tester) async {
    await pumpForm(tester);
    await fill(tester, 'Title', 'Untitled');
    await fill(tester, 'Artist', 'Nobody');
    await tap(tester, 'Continue');
    await tap(tester, 'Add to shelf');

    expect(shelf.manual.single.year, isNull);
    expect(shelf.manual.single.cover, isNull);
  });

  test('sends the photo as base64 with its type', () {
    final json = ManualAlbum(
      title: 'A',
      artist: 'B',
      cover: Uint8List.fromList(photo),
    ).toJson();
    expect(json['cover'], {'data': base64Encode(photo), 'type': 'image/png'});
    expect(
      (ManualAlbum(
            title: 'A',
            artist: 'B',
            cover: Uint8List.fromList([0xff, 0xd8]),
          ).toJson()['cover']
          as Map)['type'],
      'image/jpeg',
    );
    expect(const ManualAlbum(title: 'A', artist: 'B').toJson()['cover'], null);
  });

  testWidgets('search offers to add it yourself', (tester) async {
    final search = FakeSearch({});
    shelf = FakeShelf([]);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(Brightness.dark),
        home: SearchPage(search: search, shelf: shelf, onShelf: const {}),
      ),
    );
    await tester.enterText(find.byType(TextField), 'local tape');
    await tester.pump(SearchPage.pause);
    await tester.pumpAndSettle();

    await tap(tester, 'Add it yourself');
    expect(find.byType(ManualAlbumPage), findsOneWidget);
    expect(find.text('local tape'), findsOneWidget);
  });
}
