import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// An underlined muted link with a 48 px touch area: "Add" on a group's
/// label line, the track list's actions.
class TextLink extends StatelessWidget {
  const TextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
      color: c.muted,
      decoration: TextDecoration.underline,
      decorationColor: c.muted,
    );
    return Semantics(
      // Its own node, not merged into the text around it.
      container: true,
      button: true,
      label: semanticLabel ?? label,
      // The gesture's own semantics are excluded with the text, so the tap
      // is given here.
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: c.muted),
                const SizedBox(width: 4),
              ],
              // Wraps when it is longer than the space it has.
              Flexible(child: Text(label, style: style)),
            ],
          ),
        ),
      ),
    );
  }
}
