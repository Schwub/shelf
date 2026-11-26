import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/home/tab_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/friends/pending_invite.dart';
import 'package:shelf_app/main.dart';
import 'package:shelf_app/settings/settings.dart';
import 'package:shelf_app/share/link_resolver.dart';
import 'package:shelf_app/share/shared_link_inbox.dart';

import '../auth/fake_auth.dart';
import '../search/fake_search.dart';
import '../settings/fake_settings.dart';
import '../share/fake_links.dart';
import '../shelf/fake_shelf.dart';
import 'fake_friends.dart';
import '../feed/fake_feed.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpApp(WidgetTester tester, FakeFriends friends) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: FakeShelf([entry('1', 'Blue')]),
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        pendingInvite: PendingInvite(),
        settings: Settings(FakeSettings()),
        friends: friends,
        feed: FakeFeed(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field() => find.byType(TextField);

  testWidgets('without a name, Your name comes before the shelf', (
    tester,
  ) async {
    final friends = FakeFriends();
    await pumpApp(tester, friends);
    expect(find.text('What should friends call you?'), findsOneWidget);
    expect(find.text('My shelf'), findsNothing);

    await tester.enterText(field(), '  Michael ');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(friends.name, 'Michael');
    expect(find.text('My shelf'), findsOneWidget);
  });

  testWidgets('an empty or too long name says so', (tester) async {
    final friends = FakeFriends();
    await pumpApp(tester, friends);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter a name friends will recognise.'), findsOneWidget);

    await tester.enterText(field(), 'x' * 41);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Use at most 40 characters.'), findsOneWidget);
    expect(friends.name, isNull);
  });

  testWidgets('the limit counts characters, as the database does', (
    tester,
  ) async {
    final friends = FakeFriends();
    await pumpApp(tester, friends);

    await tester.enterText(field(), '🎵' * 40);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(friends.name, '🎵' * 40);
  });

  testWidgets('a failed save says so and can be tried again', (tester) async {
    final friends = FakeFriends();
    await pumpApp(tester, friends);
    await tester.enterText(field(), 'Michael');
    friends.error = Exception('offline');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Couldn't save your name. Check your connection and try again.",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('My shelf'), findsOneWidget);
  });

  testWidgets('loading the name can fail and be tried again', (tester) async {
    final friends = FakeFriends('Michael')..error = Exception('offline');
    await pumpApp(tester, friends);
    expect(find.text("Couldn't load your account"), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('My shelf'), findsOneWidget);
  });

  testWidgets('the name changes from Friends', (tester) async {
    final friends = FakeFriends('Michael');
    await pumpApp(tester, friends);
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('Michael'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.text('Michael'), findsOneWidget, reason: 'in the field');
    expect(find.byType(ShelfTabBar), findsNothing, reason: 'full screen');
    await tester.enterText(field(), 'Mike');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(friends.name, 'Mike');
    expect(find.text('Mike'), findsOneWidget);
    expect(find.byType(ShelfTabBar), findsOneWidget);
  });

  testWidgets('Your name meets the accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, FakeFriends());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
