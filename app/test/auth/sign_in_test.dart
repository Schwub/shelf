import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/auth/auth.dart';
import 'package:shelf_app/auth/auth_gate.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

import 'fake_auth.dart';

void main() {
  late FakeAuth auth;

  Future<void> pumpApp(WidgetTester tester, {bool signedIn = false}) {
    auth = FakeAuth(signedIn: signedIn);
    return tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(Brightness.dark),
        home: AuthGate(
          auth: auth,
          signedIn: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: auth.signOut,
                child: const Text('Signed in'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> enterEmail(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextField), email);
    await tester.tap(find.text('Send sign-in code'));
    await tester.pumpAndSettle();
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
  }

  testWidgets('signs in with the emailed code', (tester) async {
    await pumpApp(tester);

    await enterEmail(tester, ' anna@example.com ');
    expect(auth.sent, ['anna@example.com']);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('anna@example.com'), findsOneWidget);

    await enterCode(tester, '123456');
    expect(find.text('Signed in'), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
  });

  testWidgets('a signed-in user starts signed in', (tester) async {
    await pumpApp(tester, signedIn: true);

    expect(find.text('Signed in'), findsOneWidget);
  });

  testWidgets('signing out returns to sign-in', (tester) async {
    await pumpApp(tester, signedIn: true);

    await tester.tap(find.text('Signed in'));
    await tester.pumpAndSettle();

    expect(find.text('Send sign-in code'), findsOneWidget);
  });

  testWidgets('an invalid email is not sent', (tester) async {
    await pumpApp(tester);

    await enterEmail(tester, 'anna@example');

    expect(auth.sent, isEmpty);
    expect(find.textContaining('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('a failed send says so and stays', (tester) async {
    await pumpApp(tester);
    auth.sendError = Exception('offline');

    await enterEmail(tester, 'anna@example.com');

    expect(find.textContaining("Couldn't send the email"), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
  });

  testWidgets('too many emails asks to wait', (tester) async {
    await pumpApp(tester);
    auth.sendError = TooManyEmails();

    await enterEmail(tester, 'anna@example.com');

    expect(find.textContaining('Too many sign-in emails'), findsOneWidget);
  });

  testWidgets('a wrong code says so and keeps the user signed out', (
    tester,
  ) async {
    await pumpApp(tester);
    await enterEmail(tester, 'anna@example.com');

    await enterCode(tester, '654321');
    expect(find.textContaining("That code isn't right"), findsOneWidget);

    await enterCode(tester, '12345');
    expect(find.textContaining('Enter the 6-digit code'), findsOneWidget);
    expect(auth.signedIn, isFalse);
  });

  testWidgets('the code can be resent after 60 seconds', (tester) async {
    await pumpApp(tester);
    await enterEmail(tester, 'anna@example.com');

    expect(find.text('Resend code in 1:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 18));
    expect(find.text('Resend code in 0:42'), findsOneWidget);

    await tester.pump(const Duration(seconds: 42));
    await tester.tap(find.text('Resend code'));
    await tester.pump();

    expect(auth.sent, ['anna@example.com', 'anna@example.com']);
    expect(find.text('We sent a new code.'), findsOneWidget);
    expect(find.text('Resend code in 1:00'), findsOneWidget);
  });

  testWidgets('a different email goes back to the email field', (tester) async {
    await pumpApp(tester);
    await enterEmail(tester, 'anna@example.com');

    await tester.tap(find.text('Use a different email'));
    await tester.pumpAndSettle();

    expect(find.text('Send sign-in code'), findsOneWidget);
  });
}
