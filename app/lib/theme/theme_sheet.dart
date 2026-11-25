import 'package:material_ui/material_ui.dart';

import '../widgets/shelf_key.dart';
import 'shelf_colors.dart';
import 'theme_choice.dart';

/// Pick a theme; it changes at once and is remembered.
Future<void> showThemeSheet(BuildContext context, ThemeChoice theme) {
  final c = context.shelf;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.bg,
    barrierColor: const Color(0x73000000),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      side: BorderSide(color: c.line),
    ),
    // Rebuilt with the new theme's colours as soon as one is picked.
    builder: (_) => ValueListenableBuilder(
      valueListenable: theme,
      builder: (context, chosen, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.shelf.off,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Theme', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final t in AppTheme.values) ...[
              ShelfKey(
                light: true,
                selected: chosen == t,
                onPressed: () => theme.choose(t),
                child: Text(t.label),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}
