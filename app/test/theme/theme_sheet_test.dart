import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/friends/pending_invite.dart';
import 'package:shelf_app/main.dart';
import 'package:shelf_app/settings/settings.dart';
import 'package:shelf_app/share/link_resolver.dart';
import 'package:shelf_app/share/shared_link_inbox.dart';
import 'package:shelf_app/theme/shelf_colors.dart';

import '../auth/fake_auth.dart';
import '../search/fake_search.dart';
import '../share/fake_links.dart';
import '../shelf/fake_shelf.dart';
import '../settings/fake_settings.dart';
import '../friends/fake_friends.dart';
import '../feed/fake_feed.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the menu changes the theme at once', (tester) async {
    final settings = Settings(FakeSettings());
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: FakeShelf([]),
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        pendingInvite: PendingInvite(),
        settings: settings,
        friends: FakeFriends('Michael'),
        feed: FakeFeed(),
      ),
    );
    await tester.pumpAndSettle();
    Color background() =>
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor ??
        Theme.of(tester.element(find.byType(Scaffold).first))
            .scaffoldBackgroundColor;
    expect(background(), ShelfColors.tobacco.bg);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evening'));
    await tester.pumpAndSettle();

    expect(settings.theme.value, AppTheme.evening);
    expect(background(), ShelfColors.evening.bg);
  });

  testWidgets('a theme saved on another device applies after sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: FakeShelf([]),
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        pendingInvite: PendingInvite(),
        settings: Settings(
          FakeSettings((theme: 'evening', list: null, sort: null)),
        ),
        friends: FakeFriends('Michael'),
        feed: FakeFeed(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(Scaffold).first))
          .scaffoldBackgroundColor,
      ShelfColors.evening.bg,
    );
  });

  testWidgets('the sheet covers the navigation bar', (tester) async {
    tester.view.physicalSize = const Size(412, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: FakeShelf([]),
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        pendingInvite: PendingInvite(),
        settings: Settings(FakeSettings()),
        friends: FakeFriends('Michael'),
        feed: FakeFeed(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Feed'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('See what friends add and rate'), findsNothing);
  });

  testWidgets('the sheet groups the themes in their families', (tester) async {
    final settings = Settings(FakeSettings());
    tester.view.physicalSize = const Size(412, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: FakeShelf([]),
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        pendingInvite: PendingInvite(),
        settings: settings,
        friends: FakeFriends('Michael'),
        feed: FakeFeed(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    for (final family in ['Woodgrain', 'Finishes', 'Classic']) {
      expect(find.text(family), findsOneWidget);
    }
    expect(
      tester.getTopLeft(find.text('Woodgrain')).dy,
      lessThan(tester.getTopLeft(find.text('Tobacco & copper')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Finishes')).dy,
      lessThan(tester.getTopLeft(find.text('Surf green')).dy),
    );

    await tester.tap(find.text('Surf green'));
    await tester.pumpAndSettle();
    expect(settings.theme.value, AppTheme.surfGreen);
  });
}
