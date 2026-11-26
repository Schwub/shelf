import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// A cover while selecting: a signal outline and a check when [selected],
/// an empty ring when not; nothing outside selecting (null).
class SelectMark extends StatelessWidget {
  const SelectMark({super.key, required this.selected, required this.child});

  final bool? selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final on = selected;
    if (on == null) return child;
    final c = context.shelf;
    return Stack(
      children: [
        child,
        if (on)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: c.signal, width: 3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? c.signal : const Color(0x55000000),
              border: Border.all(
                color: on ? c.signal : const Color(0xFFFFFFFF),
                width: 2,
              ),
            ),
            child: on ? Icon(Icons.check, size: 16, color: c.bg) : null,
          ),
        ),
      ],
    );
  }
}
