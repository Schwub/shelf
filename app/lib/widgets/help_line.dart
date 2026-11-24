import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// A short line under a field: muted help, or an error with a warning icon
/// in signal colour (there is no separate error colour).
class HelpLine extends StatelessWidget {
  const HelpLine(this.text, {super.key, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final style = Theme.of(context).textTheme;
    if (!error) {
      return Text(text, style: style.bodySmall!.copyWith(color: c.muted));
    }
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: c.signal),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: style.labelMedium)),
        ],
      ),
    );
  }
}
