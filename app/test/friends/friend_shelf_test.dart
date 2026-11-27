import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/friends/friend_shelf_page.dart';
import 'package:shelf_app/friends/pending_invite.dart';
import 'package:shelf_app/main.dart';
import 'package:shelf_app/settings/settings.dart';
import 'package:shelf_app/share/link_resolver.dart';
import 'package:shelf_app/share/shared_link_inbox.dart';
import 'package:shelf_app/shelf/friend_tags_page.dart';
import 'package:shelf_app/shelf/path_bar.dart';
import 'package:shelf_app/shelf/place_picker_page.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/widgets/filter_bar.dart';
import 'package:shelf_app/widgets/hidden_mark.dart';
import 'package:shelf_app/widgets/shelf_key.dart';
import 'package:shelf_app/widgets/text_link.dart';

import '../auth/fake_auth.dart';
import '../search/fake_search.dart';
import '../settings/fake_settings.dart';
import '../share/fake_links.dart';
import '../shelf/fake_shelf.dart';
import 'fake_friends.dart';
import '../feed/fake_feed.dart';

void main() {
  late FakeShelf shelf;
  late FakeFriends friends;
  late FakeSettings settings;

  final kidA = ShelfEntry(
    id: 'k',
    addedAt: added,
    album: const Album(
      id: 'a-kid',
      musicbrainzId: 'mb-kid',
      title: 'Kid A',
      artist: 'Radiohead',
      year: 2000,
    ),
    rating: 10,
    comment: 'Still the best headphone album.',
    tagIds: const {'own', 'vinyl', 'listened'},
    tracks: const [
      Track(position: 2, title: 'Kid A', favorite: true),
      Track(position: 3, title: 'The National Anthem'),
    ],
  );
  final blue = entry('2', 'Blue', rating: 9, tags: {'listened'});

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = FakeSettings();
    shelf = FakeShelf([entry('2', 'Blue', rating: 8)]);
    shelf.friendShelves['anna'] = Shelf(
      entries: [kidA, blue],
      allFilters: [
        ShelfFilter.tag('own', 'Own'),
        ShelfFilter.tag('listened', 'Listened'),
      ],
      allGroups: suggestedGroups,
    );
    friends = FakeFriends('Michael')
      ..friends.add((id: 'anna', name: 'Anna', albums: 2));
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: shelf,
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        pendingInvite: PendingInvite(),
        settings: Settings(settings),
        friends: friends,
        feed: FakeFeed(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> removeEntry(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Remove from shelf'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(EntryPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from shelf'));
    await tester.pumpAndSettle();
  }

  Future<void> openAnna(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Friends').last);
    await tester.pumpAndSettle();
    expect(find.text('2 albums'), findsOneWidget);
    await tester.tap(find.text('Anna'));
    await tester.pumpAndSettle();
  }

  testWidgets("a friend's shelf shows their albums and filters", (
    tester,
  ) async {
    await openAnna(tester);

    expect(find.text('Kid A'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Add album'), findsNothing, reason: 'read-only');

    await tester.tap(
      find
          .descendant(
            of: find.byType(FilterBar),
            matching: find.byType(ShelfKey),
          )
          .at(1),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(FriendShelfPage),
        matching: find.text('Blue'),
      ),
      findsNothing,
    );
  });

  testWidgets("a friend's shelf follows your sort", (tester) async {
    settings = FakeSettings((theme: null, list: null, sort: 'title'));
    await openAnna(tester);

    expect(
      tester.getTopLeft(find.text('Blue')).dx,
      lessThan(tester.getTopLeft(find.text('Kid A')).dx),
      reason: 'Blue before Kid A, though Kid A is newer',
    );
  });

  testWidgets("a friend's own filters work on their shelf", (tester) async {
    final anna = shelf.friendShelves['anna']!;
    shelf.friendShelves['anna'] = Shelf(
      entries: anna.entries,
      allGroups: anna.allGroups,
      allFilters: [
        ...anna.allFilters,
        const ShelfFilter(id: 'top', name: 'Top', label: 'Top', minRating: 10),
      ],
    );
    await openAnna(tester);

    // All, Own, Listened, Top.
    await tester.tap(
      find
          .descendant(
            of: find.byType(FilterBar),
            matching: find.byType(ShelfKey),
          )
          .at(3),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kid A'), findsOneWidget);
    expect(find.text('Blue'), findsNothing);
  });

  testWidgets("a friend's shelf can be sorted, and so is yours", (
    tester,
  ) async {
    await openAnna(tester);

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Blue')).dx,
      lessThan(tester.getTopLeft(find.text('Kid A')).dx),
    );
    expect(settings.saved?.sort, 'title');
  });

  testWidgets("an empty friend's shelf says so", (tester) async {
    shelf.friendShelves['anna'] = Shelf(entries: []);
    await openAnna(tester);

    expect(find.text("Anna hasn't added any albums yet"), findsOneWidget);
  });

  testWidgets("a friend's shelf can fail to load and be tried again", (
    tester,
  ) async {
    final anna = shelf.friendShelves.remove('anna')!;
    await openAnna(tester);
    expect(find.text("Couldn't load Anna's shelf"), findsOneWidget);

    shelf.friendShelves['anna'] = anna;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Kid A'), findsOneWidget);
  });

  testWidgets("a friend's album shows their rating, comment, tags, tracks", (
    tester,
  ) async {
    await openAnna(tester);
    await tester.tap(find.text('Kid A'));
    await tester.pumpAndSettle();

    expect(find.text("Anna's rating"), findsOneWidget);
    expect(find.text('Still the best headphone album.'), findsOneWidget);
    for (final tag in ['Own', 'Vinyl', 'Listened']) {
      expect(find.text(tag), findsOneWidget);
    }
    expect(find.text('2. Kid A'), findsOneWidget);
    expect(find.text('3. The National Anthem'), findsNothing);
  });

  testWidgets("Back leaves a friend's album", (tester) async {
    await openAnna(tester);
    await tester.tap(find.text('Kid A'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text("Anna's rating"), findsNothing);
    expect(find.byType(FriendShelfPage), findsOneWidget);
  });

  testWidgets("adding a friend's album puts it on My shelf", (tester) async {
    await openAnna(tester);
    await tester.tap(find.text('Kid A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to my shelf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to shelf'));
    await tester.pumpAndSettle();

    expect(find.text('Added to your shelf'), findsOneWidget);
    expect(shelf.entries.first.album.musicbrainzId, 'mb-kid');
    await tester.tap(find.text('Shelf'));
    await tester.pumpAndSettle();
    expect(find.text('Added mb-kid'), findsOneWidget, reason: 'reloaded');
  });

  testWidgets('an album already on your shelf opens your entry', (
    tester,
  ) async {
    await openAnna(tester);
    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open on your shelf'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets("removing from a friend's album waits for Undo", (tester) async {
    await openAnna(tester);
    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open on your shelf'));
    await tester.pumpAndSettle();

    await removeEntry(tester);
    expect(find.text('Removed from your shelf'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(shelf.removed, isEmpty);

    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open on your shelf'));
    await tester.pumpAndSettle();
    await removeEntry(tester);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(shelf.removed, ['2']);
  });

  testWidgets("a friend's album added by hand is added once, as a copy", (
    tester,
  ) async {
    shelf.friendShelves['anna'] = Shelf(
      entries: [
        ShelfEntry(
          id: 'd',
          addedAt: added,
          album: Album(id: 'anna-demo', title: 'Demo', artist: 'Anna'),
        ),
      ],
    );
    await openAnna(tester);
    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to my shelf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to shelf'));
    await tester.pumpAndSettle();
    expect(shelf.manual.single.title, 'Demo');

    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    expect(find.text('Open on your shelf'), findsOneWidget);
  });

  testWidgets('an album can be hidden from friends, and is marked', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(Switch),
      200,
      scrollable: find
          .descendant(
            of: find.byType(EntryPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(shelf.entries.single.hidden, isTrue);
    expect(find.byType(HiddenMark), findsOneWidget);
  });

  group('adding from a friend', () {
    /// Anna's OK Computer: Own, Listened, Shoegaze (a genre the user lacks)
    /// and Parlophone (a group the user lacks), without a track list.
    setUp(() {
      final ok = ShelfEntry(
        id: 'ok',
        addedAt: added,
        album: const Album(
          id: 'a-ok',
          musicbrainzId: 'mb-ok',
          title: 'OK Computer',
          artist: 'Radiohead',
          year: 1997,
        ),
        tagIds: const {'own', 'listened', 'a-shoegaze', 'a-parlophone'},
      );
      shelf.friendShelves['anna'] = Shelf(
        entries: [kidA, ok],
        allGroups: [
          for (final g in suggestedGroups)
            g.id == 'genre'
                ? g.withTag(
                    const Tag(
                      id: 'a-shoegaze',
                      groupId: 'genre',
                      name: 'Shoegaze',
                    ),
                  )
                : g,
          const TagGroup(
            id: 'a-label',
            name: 'Label',
            exclusive: false,
            pickFromList: true,
            tags: [
              Tag(id: 'a-parlophone', groupId: 'a-label', name: 'Parlophone'),
            ],
          ),
        ],
      );
    });

    Future<void> addFromAnna(WidgetTester tester, String title) async {
      await openAnna(tester);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to my shelf'));
      await tester.pumpAndSettle();
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    /// Taps the key that reads [label] to a screen reader ("Add Own").
    Future<void> tapKey(WidgetTester tester, String label) async {
      final key = find.byWidgetPredicate(
        (w) =>
            (w is ShelfKey && w.semanticLabel == label) ||
            (w is TextLink && w.semanticLabel == label),
      );
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pumpAndSettle();
    }

    /// Adds [title] from Anna and opens "Anna's tags".
    Future<void> annasTags(WidgetTester tester, String title) async {
      await addFromAnna(tester, title);
      await tapText(tester, 'Choose');
    }

    List<String> tagsIn(String groupId) => [
      for (final t in shelf.groups.firstWhere((g) => g.id == groupId).tags)
        t.name,
    ];

    /// Taps the part of a To path that reads [label] to a screen reader
    /// ("Change Metal, new for Black metal").
    Future<void> tapPart(WidgetTester tester, String label) async {
      final chip = find.byWidgetPredicate(
        (w) => w is PathChip && w.part.semanticLabel == label,
      );
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    /// Anna's OK Computer with [tagIds], and Subgenre › Free jazz, Bebop
    /// under her Jazz, Pressing › First under her Parlophone.
    void annaNests(Set<String> tagIds) {
      final anna = shelf.friendShelves['anna']!;
      shelf.friendShelves['anna'] = Shelf(
        entries: [
          for (final e in anna.entries)
            e.id == 'ok'
                ? ShelfEntry(
                    id: e.id,
                    addedAt: e.addedAt,
                    album: e.album,
                    tagIds: tagIds,
                  )
                : e,
        ],
        allGroups: [
          ...anna.allGroups,
          const TagGroup(
            id: 'a-sub',
            name: 'Subgenre',
            exclusive: false,
            parentTagId: 'jazz',
            tags: [
              Tag(id: 'a-free', groupId: 'a-sub', name: 'Free jazz'),
              Tag(id: 'a-bebop', groupId: 'a-sub', name: 'Bebop'),
            ],
          ),
          const TagGroup(
            id: 'a-pressing',
            name: 'Pressing',
            exclusive: true,
            parentTagId: 'a-parlophone',
            tags: [Tag(id: 'a-first', groupId: 'a-pressing', name: 'First')],
          ),
        ],
      );
    }

    testWidgets('the entry says how many tags she has, none added', (
      tester,
    ) async {
      await addFromAnna(tester, 'OK Computer');

      expect(find.text("Anna's tags"), findsOneWidget);
      expect(find.text('4 on this album · none added yet'), findsOneWidget);
      expect(find.text("Added from Anna's shelf"), findsOneWidget);
      expect(shelf.trackLookups, ['mb-ok'], reason: 'no list of theirs');
      await tapText(tester, 'Add to shelf');

      expect(shelf.addedTags, isEmpty);
    });

    testWidgets('one bar when her path is mine, From and To when not', (
      tester,
    ) async {
      await annasTags(tester, 'OK Computer');

      expect(find.byType(FriendTagsPage), findsOneWidget);
      expect(find.text('= mine'), findsNWidgets(2), reason: 'Own, Listened');
      expect(find.text('FROM'), findsNWidgets(2), reason: 'the two new ones');
      expect(find.text('TO'), findsNWidgets(2));
    });

    testWidgets('Add sets my tag with its parent; Undo takes it off', (
      tester,
    ) async {
      await annasTags(tester, 'Kid A');

      await tapKey(tester, 'Add Vinyl');
      expect(find.text('On the album'), findsNWidgets(2), reason: 'Own too');
      await tapKey(tester, 'Add Listened');
      await tapKey(tester, 'Undo Listened');
      await tapText(tester, 'Done');

      expect(find.text('3 on this album · 2 added'), findsOneWidget);
      await tapText(tester, 'Add to shelf');
      expect(shelf.addedTags, unorderedEquals(['own', 'vinyl']));
      expect(shelf.addedFrom, (userId: 'anna', name: 'Anna'));
      expect(
        [for (final t in shelf.entries.first.tracks) t.title],
        ['Kid A', 'The National Anthem'],
      );
      expect(shelf.entries.first.tracks.any((t) => t.favorite), isFalse);
      expect(shelf.trackLookups, isEmpty);
    });

    testWidgets('the ones I have are one tap away', (tester) async {
      await annasTags(tester, 'Kid A');

      await tapText(tester, 'Add 3 = mine');
      expect(find.text('Add 3 = mine'), findsNothing);
      await tester.binding.handlePopRoute(); // Back, like Done.
      await tester.pumpAndSettle();
      await tapText(tester, 'Add to shelf');

      expect(shelf.addedTags, unorderedEquals(['own', 'vinyl', 'listened']));
    });

    testWidgets('Copy creates a tag I lack in my group of that name', (
      tester,
    ) async {
      await annasTags(tester, 'OK Computer');

      await tapKey(tester, 'Copy Shoegaze');

      expect(tagsIn('genre'), contains('Shoegaze'));
      await tapText(tester, 'Done');
      await tapText(tester, 'Add to shelf');
      expect(shelf.addedTags, ['shoegaze']);
    });

    testWidgets('Copy brings her structure when I lack the group', (
      tester,
    ) async {
      annaNests(const {'a-parlophone', 'a-first'});
      await annasTags(tester, 'OK Computer');

      await tapKey(tester, 'Copy First');
      await tapText(tester, 'Done');
      await tapText(tester, 'Add to shelf');

      expect(shelf.addedTags, unorderedEquals(['parlophone', 'first']));
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Label').pickFromList,
        true,
      );
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Pressing').parentTagId,
        'parlophone',
      );
    });

    testWidgets('Undo also takes off the parents the line brought', (
      tester,
    ) async {
      annaNests(const {'a-first'});
      await annasTags(tester, 'OK Computer');

      await tapKey(tester, 'Copy First');
      await tapKey(tester, 'Undo First');
      await tapText(tester, 'Done');
      await tapText(tester, 'Add to shelf');

      expect(shelf.addedTags, isEmpty, reason: 'Parlophone came off too');
    });

    group('changing a part of where it lands', () {
      /// Anna's Genre › Jazz › Subgenre › Free jazz; I have Genre › Jazz
      /// and no Subgenre.
      Future<void> freeJazz(WidgetTester tester) async {
        annaNests(const {'a-free'});
        await annasTags(tester, 'OK Computer');
      }

      testWidgets('the tag: one of my tags instead, remembered once added', (
        tester,
      ) async {
        await freeJazz(tester);

        await tapPart(tester, 'Change Free jazz, new for Free jazz');
        expect(find.text("like Anna's"), findsOneWidget);
        await tapText(tester, 'Genre › Jazz');
        await tapText(tester, 'Done');

        expect(shelf.copyTargetsSaved, isEmpty, reason: 'not added yet');
        await tapKey(tester, 'Add Free jazz');
        expect(shelf.copyTargetsSaved, {'a-free': const OntoTag('jazz')});
        await tapText(tester, 'Done');
        await tapText(tester, 'Add to shelf');
        expect(shelf.addedTags, ['jazz']);
        expect(shelf.groups.any((g) => g.name == 'Subgenre'), isFalse);
      });

      testWidgets('a sub-group: flat into my group, the rest comes along', (
        tester,
      ) async {
        await freeJazz(tester);

        await tapPart(tester, 'Change Subgenre, new for Free jazz');
        await tapText(tester, 'no sub-group');
        await tapText(tester, '+ 1 more tag from Subgenre');
        await tapText(tester, 'Done');
        await tapText(tester, 'Copy 2 tags');

        expect(find.text('Check'), findsOneWidget);
        expect(find.text('+ 1 MORE TAG, NOT ON THIS ALBUM'), findsOneWidget);
        await tapText(tester, 'Copy 2 tags');

        expect(tagsIn('genre'), containsAll(['Free jazz', 'Bebop']));
        expect(shelf.groups.any((g) => g.name == 'Subgenre'), isFalse);
        expect(shelf.copyTargetsSaved, {'a-sub': const IntoGroup('genre')});
        await tapText(tester, 'Done');
        await tapText(tester, 'Add to shelf');
        expect(shelf.addedTags, ['free jazz'], reason: 'Bebop only copied');
      });

      testWidgets('a sub-group: under another of my tags, from the browser', (
        tester,
      ) async {
        await freeJazz(tester);

        await tapPart(tester, 'Change Subgenre, new for Free jazz');
        await tapText(tester, 'Another place…');
        expect(find.byType(PlacePickerPage), findsOneWidget);
        await tapText(tester, 'Genre');
        await tapText(tester, 'Ambient');
        await tapText(tester, 'Subgenre under Ambient');
        expect(find.text('Genre › Ambient › Subgenre'), findsOneWidget);
        await tapText(tester, 'Done');
        await tapKey(tester, 'Copy Free jazz');

        expect(
          shelf.groups.firstWhere((g) => g.name == 'Subgenre').parentTagId,
          'ambient',
        );
        expect(shelf.copyTargetsSaved, {'a-sub': const UnderTag('ambient')});
        await tapText(tester, 'Done');
        await tapText(tester, 'Add to shelf');
        expect(shelf.addedTags, unorderedEquals(['ambient', 'free jazz']));
      });

      testWidgets('a remembered place is used, and can go back to hers', (
        tester,
      ) async {
        shelf.copyTargetsSaved['a-free'] = const OntoTag('ambient');
        await freeJazz(tester);

        expect(find.text('Ambient'), findsOneWidget);
        await tapPart(tester, 'Change Ambient for Free jazz');
        await tapText(tester, "like Anna's");
        await tapText(tester, 'Done');
        await tapKey(tester, 'Copy Free jazz');

        expect(shelf.copyTargetsSaved, isEmpty);
        expect(
          shelf.groups.firstWhere((g) => g.name == 'Subgenre').parentTagId,
          'jazz',
        );
      });

      testWidgets('a tag pushed out of a one-per-album group is named', (
        tester,
      ) async {
        await annasTags(tester, 'OK Computer');
        await tapKey(tester, 'Add Own');

        await tapPart(tester, 'Change Listened for Listened');
        await tapText(tester, 'Another place…');
        await tapText(tester, 'My tags');
        await tapText(tester, 'Collection');
        await tapText(tester, 'Listened into Collection');
        await tapText(tester, 'Done');
        await tapKey(tester, 'Copy Listened');

        expect(find.text('Own: off, one per album'), findsOneWidget);
      });

      testWidgets('the sheet and the browser are accessible', (tester) async {
        final semantics = tester.ensureSemantics();
        await freeJazz(tester);
        await tapPart(tester, 'Change Subgenre, new for Free jazz');
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));

        await tapText(tester, 'Another place…');
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
      });
    });

    testWidgets("a failed copy says so and can be tried again", (tester) async {
      shelf.failEdit = true;
      await annasTags(tester, 'OK Computer');

      await tapKey(tester, 'Copy Parlophone');
      expect(
        find.text(
          "Couldn't copy the tag. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      await tapKey(tester, 'Copy Parlophone');

      expect(shelf.groups.any((g) => g.name == 'Label'), isTrue);
      await tapText(tester, 'Done');
      await tapText(tester, 'Add to shelf');
      expect(shelf.addedTags, ['parlophone']);
    });

    testWidgets('copies stay when the add is cancelled', (tester) async {
      await annasTags(tester, 'OK Computer');
      await tapKey(tester, 'Copy Shoegaze');
      await tapText(tester, 'Done');
      await tapText(tester, 'Cancel');
      await tapText(tester, 'Discard');

      expect(shelf.entries.any((e) => e.album.musicbrainzId == 'mb-ok'), false);
      await tapText(tester, 'Add to my shelf');
      await tapText(tester, 'Choose');
      expect(find.text('Add 3 = mine'), findsOneWidget);
    });

    testWidgets("adding says so when your shelf doesn't load", (tester) async {
      await openAnna(tester);
      await tester.tap(find.text('OK Computer'));
      await tester.pumpAndSettle();
      shelf.failLoad = true;

      await tester.tap(find.text('Add to my shelf'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load your shelf. Try again."), findsOneWidget);
      expect(find.text('Add to shelf'), findsNothing);
    });

    testWidgets("Anna's tags meet the accessibility guidelines", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await addFromAnna(tester, 'OK Computer');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      await tapText(tester, 'Choose');
      await tapKey(tester, 'Add Own');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  });

  testWidgets("an album added from a friend says so later", (tester) async {
    shelf.entries[0] = ShelfEntry(
      id: '2',
      addedAt: added,
      album: Album(id: 'a2', title: 'Blue', artist: 'Joni Mitchell'),
      addedFromName: 'Anna',
    );
    await pumpApp(tester);
    await tester.tap(find.text('Blue'));
    await tester.pumpAndSettle();

    expect(find.text("Added from Anna's shelf"), findsOneWidget);
  });

  testWidgets("a friend's shelf and album meet the accessibility guidelines", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openAnna(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.tap(find.text('Kid A'));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
