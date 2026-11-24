import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:shelf_app/main.dart';

import 'auth/fake_auth.dart';

void main() {
  testWidgets('shows the last shared link', (tester) async {
    final links = StreamController<Uri>();
    await tester.pumpWidget(
      ShelfApp(auth: FakeAuth(signedIn: true), links: links.stream),
    );

    expect(find.textContaining('Share an album'), findsOneWidget);

    links.add(Uri.parse('https://open.spotify.com/album/abc'));
    await tester.pump();

    expect(find.text('https://open.spotify.com/album/abc'), findsOneWidget);
    await links.close();
  });
}
