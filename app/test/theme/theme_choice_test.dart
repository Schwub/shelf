import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/main.dart';
import 'package:shelf_app/share/link_resolver.dart';
import 'package:shelf_app/share/shared_link_inbox.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/theme/theme_choice.dart';

import '../auth/fake_auth.dart';
import '../search/fake_search.dart';
import '../share/fake_links.dart';
import '../shelf/fake_shelf.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('tobacco until another theme is chosen, then remembered', () async {
    expect((await ThemeChoice.load()).value, AppTheme.tobacco);

    await (await ThemeChoice.load()).choose(AppTheme.evening);

    expect((await ThemeChoice.load()).value, AppTheme.evening);
  });

  testWidgets('the menu changes the theme at once', (tester) async {
    final theme = ThemeChoice();
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
        theme: theme,
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

    expect(theme.value, AppTheme.evening);
    expect(background(), ShelfColors.evening.bg);
  });
}
