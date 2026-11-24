import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// A text field recessed like a cassette window: 1 px outline and a soft
/// inner shadow at the top.
class ShelfField extends StatelessWidget {
  const ShelfField({
    super.key,
    required this.hintText,
    this.controller,
    this.icon,
    this.minLines,
    this.maxLines = 1,
  });

  final String hintText;
  final TextEditingController? controller;

  /// Shown at the start in muted colour, like the search icon.
  final IconData? icon;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: color),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            style: Theme.of(context).textTheme.bodyMedium,
            cursorColor: c.signal,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: c.muted),
              filled: true,
              fillColor: c.surface,
              isDense: true,
              constraints: const BoxConstraints(minHeight: 48),
              contentPadding: const EdgeInsets.all(14),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, size: 18, color: c.muted),
              prefixIconConstraints: const BoxConstraints(minWidth: 38),
              border: border(c.line),
              enabledBorder: border(c.line),
              focusedBorder: border(c.signal),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 6,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.press, c.press.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
