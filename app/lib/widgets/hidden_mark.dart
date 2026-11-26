import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// Under an album the user hides from friends.
class HiddenMark extends StatelessWidget {
  const HiddenMark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    return Semantics(
      label: 'Hidden from friends',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_outlined, size: 14, color: c.muted),
            const SizedBox(width: 4),
            Text(
              'Hidden',
              style: Theme.of(context).textTheme.bodySmall!
                  .copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
