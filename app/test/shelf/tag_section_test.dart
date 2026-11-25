import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/search/album_search.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/tag_section.dart';
import 'package:shelf_app/theme/shelf_theme.dart';
import 'package:shelf_app/widgets/shelf_key.dart';

import 'fake_shelf.dart';

void main() {
  group('TagChoice', () {
    final none = TagChoice(suggestedGroups, const {});

    test('an exclusive group keeps one tag', () {
      final choice = none.toggle('want').toggle('own');
      expect(choice.chosen, {'own'});
    });

    test('a multiple-choice group keeps several', () {
      final choice = none.toggle('jazz').toggle('pop');
      expect(choice.chosen, {'jazz', 'pop'});
    });

    test('releasing a parent tag removes its sub-tags', () {
      final choice = none.toggle('own').toggle('vinyl').toggle('cd');
      expect(choice.toggle('own').chosen, isEmpty);
      // Switching the exclusive group releases the parent too.
      expect(choice.toggle('want').chosen, {'want'});
    });

    test('orders parent tags before their sub-tags', () {
      expect(none.ordered(['vinyl', 'jazz', 'own']).last, 'vinyl');
    });
  });

  late FakeShelf shelf;
  EntryResult? outcome;

  Future<void> pumpEntry(WidgetTester tester, {Set<String>? tags}) async {
    shelf = FakeShelf([entry('1', 'Blue', tags: tags)]);
    outcome = null;
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
                builder: (_) => EntryPage(
                  entry: shelf.entries.first,
                  shelf: shelf,
                  groups: shelf.groups,
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

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  bool pressed(WidgetTester tester, String name) => tester
      .widget<ShelfKey>(
        find.ancestor(of: find.text(name), matching: find.byType(ShelfKey)),
      )
      .selected!;

  testWidgets('groups show as keys; Format appears under Own', (tester) async {
    await pumpEntry(tester);
    for (final label in ['Collection', 'Listening', 'Genre']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Format'), findsNothing);

    await tap(tester, 'Own');
    expect(find.text('Format'), findsOneWidget);
    await tap(tester, 'Vinyl');
    expect(pressed(tester, 'Vinyl'), isTrue);

    // Want releases Own, and with it Format and Vinyl.
    await tap(tester, 'Want');
    expect(pressed(tester, 'Want'), isTrue);
    expect(pressed(tester, 'Own'), isFalse);
    expect(find.text('Format'), findsNothing);
  });

  testWidgets('saving sends the changed tags, parents first', (tester) async {
    await pumpEntry(tester, tags: {'want'});

    await tap(tester, 'Own');
    await tap(tester, 'File');
    await tap(tester, 'Listened');
    await tap(tester, 'Save');

    expect(outcome, EntryResult.saved);
    expect(shelf.removedTags, {'want'});
    expect(shelf.addedTags.toSet(), {'own', 'file', 'listened'});
    expect(
      shelf.addedTags.indexOf('own'),
      lessThan(shelf.addedTags.indexOf('file')),
    );
    expect(shelf.entries.first.tagIds, {'own', 'file', 'listened'});
  });

  testWidgets('a large group shows only its chosen tags', (tester) async {
    await pumpEntry(tester, tags: {'jazz'});

    expect(find.text('Jazz'), findsOneWidget);
    expect(find.text('Ambient'), findsNothing);
  });

  testWidgets('the Add sheet searches and ticks tags', (tester) async {
    await pumpEntry(tester);
    expect(find.text('No genre yet'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add genre'));
    await tester.pumpAndSettle();
    expect(find.text('Ambient'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'kraut');
    await tester.pumpAndSettle();
    expect(find.text('Ambient'), findsNothing);
    await tap(tester, 'Krautrock');
    await tap(tester, 'Done');

    expect(pressed(tester, 'Krautrock'), isTrue);
    expect(find.text('No genre yet'), findsNothing);
  });

  testWidgets('the Add sheet creates a tag that matches nothing', (
    tester,
  ) async {
    await pumpEntry(tester);
    await tester.tap(find.bySemanticsLabel('Add genre'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'shoegaze');
    await tester.pumpAndSettle();
    expect(find.text('No genre matches “shoegaze”.'), findsOneWidget);
    await tap(tester, 'Create “Shoegaze”');
    await tap(tester, 'Done');

    expect(shelf.groups.last.tags.last.name, 'Shoegaze');
    expect(pressed(tester, 'Shoegaze'), isTrue);
    await tap(tester, 'Save');
    expect(shelf.addedTags, ['shoegaze']);
  });

  testWidgets('a failed create says so and keeps the sheet open', (
    tester,
  ) async {
    await pumpEntry(tester);
    await tester.tap(find.bySemanticsLabel('Add genre'));
    await tester.pumpAndSettle();
    shelf.failCreate = true;

    await tester.enterText(find.byType(TextField).last, 'shoegaze');
    await tester.pumpAndSettle();
    await tap(tester, 'Create “Shoegaze”');

    expect(find.textContaining("Couldn't create “Shoegaze”"), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('adding an album sends its tags', (tester) async {
    shelf = FakeShelf([]);
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(Brightness.dark),
        home: EntryPage.add(
          result: const SearchResult(
            musicbrainzId: 'mb-ok',
            title: 'OK Computer',
            artist: 'Radiohead',
          ),
          shelf: shelf,
          groups: shelf.groups,
        ),
      ),
    );
    await tap(tester, 'Own');
    await tap(tester, 'Vinyl');
    await tester.ensureVisible(find.text('Add to shelf'));
    await tap(tester, 'Add to shelf');

    expect(shelf.addedTags, ['own', 'vinyl']);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpEntry(tester, tags: {'own', 'vinyl', 'jazz'});

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
