import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/feed/feed_page.dart';
import 'package:shelf_app/feed/feed_repository.dart';
import 'package:shelf_app/friends/friend_album_page.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import '../friends/fake_friends.dart';
import '../shelf/fake_shelf.dart';
import 'fake_feed.dart';

FeedItem item(
  int i, {
  FeedKind kind = FeedKind.added,
  String friend = 'Anna',
  int? rating,
  DateTime? at,
}) => FeedItem(
  kind: kind,
  at: at ?? DateTime.now().subtract(Duration(hours: i)),
  entryId: 'e$i',
  friendId: friend.toLowerCase(),
  friendName: friend,
  album: Album(id: 'a$i', title: 'Album $i', artist: 'Artist $i'),
  rating: rating,
);

void main() {
  late FakeFeed feed;
  late FakeFriends friends;
  late FakeShelf shelf;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    feed = FakeFeed();
    friends = FakeFriends('Michael');
    shelf = FakeShelf([]);
  });

  Future<void> pumpFeed(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(AppTheme.tobacco.colors),
        home: FeedPage(feed: feed, friends: friends, shelf: shelf),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('friends\' adds and ratings, newest first', (tester) async {
    feed.items.addAll([
      item(2, at: DateTime.now().subtract(const Duration(hours: 2))),
      item(3, kind: FeedKind.rated, friend: 'Ben', rating: 9),
    ]);
    await pumpFeed(tester);

    expect(find.text('Anna added Album 2', findRichText: true), findsOneWidget);
    expect(find.text('Ben rated Album 3', findRichText: true), findsOneWidget);
    expect(find.text('2 h'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Artist 2')).dy,
      lessThan(tester.getTopLeft(find.text('Artist 3')).dy),
    );
  });

  testWidgets('without friends, the feed says how to get some', (tester) async {
    await pumpFeed(tester);

    expect(find.text('See what friends add and rate'), findsOneWidget);
  });

  testWidgets('with quiet friends, the feed names them', (tester) async {
    friends.friends
      ..add((id: 'anna', name: 'Anna', albums: 0))
      ..add((id: 'ben', name: 'Ben', albums: 0));
    await pumpFeed(tester);

    expect(find.text('Nothing yet'), findsOneWidget);
    expect(
      find.text('When Anna or Ben add or rate albums, they show here.'),
      findsOneWidget,
    );
  });

  testWidgets('a failed load can be tried again', (tester) async {
    feed
      ..items.add(item(1))
      ..error = Exception('offline');
    await pumpFeed(tester);
    expect(find.text("Couldn't load the feed"), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Anna added Album 1', findRichText: true), findsOneWidget);
  });

  testWidgets('more items load at the end, and can be tried again', (
    tester,
  ) async {
    feed.items.addAll([for (var i = 0; i < 35; i++) item(i)]);
    await pumpFeed(tester);
    expect(feed.pages, 1);

    feed.error = Exception('offline');
    final list = find.byType(Scrollable).first;
    await tester.fling(list, const Offset(0, -6000), 3000);
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load more"), findsOneWidget);
    expect(feed.pages, 2);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    await tester.fling(list, const Offset(0, -6000), 3000);
    await tester.pumpAndSettle();
    expect(
      find.text('Anna added Album 34', findRichText: true),
      findsOneWidget,
    );
    expect(feed.pages, 3);
  });

  testWidgets('an item opens the friend\'s album', (tester) async {
    feed.items.add(item(1));
    shelf.friendShelves['anna'] = Shelf(
      entries: [
        ShelfEntry(
          id: 'e1',
          album: const Album(id: 'a1', title: 'Album 1', artist: 'Artist 1'),
          rating: 6,
        ),
      ],
    );
    await pumpFeed(tester);

    await tester.tap(find.text('Anna added Album 1', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.byType(FriendAlbumPage), findsOneWidget);
    expect(find.text("Anna's rating"), findsOneWidget);
  });

  testWidgets('an album gone from the friend\'s shelf says so', (tester) async {
    feed.items.add(item(1));
    shelf.friendShelves['anna'] = Shelf(entries: []);
    await pumpFeed(tester);

    await tester.tap(find.text('Anna added Album 1', findRichText: true));
    await tester.pumpAndSettle();

    expect(
      find.text("That album isn't on Anna's shelf anymore"),
      findsOneWidget,
    );
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    feed.items.addAll([item(1, rating: 7), item(2, kind: FeedKind.rated)]);
    await pumpFeed(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  group('ago', () {
    final now = DateTime(2026, 11, 26, 12);
    for (final (at, text) in [
      (DateTime(2026, 11, 26, 11, 59, 30), 'just now'),
      (DateTime(2026, 11, 26, 11, 55), '5 min'),
      (DateTime(2026, 11, 26, 9), '3 h'),
      (DateTime(2026, 11, 25, 22), 'yesterday'),
      (DateTime(2026, 11, 23, 12), '3 days ago'),
      (DateTime(2026, 11, 12), '12 Nov'),
      (DateTime(2025, 12, 31), '31 Dec 2025'),
    ]) {
      test(text, () => expect(ago(at, now), text));
    }
  });
}
