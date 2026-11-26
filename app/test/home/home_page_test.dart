import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/home/home_page.dart';
import 'package:shelf_app/share/shared_link_inbox.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

/// A tab's first screen with a button that opens a second one.
class _Root extends StatelessWidget {
  const _Root(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(body: Text('$name details')),
          ),
        ),
        child: Text('$name root'),
      ),
    ),
  );
}

void main() {
  late SharedLinkInbox inbox;

  Future<void> pumpHome(WidgetTester tester) async {
    inbox = SharedLinkInbox(const Stream.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: shelfTheme(AppTheme.tobacco.colors),
        home: HomePage(
          inbox: inbox,
          shelf: const _Root('Shelf'),
          feed: const _Root('Feed'),
          friends: const _Root('Friends'),
        ),
      ),
    );
  }

  testWidgets('a shared link shows the Shelf tab, which opens it', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    inbox.value = Uri.parse('https://example.bandcamp.com/album/x');
    await tester.pumpAndSettle();

    expect(find.text('Shelf root'), findsOneWidget);
  });

  testWidgets('opens on Shelf and switches tabs', (tester) async {
    await pumpHome(tester);
    expect(find.text('Shelf root'), findsOneWidget);

    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    expect(find.text('Feed root'), findsOneWidget);
    expect(find.text('Shelf root'), findsNothing);
  });

  testWidgets('each tab keeps its screens', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friends root'));
    await tester.pumpAndSettle();
    expect(find.text('Friends details'), findsOneWidget);

    await tester.tap(find.text('Shelf'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('Friends details'), findsOneWidget);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('Friends root'), findsOneWidget, reason: 'tapped again');
  });

  testWidgets('back closes the current tab\'s screen first', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Shelf root'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Shelf root'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });
}
