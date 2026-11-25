import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/main.dart';

import 'auth/fake_auth.dart';
import 'shelf/fake_shelf.dart';

void main() {
  testWidgets('starts on the shelf when signed in', (tester) async {
    await tester.pumpWidget(
      ShelfApp(
        auth: FakeAuth(signedIn: true),
        shelf: FakeShelf([entry('1', 'Blue')]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My shelf'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
  });

  testWidgets('starts on sign-in when signed out', (tester) async {
    await tester.pumpWidget(ShelfApp(auth: FakeAuth(), shelf: FakeShelf([])));

    expect(find.text('Send sign-in code'), findsOneWidget);
  });
}
