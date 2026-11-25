import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// A 56 px row of the editor's lists: an optional 44 px [leading] slot
/// (reorder handle, or the + of an "Add" row), title and muted [subtitle],
/// an optional muted [mark] ("Built-in") and a 44 px [trailing] slot.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.mark,
    this.leading,
    this.trailing,
    this.dim = false,
    this.onTap,
  });

  final String title;
  final String? subtitle, mark;
  final Widget? leading, trailing;

  /// Muted text, for a hidden group.
  final bool dim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    Widget slot(Widget child) => IconTheme.merge(
      data: IconThemeData(color: c.muted, size: 20),
      child: SizedBox.square(dimension: 44, child: Center(child: child)),
    );
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            if (leading != null)
              Transform.translate(
                offset: const Offset(-12, 0),
                child: slot(leading!),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: dim
                          ? text.titleMedium!.copyWith(color: c.muted)
                          : text.titleMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: text.bodySmall!.copyWith(color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (mark != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  mark!,
                  style: text.labelSmall!.copyWith(color: c.muted),
                ),
              ),
            if (trailing != null)
              Transform.translate(
                offset: const Offset(12, 0),
                child: slot(trailing!),
              ),
          ],
        ),
      ),
    );
  }
}
