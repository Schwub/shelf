import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/auth/auth_gate.dart';
import 'package:shelf_app/preview/preview_page.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import 'fake_auth.dart';

void main() {
  late FakeAuth auth;

  Future<void> openSignOut(WidgetTester tester) async {
    auth = FakeAuth(signedIn: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(Brightness.dark),
        home: AuthGate(
          auth: auth,
          signedIn: PreviewPage(auth: auth, links: const Stream.empty()),
        ),
      ),
    );
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
