import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shelf_app/theme/shelf_colors.dart';
import 'package:shelf_app/theme/shelf_theme.dart';

/// [child] in the app theme, 400 px wide.
Widget themed(Widget child, {AppTheme theme = AppTheme.tobacco}) => MaterialApp(
  theme: shelfTheme(theme.colors),
  home: Scaffold(
    body: Center(child: SizedBox(width: 400, child: child)),
  ),
);

/// The heights the keys are animating to, in order.
List<double?> keyDepths(WidgetTester tester) => tester
    .widgetList<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    )
    .map((t) => t.tween.end)
    .toList();
