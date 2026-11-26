import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/home/tab_bar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/friends/friend_shelf_page.dart';
import 'package:shelf_app/friends/friends_repository.dart';
import 'package:shelf_app/friends/invite_links.dart';
import 'package:shelf_app/friends/invite_sheet.dart';
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
  late FakeFriends friends;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    friends = FakeFriends('Michael');
    friends.codes['ANNA2345'] = (
      status: InviteStatus.valid,
      inviterId: 'anna',
      inviterName: 'Anna',
    );
  });

  /// The app on the Friends tab (or wherever [pending] leads).
  Future<void> pumpFriends(
    WidgetTester tester, {
    PendingInvite? pending,
  }) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: FakeShelf([]),
        search: FakeSearch({}),
        links: FakeLinks(UnsupportedLink()),
        inbox: SharedLinkInbox(const Stream.empty()),
        pendingInvite: pending ?? PendingInvite(),
        settings: Settings(FakeSettings()),
        friends: friends,
        feed: FakeFeed(),
      ),
    );
    await tester.pumpAndSettle();
    if (pending == null) {
      await tester.tap(find.text('Friends').last);
      await tester.pumpAndSettle();
    }
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.tap(find.text('Enter code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('no friends yet offers to invite or enter a code', (
    tester,
  ) async {
    await pumpFriends(tester);

    expect(find.text('No friends yet'), findsOneWidget);
    expect(find.text('Invite a friend'), findsOneWidget);
    expect(find.text('Have a code? Enter it'), findsOneWidget);
  });

  testWidgets('an invite shows its link and code, then waits', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await pumpFriends(tester);

    await tester.tap(find.text('Invite a friend'));
    await tester.pumpAndSettle();
    expect(find.text('K7Q2-M9XA'), findsOneWidget);
    expect(find.textContaining('/invite/K7Q2-M9XA'), findsOneWidget);
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(find.text('Link copied'), findsOneWidget);
    expect(copied, endsWith('/invite/K7Q2-M9XA'));

    await tester.tapAt(const Offset(200, 100)); // the barrier closes it
    await tester.pumpAndSettle();
    expect(find.text('Invites waiting'), findsOneWidget);
    expect(find.text('K7Q2-M9XA'), findsOneWidget);
    expect(find.text('Expires in 7 days · works once'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Invite cancelled'), findsOneWidget);
    expect(friends.invites, isEmpty);
    expect(find.text('No friends yet'), findsOneWidget);
  });

  testWidgets('a failed invite says so', (tester) async {
    await pumpFriends(tester);
    friends.error = Exception('offline');

    await tester.tap(find.text('Invite a friend'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't create an invite. Try again."), findsOneWidget);
  });

  testWidgets('a code, however typed, leads to Accept and a friend', (
    tester,
  ) async {
    await pumpFriends(tester);

    await enterCode(tester, ' anna-2345 ');
    expect(find.text('Anna invited you'), findsOneWidget);
    expect(find.byType(ShelfTabBar), findsNothing, reason: 'full screen');

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('You and Anna are friends'), findsOneWidget);
    expect(find.byType(FriendShelfPage), findsOneWidget, reason: 'opened');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsOneWidget, reason: 'in the list');
  });

  testWidgets('a wrong code says so', (tester) async {
    await pumpFriends(tester);

    await enterCode(tester, 'NOPE-NOPE');

    expect(
      find.text("That code isn't right. Check it and try again."),
      findsOneWidget,
    );
  });

  for (final (status, title) in [
    (InviteStatus.gone, 'This invite has expired'),
    (InviteStatus.own, "That's your own invite"),
    (InviteStatus.friends, 'You and Anna are already friends'),
  ]) {
    testWidgets('an invite that is ${status.name} says so', (tester) async {
      friends.codes['ANNA2345'] = (
        status: status,
        inviterId: 'anna',
        inviterName: 'Anna',
      );
      await pumpFriends(tester);

      await enterCode(tester, 'ANNA2345');
      expect(find.text(title), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Invite code'), findsOneWidget, reason: 'try another');
    });
  }

  testWidgets('an invite used meanwhile says so on Accept', (tester) async {
    await pumpFriends(tester);
    await enterCode(tester, 'ANNA2345');
    friends.codes['ANNA2345'] = (
      status: InviteStatus.gone,
      inviterId: 'anna',
      inviterName: 'Anna',
    );

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('This invite has expired'), findsOneWidget);
  });

  testWidgets('a failed accept can be tried again', (tester) async {
    await pumpFriends(tester);
    await enterCode(tester, 'ANNA2345');
    friends.error = Exception('offline');

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't accept the invite. Try again."), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text('You and Anna are friends'), findsOneWidget);
  });

  testWidgets('a web invite link opens the invitation after sign-in', (
    tester,
  ) async {
    await pumpFriends(tester, pending: PendingInvite('anna-2345'));

    expect(find.text('Anna invited you'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(find.text('You and Anna are friends'), findsOneWidget);
    expect(find.byType(FriendShelfPage), findsOneWidget, reason: 'opened');
  });

  testWidgets('Not now leaves the invite unanswered', (tester) async {
    await pumpFriends(tester, pending: PendingInvite('ANNA2345'));

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(friends.friends, isEmpty);
    expect(find.text('No friends yet'), findsOneWidget);
  });

  testWidgets('an invite link arriving later opens on Friends', (tester) async {
    final pending = PendingInvite();
    await pumpFriends(tester, pending: pending);
    expect(find.text('My shelf'), findsOneWidget);

    pending.value = 'ANNA2345';
    await tester.pumpAndSettle();

    expect(find.text('Anna invited you'), findsOneWidget);
    expect(pending.value, isNull, reason: 'taken once');
  });

  testWidgets('removing a friend asks first', (tester) async {
    friends.friends.add((id: 'anna', name: 'Anna', albums: 0));
    await pumpFriends(tester);

    await tester.tap(find.byTooltip('More for Anna'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Anna?'), findsOneWidget);
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();

    expect(find.text('Anna removed'), findsOneWidget);
    expect(friends.friends, isEmpty);
  });

  testWidgets('loading friends can fail and be tried again', (tester) async {
    friends.friends.add((id: 'anna', name: 'Anna', albums: 0));
    friends.loadError = Exception('offline');
    await pumpFriends(tester);

    expect(find.text("Couldn't load your friends"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('Friends and the invitation meet the accessibility guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    friends.friends.add((id: 'ben', name: 'Ben', albums: 0));
    friends.invites.add((
      code: 'K7Q2M9XD',
      expiresAt: DateTime.now().add(const Duration(days: 6, hours: 1)),
    ));
    await pumpFriends(tester);
    expect(find.text('Expires in 6 days · works once'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await enterCode(tester, 'ANNA2345');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  test('the shared message carries the app link and the code', () {
    expect(
      inviteMessage('Michael', 'K7Q2M9XD'),
      'Michael invites you to shelf: de.schwubware.shelf://invite/K7Q2-M9XD '
      '(or open shelf and enter the code K7Q2-M9XD under Friends)',
    );
  });

  test('invite links carry the code; other links none', () {
    expect(inviteCode(inviteLink('K7Q2M9XD')), 'K7Q2-M9XD');
    expect(inviteCode(Uri.parse('de.schwubware.shelf://login?code=1')), isNull);
    expect(inviteCode(Uri.parse('https://example.com/invite/K7Q2')), isNull);
  });

  group('inviteCodesFrom', () {
    final link = Uri.parse('de.schwubware.shelf://invite/K7Q2-M9XD');

    test('the link the app started with counts once', () async {
      final links = StreamController<Uri>();
      final codes = <String>[];
      inviteCodesFrom(Future.value(link), links.stream).listen(codes.add);
      await pumpEventQueue();
      links.add(link); // the same launch link, from the stream as well
      await pumpEventQueue();
      expect(codes, ['K7Q2-M9XD']);

      links.add(link); // tapped again later
      links.add(Uri.parse('de.schwubware.shelf://login?code=1'));
      await pumpEventQueue();
      expect(codes, ['K7Q2-M9XD', 'K7Q2-M9XD']);
      await links.close();
    });

    test('links arriving later come through', () async {
      final links = StreamController<Uri>();
      final codes = <String>[];
      inviteCodesFrom(Future.value(null), links.stream).listen(codes.add);
      await pumpEventQueue();
      links.add(link);
      await pumpEventQueue();
      expect(codes, ['K7Q2-M9XD']);
      await links.close();
    });
  });

  group('PendingInvite', () {
    test('takes codes from links and keeps them until taken', () async {
      final links = StreamController<String>();
      final pending = await PendingInvite.load(links.stream);
      expect(pending.value, isNull);

      links.add('K7Q2-M9XD');
      await pumpEventQueue();
      expect(pending.value, 'K7Q2-M9XD');
      final restarted = await PendingInvite.load(const Stream.empty());
      expect(restarted.value, 'K7Q2-M9XD', reason: 'kept on the device');

      expect(await restarted.take(), 'K7Q2-M9XD');
      expect(restarted.value, isNull);
      expect((await PendingInvite.load(const Stream.empty())).value, isNull);
      await links.close();
    });
  });
}
