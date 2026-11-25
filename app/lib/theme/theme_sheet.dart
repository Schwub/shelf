import 'package:material_ui/material_ui.dart';

import '../widgets/shelf_key.dart';
import 'shelf_colors.dart';
import 'theme_choice.dart';

/// Pick a theme; it changes at once and is remembered.
Future<void> showThemeSheet(BuildContext context, ThemeChoice theme) {
  final c = context.shelf;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.bg,
    barrierColor: const Color(0x73000000),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      side: BorderSide(color: c.line),
    ),
    // Rebuilt with the new theme's colours as soon as one is picked.
    builder: (_) => ValueListenableBuilder(
      valueListenable: theme,
      builder: (context, chosen, _) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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
            for (final family in ThemeFamily.values) ...[
              const SizedBox(height: 16),
              Text(
                family.label,
                style: Theme.of(context).textTheme.labelSmall!
                    .copyWith(color: context.shelf.muted),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, box) => Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final t in AppTheme.values)
                      if (t.family == family)
                        SizedBox(
                          width: (box.maxWidth - 8) / 2,
                          child: ShelfKey(
                            light: true,
                            selected: chosen == t,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            onPressed: () => theme.choose(t),
                            child: Row(
                              children: [
                                _Swatch(t.colors),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    t.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// A theme at a glance: its background with its accent.
class _Swatch extends StatelessWidget {
  const _Swatch(this.colors);

  final ShelfColors colors;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: colors.bg,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: context.shelf.line),
    ),
    alignment: Alignment.bottomRight,
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: colors.signal,
        borderRadius: BorderRadius.circular(1),
      ),
    ),
  );
}
