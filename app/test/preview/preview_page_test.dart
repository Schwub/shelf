import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/preview/preview_page.dart';

import '../auth/fake_auth.dart';

import 'package:shelf_app/theme/shelf_theme.dart';

void main() {
  testWidgets(
    'every component in both themes meets the accessibility guidelines',
    (tester) async {
      final semantics = tester.ensureSemantics();
      // Tall enough to show the whole page: the guidelines check what's on screen.
      tester.view.physicalSize = const Size(412, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: shelfTheme(Brightness.light),
          home: PreviewPage(auth: FakeAuth(), links: const Stream.empty()),
        ),
      );

      expect(find.text('Evening'), findsOneWidget);
      expect(find.text('Daylight'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    },
  );
}
