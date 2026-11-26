import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/main.dart';
import 'package:shelf_app/settings/settings.dart';
import 'package:shelf_app/share/link_resolver.dart';
import 'package:shelf_app/share/shared_link_inbox.dart';

import 'auth/fake_auth.dart';
import 'shelf/fake_shelf.dart';
import 'search/fake_search.dart';
import 'share/fake_links.dart';
import 'settings/fake_settings.dart';
import 'friends/fake_friends.dart';

void main() {
  testWidgets('starts on the shelf when signed in', (tester) async {
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: FakeShelf([entry('1', 'Blue')]),
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        settings: Settings(FakeSettings()),
        friends: FakeFriends('Michael'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My shelf'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
  });

  testWidgets('starts on sign-in when signed out', (tester) async {
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(),
        shelf: FakeShelf([]),
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        settings: Settings(FakeSettings()),
        friends: FakeFriends('Michael'),
      ),
    );

    expect(find.text('Send sign-in code'), findsOneWidget);
  });

  testWidgets('a link shared while signed out opens after signing in', (
    tester,
  ) async {
    final auth = FakeAuth();
    final links = FakeLinks(const NotAnAlbum('track'));
    final shared = Uri.parse('https://open.spotify.com/track/x');
    await tester.pumpWidget(
      ShelfApp(
        auth: auth,
        shelf: FakeShelf([]),
        search: FakeSearch({}),
        links: links,
        inbox: SharedLinkInbox(Stream.value(shared)),
        settings: Settings(FakeSettings()),
        friends: FakeFriends('Michael'),
      ),
    );
    await tester.pumpAndSettle();
    expect(links.links, isEmpty);

    await auth.verifyCode('a@example.com', '123456');
    await tester.pumpAndSettle();

    expect(links.links, [shared]);
    expect(find.text('That’s a track, not an album'), findsOneWidget);
  });
}
