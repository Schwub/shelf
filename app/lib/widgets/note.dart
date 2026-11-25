import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// A boxed message with a warning or info icon in signal colour: why
/// something can't be done, or that a change didn't save.
class Note extends StatelessWidget {
  const Note({
    super.key,
    required this.child,
    this.icon = Icons.warning_amber_rounded,
  });

  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: c.signal),
            const SizedBox(width: 8),
            Expanded(
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontSize: 13, height: 1.4),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
