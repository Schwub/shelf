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
import 'package:shelf_app/shelf/copy_tags_page.dart';
import 'package:shelf_app/shelf/entry_page.dart';
import 'package:shelf_app/shelf/shelf.dart';
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

    /// Scrolls Anna's tags (a long tree) until [text] shows.
    Future<Finder> inTags(WidgetTester tester, String text) async {
      final f = find.text(text);
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find
            .descendant(
              of: find.byType(CopyTagsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      return f;
    }

    Future<void> addFromAnna(WidgetTester tester, String title) async {
      await openAnna(tester);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to my shelf'));
      await tester.pumpAndSettle();
    }

    testWidgets('sets the tags you have and copies their track list', (
      tester,
    ) async {
      await addFromAnna(tester, 'Kid A');

      expect(
        find.text("Own and Listened are set like Anna's."),
        findsOneWidget,
      );
      expect(find.text("Added from Anna's shelf"), findsOneWidget);
      expect(
        find.text('Copy them to your tags? You can edit them later.'),
        findsNothing,
        reason: 'no tags missing',
      );
      await tester.tap(find.text('Add to shelf'));
      await tester.pumpAndSettle();

      expect(shelf.addedTags, unorderedEquals(['own', 'vinyl', 'listened']));
      expect(shelf.addedFrom, (userId: 'anna', name: 'Anna'));
      expect(
        [for (final t in shelf.entries.first.tracks) t.title],
        ['Kid A', 'The National Anthem'],
      );
      expect(shelf.entries.first.tracks.any((t) => t.favorite), isFalse);
      expect(shelf.trackLookups, isEmpty);
    });

    testWidgets('offers their missing tags and copies them', (tester) async {
      await addFromAnna(tester, 'OK Computer');

      expect(find.text("Anna's tags"), findsOneWidget);
      expect(find.text('Into my Genre'), findsOneWidget, reason: 'same name');
      expect(
        await inTags(tester, 'New group'),
        findsOneWidget,
        reason: 'Label',
      );
      expect(shelf.trackLookups, ['mb-ok'], reason: 'no list of theirs');
      await tester.tap(find.text('Copy 2 tags'));
      await tester.pumpAndSettle();

      expect(find.text("Anna's tags"), findsNothing);
      expect(find.text('Shoegaze'), findsOneWidget);
      expect(find.text('Parlophone'), findsOneWidget);
      await tester.tap(find.text('Add to shelf'));
      await tester.pumpAndSettle();
      expect(
        shelf.addedTags,
        unorderedEquals(['own', 'listened', 'shoegaze', 'parlophone']),
      );
    });

    testWidgets('copies only the ticked tags', (tester) async {
      await addFromAnna(tester, 'OK Computer');

      await tester.tap(await inTags(tester, 'Parlophone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy 1 tag'));
      await tester.pumpAndSettle();

      expect(find.text('Shoegaze'), findsOneWidget);
      expect(shelf.groups.any((g) => g.name == 'Label'), isFalse);
    });

    testWidgets('Skip copies nothing', (tester) async {
      await addFromAnna(tester, 'OK Computer');

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Shoegaze'), findsNothing);
      expect(shelf.groups.any((g) => g.name == 'Label'), isFalse);
      await tester.tap(find.text('Add to shelf'));
      await tester.pumpAndSettle();
      expect(shelf.addedTags, unorderedEquals(['own', 'listened']));
    });

    testWidgets("a failed copy says so and can be tried again", (tester) async {
      shelf.failEdit = true;
      await addFromAnna(tester, 'OK Computer');

      await tester.tap(find.text('Copy 2 tags'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Couldn't copy the tags. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Shoegaze'), findsOneWidget);
      expect(find.text('Parlophone'), findsOneWidget);
    });

    testWidgets('copies stay when the add is cancelled', (tester) async {
      await addFromAnna(tester, 'OK Computer');
      await tester.tap(find.text('Copy 2 tags'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(shelf.entries.any((e) => e.album.musicbrainzId == 'mb-ok'), false);
      expect(shelf.groups.any((g) => g.name == 'Label'), isTrue);
    });

    testWidgets('adding again after a cancel starts from the copies', (
      tester,
    ) async {
      await addFromAnna(tester, 'OK Computer');
      await tester.tap(find.text('Copy 2 tags'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to my shelf'));
      await tester.pumpAndSettle();

      expect(find.text("Anna's tags"), findsNothing);
      await tester.tap(find.text('Add to shelf'));
      await tester.pumpAndSettle();
      expect(
        shelf.addedTags,
        unorderedEquals(['own', 'listened', 'shoegaze', 'parlophone']),
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

    testWidgets("Anna's tags stay open while they copy", (tester) async {
      await addFromAnna(tester, 'OK Computer');
      shelf.holdLoad = Completer();

      await tester.tap(find.text('Copy 2 tags'));
      await tester.pump();
      expect(find.text('Copying…'), findsOneWidget);
      await tester.binding.handlePopRoute(); // Back.
      await tester.pumpAndSettle();
      expect(find.text('Copying…'), findsOneWidget);

      shelf.holdLoad!.complete();
      shelf.holdLoad = null;
      await tester.pumpAndSettle();
      expect(find.text('Shoegaze'), findsOneWidget);
    });

    /// Anna keeps genres in "Style": Electronic (which the user has in
    /// Genre) and Shoegaze, both on OK Computer.
    void annaSortsByStyle() {
      final anna = shelf.friendShelves['anna']!;
      shelf.friendShelves['anna'] = Shelf(
        entries: [
          for (final e in anna.entries)
            e.id == 'ok'
                ? ShelfEntry(
                    id: e.id,
                    addedAt: e.addedAt,
                    album: e.album,
                    tagIds: const {'own', 'a-electronic', 'a-shoegaze2'},
                  )
                : e,
        ],
        allGroups: [
          ...suggestedGroups,
          const TagGroup(
            id: 'a-style',
            name: 'Style',
            exclusive: false,
            pickFromList: true,
            tags: [
              Tag(id: 'a-electronic', groupId: 'a-style', name: 'Electronic'),
              Tag(id: 'a-shoegaze2', groupId: 'a-style', name: 'Shoegaze'),
            ],
          ),
        ],
      );
    }

    testWidgets('a group goes into another of mine, and that is remembered', (
      tester,
    ) async {
      annaSortsByStyle();
      await addFromAnna(tester, 'OK Computer');
      expect(find.text('Copy 2 tags'), findsOneWidget, reason: 'new group');

      await tester.tap(await inTags(tester, 'New group'));
      await tester.pumpAndSettle();
      expect(find.text("Copy Anna's Style into"), findsOneWidget);
      await tester.tap(find.text('My Genre'));
      await tester.pumpAndSettle();

      expect(
        shelf.savedDestinations['a-style'],
        const Destination.into('genre'),
      );
      expect(find.text('Copy 1 tag'), findsOneWidget, reason: 'has Electronic');
      await tester.tap(find.text('Copy 1 tag'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to shelf'));
      await tester.pumpAndSettle();
      expect(
        shelf.addedTags,
        unorderedEquals(['own', 'electronic', 'shoegaze']),
        reason: 'both in my Genre',
      );
    });

    /// Opens the picker from Style's link, labelled [shown] (Style comes
    /// after Anna's own Genre).
    Future<void> chooseForStyle(
      WidgetTester tester,
      String shown,
      String choice,
    ) async {
      await tester.tap(find.text(shown).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice));
      await tester.pumpAndSettle();
    }

    testWidgets('a changed destination takes its old tags off the album', (
      tester,
    ) async {
      annaSortsByStyle();
      await addFromAnna(tester, 'OK Computer');
      await inTags(tester, 'Shoegaze');
      await chooseForStyle(tester, 'New group', 'My Genre');
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("See Anna's tags"));
      await tester.pumpAndSettle();
      await inTags(tester, 'Shoegaze');
      await chooseForStyle(tester, 'Into my Genre', "Don't copy this group");
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to shelf'));
      await tester.pumpAndSettle();

      expect(shelf.addedTags, ['own'], reason: 'Electronic came off again');
    });

    testWidgets('back keeps the destinations chosen', (tester) async {
      annaSortsByStyle();
      await addFromAnna(tester, 'OK Computer');
      await inTags(tester, 'Shoegaze');
      await chooseForStyle(tester, 'New group', 'My Genre');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CopyTagsPage), findsNothing);
      await tester.tap(find.text('Add to shelf'));
      await tester.pumpAndSettle();

      expect(shelf.addedTags, unorderedEquals(['own', 'electronic']));
    });

    testWidgets('a remembered destination is used at once', (tester) async {
      annaSortsByStyle();
      shelf.savedDestinations['a-style'] = const Destination.into('genre');
      await addFromAnna(tester, 'OK Computer');

      expect(await inTags(tester, 'Into my Genre'), findsNWidgets(2));
      expect(find.text('Copy 1 tag'), findsOneWidget);
    });

    testWidgets("a group can stay uncopied; Skip, then the link reopens it", (
      tester,
    ) async {
      annaSortsByStyle();
      await addFromAnna(tester, 'OK Computer');

      await tester.tap(await inTags(tester, 'New group'));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Don't copy this group"));
      await tester.pumpAndSettle();
      expect(find.text("Don't copy"), findsOneWidget);
      expect(find.text('Shoegaze'), findsNothing, reason: 'its tags fold away');
      expect(shelf.savedDestinations['a-style'], const Destination.nowhere());

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.byType(CopyTagsPage), findsNothing);
      await tester.tap(find.text("See Anna's tags"));
      await tester.pumpAndSettle();
      expect(find.byType(CopyTagsPage), findsOneWidget);
    });

    testWidgets("Anna's tags meet the accessibility guidelines", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await addFromAnna(tester, 'OK Computer');

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('a sub-tag is ticked and unticked with its parent', (
      tester,
    ) async {
      final anna = shelf.friendShelves['anna']!;
      shelf.friendShelves['anna'] = Shelf(
        entries: [
          for (final e in anna.entries)
            e.id == 'ok'
                ? ShelfEntry(
                    id: e.id,
                    addedAt: e.addedAt,
                    album: e.album,
                    tagIds: {...e.tagIds, 'a-first'},
                  )
                : e,
        ],
        allGroups: [
          ...anna.allGroups,
          const TagGroup(
            id: 'a-pressing',
            name: 'Pressing',
            exclusive: true,
            parentTagId: 'a-parlophone',
            tags: [Tag(id: 'a-first', groupId: 'a-pressing', name: 'First')],
          ),
        ],
      );
      await addFromAnna(tester, 'OK Computer');
      expect(find.text('Copy 3 tags'), findsOneWidget);

      await tester.tap(await inTags(tester, 'Parlophone'));
      await tester.pumpAndSettle();
      expect(find.text('Copy 1 tag'), findsOneWidget, reason: 'First went too');

      await tester.tap(await inTags(tester, 'First'));
      await tester.pumpAndSettle();
      expect(find.text('Copy 3 tags'), findsOneWidget, reason: 'and came back');
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
