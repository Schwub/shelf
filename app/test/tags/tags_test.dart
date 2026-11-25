import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/shelf_data.dart';
import 'package:shelf_app/tags/tags_page.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import '../shelf/fake_shelf.dart';

void main() {
  late FakeShelf shelf;

  final albums = [
    entry(
      '1',
      'OK Computer',
      tags: {'own', 'vinyl', 'alternative', 'art rock'},
    ),
    entry('2', 'Blue', tags: {'own', 'cd', 'jazz'}),
    entry('3', 'Promises', tags: {'want', 'jazz', 'ambient'}),
  ];

  Future<void> pumpTags(
    WidgetTester tester, {
    FakeShelf? fake,
    Brightness brightness = Brightness.dark,
  }) async {
    shelf = fake ?? FakeShelf(albums, filters: const [own, want]);
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(brightness),
        home: TagsPage(shelf: shelf),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openGroup(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  TagGroup groupWith(String id) => shelf.groups.firstWhere((g) => g.id == id);

  group('Tags', () {
    testWidgets('lists the top-level groups with type and tag count', (
      tester,
    ) async {
      await pumpTags(tester);

      expect(find.text('Collection'), findsOneWidget);
      expect(find.text('One per album · 2 tags'), findsNWidgets(2));
      expect(find.text('Several per album · 7 tags'), findsOneWidget);
      expect(find.text('Built-in'), findsNWidgets(2));
      // Sub-groups are edited from their tag.
      expect(find.text('Format'), findsNothing);
    });

    testWidgets('a hidden group is marked and says how to show it', (
      tester,
    ) async {
      final fake = FakeShelf(albums);
      fake.groups[2] = fake.groups[2].copyWith(hidden: true);
      await pumpTags(tester, fake: fake);

      expect(find.text('Listening · hidden'), findsOneWidget);
      expect(
        find.text('Open a hidden group to show it again.'),
        findsOneWidget,
      );
    });

    testWidgets('a load error offers to try again', (tester) async {
      await pumpTags(tester, fake: FakeShelf(albums)..failLoad = true);
      expect(find.text('Couldn’t load your tags'), findsOneWidget);

      await tapText(tester, 'Try again');
      expect(find.text('Collection'), findsOneWidget);
    });

    testWidgets('dragging a handle reorders the groups', (tester) async {
      await pumpTags(tester);

      final genre = find.byIcon(Icons.drag_handle).at(2);
      final gesture = await tester.startGesture(tester.getCenter(genre));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        [
          for (final g in shelf.groups)
            if (g.parentTagId == null) g.id,
        ],
        ['collection', 'genre', 'listening'],
      );
    });
  });

  group('New group', () {
    testWidgets('needs a name that is new', (tester) async {
      await pumpTags(tester);
      await tapText(tester, 'New group');

      await tapText(tester, 'Create group');
      expect(find.text('Give the group a name.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'genre');
      await tapText(tester, 'Create group');
      expect(
        find.text('You already have a group called “genre”.'),
        findsOneWidget,
      );
    });

    testWidgets('is created with its type and tags', (tester) async {
      await pumpTags(tester);
      await tapText(tester, 'New group');

      await tester.enterText(find.byType(TextField).first, 'Mood');
      await tapText(tester, 'One');
      for (final tag in ['Calm', 'Late night', 'calm']) {
        if (find.text('Add tag').evaluate().isNotEmpty) {
          await tapText(tester, 'Add tag');
        }
        await tester.enterText(find.byType(TextField).last, tag);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }
      expect(find.text('Mood already has “calm”.'), findsOneWidget);
      await tapText(tester, 'Create group');

      final mood = groupWith('mood');
      expect(mood.exclusive, isTrue);
      expect([for (final t in mood.tags) t.name], ['Calm', 'Late night']);
      expect(find.byType(TagsPage), findsOneWidget);
      expect(find.text('One per album · 2 tags'), findsNWidgets(3));
    });
  });

  group('A group', () {
    testWidgets('shows its tags with their albums', (tester) async {
      await pumpTags(tester);
      await openGroup(tester, 'Collection');

      expect(find.text('On 1 album'), findsOneWidget);
      expect(find.text('On 2 albums · opens Format'), findsOneWidget);
      expect(
        find.text('One per album. Built-in groups stay that way.'),
        findsOneWidget,
      );
      expect(find.text('Delete group'), findsNothing);
    });

    testWidgets('renames when the name is new', (tester) async {
      await pumpTags(tester);
      await openGroup(tester, 'Genre');

      await tester.enterText(find.byType(TextField).first, 'Listening');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        find.text('You already have a group called “Listening”.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).first, 'Style');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(groupWith('genre').name, 'Style');
      expect(find.text('Style'), findsWidgets);
    });

    testWidgets('can’t switch to one per album while albums have several', (
      tester,
    ) async {
      await pumpTags(tester);
      await openGroup(tester, 'Genre');

      await tapText(tester, 'One');

      expect(groupWith('genre').exclusive, isFalse);
      expect(
        find.textContaining('2 albums have more than one Genre tag'),
        findsOneWidget,
      );
      // The albums to change, which open their entry.
      await tapText(tester, 'Promises');
      expect(find.byType(EntryPage), findsOneWidget);
    });

    testWidgets('switches when every album has at most one', (tester) async {
      await pumpTags(
        tester,
        fake: FakeShelf([
          entry('1', 'Blue', tags: {'jazz'}),
        ]),
      );
      await openGroup(tester, 'Genre');

      await tapText(tester, 'One');

      expect(groupWith('genre').exclusive, isTrue);
    });

    testWidgets('adds a tag, but not one it has', (tester) async {
      await pumpTags(tester);
      await openGroup(tester, 'Genre');

      await tapText(tester, 'Add tag');
      await tester.enterText(find.byType(TextField).last, 'jazz');
      await tester.tap(find.bySemanticsLabel('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Genre already has “jazz”.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'Shoegaze');
      await tester.tap(find.bySemanticsLabel('Add'));
      await tester.pumpAndSettle();
      expect(groupWith('genre').tags.last.name, 'Shoegaze');
      expect(find.text('Shoegaze'), findsOneWidget);
    });

    testWidgets('reorders its tags', (tester) async {
      await pumpTags(tester);
      await openGroup(tester, 'Listening');

      final listened = find.byIcon(Icons.drag_handle).at(1);
      final gesture = await tester.startGesture(tester.getCenter(listened));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        [for (final t in groupWith('listening').tags) t.name],
        ['Listened', 'Want to listen'],
      );
    });

    testWidgets('a failed change can be tried again', (tester) async {
      await pumpTags(tester);
      await openGroup(tester, 'Listening');

      shelf.failEdit = true;
      await tapText(tester, 'Hide this group');
      expect(find.textContaining('Couldn’t save hiding the group'), findsOne);
      expect(groupWith('listening').hidden, isFalse);

      await tapText(tester, 'Try again');
      expect(groupWith('listening').hidden, isTrue);
      expect(find.textContaining('Couldn’t save'), findsNothing);
    });

    testWidgets('a built-in group can be hidden and shown', (tester) async {
      await pumpTags(tester);
      await openGroup(tester, 'Listening');

      await tapText(tester, 'Hide this group');
      expect(shelf.groups[2].hidden, isTrue);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Listening · hidden'), findsOneWidget);

      await openGroup(tester, 'Listening · hidden');
      await tapText(tester, 'Hide this group');
      expect(shelf.groups[2].hidden, isFalse);
    });

    testWidgets('delete asks first, with what goes too', (tester) async {
      await pumpTags(tester, fake: FakeShelf(albums, filters: const [own]));
      await openGroup(tester, 'Genre');

      await tapText(tester, 'Delete group');
      expect(find.text('Delete “Genre”?'), findsOneWidget);
      expect(
        find.text('Its 7 tags are on 3 albums and will be removed from them.'),
        findsOneWidget,
      );
      await tapText(tester, 'Cancel');
      expect(shelf.groups.any((g) => g.id == 'genre'), isTrue);

      await tapText(tester, 'Delete group');
      await tapText(tester, 'Delete');
      expect(shelf.groups.any((g) => g.id == 'genre'), isFalse);
      expect(shelf.entries.first.tagIds, {'own', 'vinyl'});
      expect(find.byType(TagsPage), findsOneWidget);
    });
  });

  group('A tag', () {
    Future<void> openTag(WidgetTester tester, String group, String tag) async {
      await openGroup(tester, group);
      await tester.tap(find.text(tag));
      await tester.pumpAndSettle();
    }

    testWidgets('is renamed in its sheet', (tester) async {
      await pumpTags(tester);
      await openTag(tester, 'Genre', 'Jazz');

      await tester.enterText(find.byType(TextField).last, 'pop');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Genre already has “pop”.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'Free jazz');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(groupWith('genre').tags.map((t) => t.name), contains('Free jazz'));
    });

    testWidgets('delete says how many albums, sub-group and filters', (
      tester,
    ) async {
      await pumpTags(
        tester,
        fake: FakeShelf(
          albums,
          filters: const [ShelfFilter(tagId: 'vinyl', label: 'Vinyl')],
          groups: [
            ...suggestedGroups.take(2),
            TagGroup(
              id: 'collection2',
              name: 'Shelf',
              exclusive: true,
              tags: [tag('collection2', 'Own')],
            ),
          ],
        ),
      );
      // "Own" outside the built-in group, with the Format sub-group under
      // the tag "own".
      await openTag(tester, 'Shelf', 'Own');
      await tapText(tester, 'Delete tag');

      expect(
        find.text(
          'It’s on 2 albums and will be removed from them. Its sub-group '
          '“Format” (4 tags) and 1 filter go too.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'Delete');
      expect(shelf.groups.any((g) => g.id == 'format'), isFalse);
      expect(shelf.filters, isEmpty);
    });

    testWidgets('a built-in tag can’t be deleted', (tester) async {
      await pumpTags(tester);
      await openTag(tester, 'Collection', 'Own');

      expect(find.text('Built-in tags can’t be deleted.'), findsOneWidget);
      expect(find.text('Delete tag'), findsNothing);
      expect(find.text('Edit sub-group “Format”'), findsOneWidget);
    });

    testWidgets('gets a sub-group, one level deep', (tester) async {
      await pumpTags(tester);
      await openTag(tester, 'Collection', 'Want');

      await tapText(tester, 'Add sub-group');
      expect(find.text('New sub-group'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Where');
      await tapText(tester, 'Create group');

      final where = groupWith('where');
      expect(where.parentTagId, 'want');
      expect(find.text('On 1 album · opens Where'), findsOneWidget);
    });

    testWidgets('in a sub-group has no sub-group of its own', (tester) async {
      await pumpTags(tester);
      await openTag(tester, 'Collection', 'Own');
      await tapText(tester, 'Edit sub-group “Format”');
      expect(find.textContaining('Sub-group under'), findsOneWidget);

      await tester.tap(find.text('Vinyl'));
      await tester.pumpAndSettle();
      expect(find.text('Delete tag'), findsOneWidget);
      expect(find.textContaining('sub-group'), findsNothing);
    });
  });

  testWidgets('Edit tags on an album keeps its draft', (tester) async {
    shelf = FakeShelf(albums);
    tester.view.physicalSize = const Size(412, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(Brightness.dark),
        home: EntryPage(
          entry: albums[1],
          shelf: shelf,
          groups: (await shelf.load()).groups,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tapText(tester, 'Listened');
    await tapText(tester, 'Edit tags');
    expect(find.byType(TagsPage), findsOneWidget);
    await openGroup(tester, 'Listening');
    await tester.enterText(find.byType(TextField).first, 'Heard');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(EntryPage), findsOneWidget);
    expect(find.text('Heard'), findsOneWidget);
    await tapText(tester, 'Save');
    expect(shelf.entries[1].tagIds, contains('listened'));
  });

  for (final brightness in Brightness.values) {
    testWidgets('meets the accessibility guidelines ($brightness)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpTags(tester, brightness: brightness);
      Future<void> check() async {
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }

      await check();
      await openGroup(tester, 'Collection');
      await check();
      semantics.dispose();
    });
  }
}
