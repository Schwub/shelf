import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/auth/auth_gate.dart';
import 'package:shelf_app/share/link_resolver.dart';
import 'package:shelf_app/share/shared_link_inbox.dart';
import 'package:shelf_app/shelf/shelf_page.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import '../shelf/fake_shelf.dart';
import 'fake_auth.dart';
import '../search/fake_search.dart';
import '../share/fake_links.dart';

void main() {
  late FakeAuth auth;

  Future<void> openSignOut(WidgetTester tester) async {
    auth = FakeAuth(signedIn: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(Brightness.dark),
        home: AuthGate(
          auth: auth,
          signedIn: ShelfPage(
            auth: auth,
            shelf: FakeShelf([]),
            search: FakeSearch({}),
            links: FakeLinks(UnsupportedLink()),
            inbox: SharedLinkInbox(const Stream.empty()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
  }

  testWidgets('signs out from the menu after confirming', (tester) async {
    await openSignOut(tester);

    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Sign out')),
    );
    await tester.pumpAndSettle();

    expect(auth.signedIn, isFalse);
    expect(find.text('Send sign-in code'), findsOneWidget);
  });

  testWidgets('cancel keeps the user signed in', (tester) async {
    await openSignOut(tester);

    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')),
    );
    await tester.pumpAndSettle();

    expect(auth.signedIn, isTrue);
    expect(find.text('Sign out?'), findsNothing);
    expect(find.text('My shelf'), findsOneWidget);
  });
}
