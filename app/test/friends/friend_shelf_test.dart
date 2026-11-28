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
import 'package:shelf_app/shelf/friend_suggestions.dart';
import 'package:shelf_app/shelf/place_picker_page.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/shelf/tag_section.dart';
import 'package:shelf_app/widgets/filter_bar.dart';
import 'package:shelf_app/widgets/hidden_mark.dart';
import 'package:shelf_app/widgets/shelf_key.dart';

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

    /// One of Anna's tags offered as a faint key, by what it reads.
    Finder ghost(String label) =>
        find.byWidgetPredicate((w) => w is GhostChip && w.label == label);

    Future<void> tapGhost(WidgetTester tester, String label) async {
      await tester.ensureVisible(ghost(label));
      await tester.pumpAndSettle();
      await tester.tap(ghost(label));
      await tester.pumpAndSettle();
    }

    Future<void> pressGhost(WidgetTester tester, String label) async {
      await tester.ensureVisible(ghost(label));
      await tester.pumpAndSettle();
      await tester.longPress(ghost(label));
      await tester.pumpAndSettle();
    }

    List<String> tagsIn(String groupId) => [
      for (final t in shelf.groups.firstWhere((g) => g.id == groupId).tags)
        t.name,
    ];

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

    testWidgets('her tags are offered inside my own tags; none is set', (
      tester,
    ) async {
      await addFromAnna(tester, 'OK Computer');

      expect(find.text("Anna's tags"), findsOneWidget);
      expect(find.text("Added from Anna's shelf"), findsOneWidget);
      expect(ghost('Shoegaze'), findsOneWidget, reason: 'in my Genre');
      expect(find.text('New from Anna'), findsOneWidget);
      expect(ghost('Label › Parlophone'), findsOneWidget);
      expect(ghost('Own'), findsNothing, reason: 'my key has a dot instead');
      expect(tester.widget<TagSection>(find.byType(TagSection)).suggested, {
        'own',
        'listened',
      });
      expect(shelf.trackLookups, ['mb-ok'], reason: 'no list of theirs');
      await tapText(tester, 'Add to shelf');

      expect(shelf.addedTags, isEmpty);
    });

    testWidgets('a tap takes a tag I have, with its parent', (tester) async {
      await addFromAnna(tester, 'Kid A');

      await tapGhost(tester, 'Own › Format › Vinyl');

      expect(ghost('Own › Format › Vinyl'), findsNothing);
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
      await addFromAnna(tester, 'Kid A');

      await tapText(tester, 'Add the 3 I have');

      expect(find.text("Anna's tags"), findsNothing, reason: 'all taken');
      await tapText(tester, 'Add to shelf');
      expect(shelf.addedTags, unorderedEquals(['own', 'vinyl', 'listened']));
    });

    testWidgets('a tag I lack is created in my group of that name', (
      tester,
    ) async {
      await addFromAnna(tester, 'OK Computer');

      await tapGhost(tester, 'Shoegaze');

      expect(tagsIn('genre'), contains('Shoegaze'));
      await tapText(tester, 'Add to shelf');
      expect(shelf.addedTags, ['shoegaze']);
    });

    testWidgets('a tag with no place of mine brings her structure', (
      tester,
    ) async {
      annaNests(const {'a-first'});
      await addFromAnna(tester, 'OK Computer');

      await tapGhost(tester, 'Label › Parlophone › Pressing › First');
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

    group('a long press sends it elsewhere', () {
      /// Anna's Genre › Jazz › Subgenre › Free jazz; I have Genre › Jazz
      /// and no Subgenre.
      Future<void> freeJazz(WidgetTester tester) async {
        annaNests(const {'a-free'});
        await addFromAnna(tester, 'OK Computer');
        await pressGhost(tester, 'Jazz › Subgenre › Free jazz');
      }

      testWidgets('flat into my group; remembered once taken', (tester) async {
        await freeJazz(tester);

        expect(find.text('FROM'), findsOneWidget);
        await tapText(tester, 'no sub-group');
        await tapText(tester, 'Done');

        expect(ghost('Free jazz'), findsOneWidget);
        expect(shelf.copyTargetsSaved, isEmpty, reason: 'not taken yet');
        await tapGhost(tester, 'Free jazz');
        expect(tagsIn('genre'), contains('Free jazz'));
        expect(shelf.groups.any((g) => g.name == 'Subgenre'), isFalse);
        expect(shelf.copyTargetsSaved, {'a-sub': const IntoGroup('genre')});
        await tapText(tester, 'Add to shelf');
        expect(shelf.addedTags, ['free jazz']);
      });

      testWidgets('the rest of her group can come along, after a check', (
        tester,
      ) async {
        await freeJazz(tester);
        await tapText(tester, 'no sub-group');
        await tapText(tester, '+ 1 more tag from Subgenre');
        await tapText(tester, 'Done');

        await tapGhost(tester, 'Free jazz');
        expect(find.text('Check'), findsOneWidget);
        expect(find.text('+ 1 MORE TAG, COPIED ONLY'), findsOneWidget);
        await tapText(tester, 'Copy 2 tags');

        expect(tagsIn('genre'), containsAll(['Free jazz', 'Bebop']));
        await tapText(tester, 'Add to shelf');
        expect(shelf.addedTags, ['free jazz'], reason: 'Bebop only copied');
      });

      testWidgets('under another of my tags, from the browser', (tester) async {
        await freeJazz(tester);

        await tapText(tester, 'Another place…');
        expect(find.byType(PlacePickerPage), findsOneWidget);
        await tapText(tester, 'Genre');
        await tapText(tester, 'Ambient');
        await tapText(tester, 'Subgenre under Ambient');
        await tapText(tester, 'Done');
        await tapGhost(tester, 'Ambient › Subgenre › Free jazz');

        expect(
          shelf.groups.firstWhere((g) => g.name == 'Subgenre').parentTagId,
          'ambient',
        );
        expect(shelf.copyTargetsSaved, {'a-sub': const UnderTag('ambient')});
        await tapText(tester, 'Add to shelf');
        expect(shelf.addedTags, unorderedEquals(['ambient', 'free jazz']));
      });

      testWidgets('the sheet and the browser are accessible', (tester) async {
        final semantics = tester.ensureSemantics();
        await freeJazz(tester);
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

    testWidgets('a remembered place is used, and can go back to hers', (
      tester,
    ) async {
      shelf.copyTargetsSaved['a-free'] = const OntoTag('ambient');
      annaNests(const {'a-free'});
      await addFromAnna(tester, 'OK Computer');

      expect(ghost('Ambient'), findsOneWidget);
      await pressGhost(tester, 'Ambient');
      await tapText(tester, "like Anna's");
      await tapText(tester, 'Done');
      await tapGhost(tester, 'Jazz › Subgenre › Free jazz');

      expect(shelf.copyTargetsSaved, isEmpty);
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Subgenre').parentTagId,
        'jazz',
      );
    });

    testWidgets('a tag sent onto one of my keys can still be sent back', (
      tester,
    ) async {
      shelf.copyTargetsSaved['a-shoegaze'] = const OntoTag('want');
      await addFromAnna(tester, 'OK Computer');

      expect(ghost('Want'), findsOneWidget, reason: 'faint, not just a dot');
      await tapGhost(tester, 'Want');
      await tapText(tester, 'Add to shelf');
      expect(shelf.addedTags, ['want']);
    });

    testWidgets("a failed copy says so and can be tried again", (tester) async {
      shelf.failEdit = true;
      await addFromAnna(tester, 'OK Computer');

      await tapGhost(tester, 'Label › Parlophone');
      expect(
        find.text(
          "Couldn't copy the tag. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      await tapGhost(tester, 'Label › Parlophone');

      expect(shelf.groups.any((g) => g.name == 'Label'), isTrue);
      await tapText(tester, 'Add to shelf');
      expect(shelf.addedTags, ['parlophone']);
    });

    testWidgets('copies stay when the add is cancelled', (tester) async {
      await addFromAnna(tester, 'OK Computer');
      await tapGhost(tester, 'Shoegaze');
      await tapText(tester, 'Cancel');
      await tapText(tester, 'Discard');

      expect(shelf.entries.any((e) => e.album.musicbrainzId == 'mb-ok'), false);
      await tapText(tester, 'Add to my shelf');
      expect(
        tester.widget<GhostChip>(ghost('Shoegaze')).isNew,
        isFalse,
        reason: 'mine now',
      );
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

    testWidgets("her tags on the entry meet the accessibility guidelines", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await addFromAnna(tester, 'OK Computer');

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
