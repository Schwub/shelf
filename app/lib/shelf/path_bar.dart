import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// One part of a tag's path: a group or tag name. [isNew] parts don't exist
/// yet (dashed, with a plus), [on] parts are filled in, [dim] ones stand
/// back. With [onTap] the part can be changed.
class PathPart {
  const PathPart(
    this.name, {
    this.isNew = false,
    this.on = false,
    this.dim = false,
    this.onTap,
    this.semanticLabel,
  });

  final String name;
  final bool isNew, on, dim;
  final VoidCallback? onTap;
  final String? semanticLabel;
}

/// A tag's full path as a row of parts that wraps, the last one the tag
/// itself: "Genre › Metal › Black metal" (docs/design/wireframes/
/// copy-tags-8.html). [label] says whose it is ("FROM", "TO").
class PathBar extends StatelessWidget {
  const PathBar({super.key, this.label, required this.parts, this.trailing});

  final String? label;
  final List<PathPart> parts;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          height: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label ?? '',
              style: text.labelSmall!.copyWith(color: c.muted),
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (i, part) in parts.indexed) ...[
                if (i > 0)
                  ExcludeSemantics(
                    child: Text(
                      '›',
                      style: text.bodySmall!.copyWith(color: c.muted),
                    ),
                  ),
                PathChip(part, last: i == parts.length - 1),
              ],
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

/// A part of a path as a chip; a full-height touch area when it can be
/// tapped.
class PathChip extends StatelessWidget {
  const PathChip(this.part, {super.key, this.last = false});

  final PathPart part;

  /// The tag itself, at the end of the path: bolder.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final color = part.on
        ? c.signal
        : part.dim
        ? c.off
        : c.line;
    final chip = CustomPaint(
      foregroundPainter: part.isNew && !part.on ? _Dashes(c.muted) : null,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: part.on ? c.signal : c.window,
          borderRadius: BorderRadius.circular(4),
          border: part.isNew && !part.on ? null : Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (part.isNew && !part.on) ...[
              Icon(Icons.add, size: 14, color: c.muted),
              const SizedBox(width: 2),
            ],
            Text(
              part.name,
              style: (last ? text.titleSmall : text.bodyMedium)!.copyWith(
                color: part.on
                    ? c.bg
                    : part.dim
                    ? c.muted
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: part.onTap != null,
      label: part.semanticLabel ?? '${part.name}${part.isNew ? ', new' : ''}',
      onTap: part.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: part.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Center(widthFactor: 1, child: chip),
          ),
        ),
      ),
    );
  }
}

/// A dashed rounded outline, for a part that doesn't exist yet.
class _Dashes extends CustomPainter {
  const _Dashes(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          const Radius.circular(4),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in outline.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 7) {
        canvas.drawPath(metric.extractPath(at, at + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => old.color != color;
}
