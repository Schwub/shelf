import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/widgets/text_link.dart';

import 'harness.dart';

void main() {
  testWidgets('screen readers can activate it', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      themed(
        TextLink(
          label: 'Change',
          semanticLabel: 'Change your name',
          onPressed: () => taps++,
        ),
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Change your name'));

    expect(taps, 1);
    semantics.dispose();
  });
}
