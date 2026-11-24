import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// Geometry of the cassette-recorder key, seen from the bottom right.
///
/// Pressing lowers the key along its own height, so the right side, the
/// front side and the shadow all shrink in the same ratio (5:6 for the sides).
@immutable
class KeyGeometry {
  const KeyGeometry(this.depth);

  /// The key's height: [rest], [half] (half-star rating) or [pressed].
  final double depth;

  static const rest = 1.0;
  static const half = 0.7;
  static const pressed = 0.4;

  double get right => 5 * depth;
  double get front => 6 * depth;

  /// The face moves down and right by what the sides lose.
  Offset get faceOffset => Offset(5 - right, 6 - front);

  BoxShadow shadow(Color color) => BoxShadow(
    color: color,
    offset: Offset(3 * depth, 4 * depth),
    blurRadius: 5 * depth,
    spreadRadius: -depth,
  );
}

/// The one control of the app: a key that presses down (visual-system.md).
///
/// [selected] null makes an action key that only goes down while held; true
/// or false makes a choice that stays down while selected. [depth] overrides
/// the height, for rating keys.
class ShelfKey extends StatefulWidget {
  const ShelfKey({
    super.key,
    required this.child,
    this.onPressed,
    this.selected,
    this.light = false,
    this.primary = false,
    this.depth,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;

  /// Null disables the key.
  final VoidCallback? onPressed;
  final bool? selected;

  /// Shows the light window at the start of the key, lit while selected.
  final bool light;

  /// Amber face, for the main action of a screen.
  final bool primary;
  final double? depth;

  /// For keys whose child isn't text, such as icon keys.
  final String? semanticLabel;

  /// Space between the face's edges and the child.
  final EdgeInsets padding;

  @override
  State<ShelfKey> createState() => _ShelfKeyState();
}

class _ShelfKeyState extends State<ShelfKey> {
  bool _down = false;

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final selected = widget.selected ?? false;
    final depth =
        widget.depth ??
        (selected || _down ? KeyGeometry.pressed : KeyGeometry.rest);
    final lit = selected || (widget.depth != null && depth < KeyGeometry.rest);
    Widget key = TweenAnimationBuilder<double>(
      tween: Tween(end: depth),
      duration: const Duration(milliseconds: 100),
      builder: (context, depth, child) => CustomPaint(
        painter: _KeyPainter(
          geometry: KeyGeometry(depth),
          colors: context.shelf,
          primary: widget.primary,
          lit: lit,
          light: widget.light,
        ),
        child: Padding(
          padding: _contentPadding(KeyGeometry(depth)),
          child: child,
        ),
      ),
      child: Center(widthFactor: 1, child: _label(context)),
    );
    // The key looks 44 px; an invisible margin makes the touch area at
    // least 48 × 48 (Android's minimum).
    key = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        height: 44,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44),
          child: key,
        ),
      ),
    );
    final visible = key;
    key = LayoutBuilder(
      builder: (context, constraints) => constraints.hasTightWidth
          ? visible
          : ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48),
              child: Center(widthFactor: 1, heightFactor: 1, child: visible),
            ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setDown(true) : null,
          onTapUp: enabled ? (_) => _setDown(false) : null,
          onTapCancel: enabled ? () => _setDown(false) : null,
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onPressed!();
                }
              : null,
          child: key,
        ),
      ),
    );
  }

  EdgeInsets _contentPadding(KeyGeometry g) {
    final p = widget.padding;
    return EdgeInsets.fromLTRB(
      g.faceOffset.dx + p.left + (widget.light ? 12 : 0),
      g.faceOffset.dy,
      g.right + p.right,
      g.front,
    );
  }

  Widget _label(BuildContext context) {
    final c = context.shelf;
    final engraved = widget.primary
        ? const [Shadow(color: Color(0x88FFD98A), offset: Offset(0, 1))]
        : [
            Shadow(color: c.engrave, offset: const Offset(0, 1)),
            Shadow(color: c.engraveLight, offset: const Offset(0, -1)),
          ];
    final color = widget.primary ? c.onAmber : c.text;
    return DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.labelLarge!
          .copyWith(color: color, shadows: engraved),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: 20),
        child: widget.child,
      ),
    );
  }
}

class _KeyPainter extends CustomPainter {
  _KeyPainter({
    required this.geometry,
    required this.colors,
    required this.primary,
    required this.lit,
    required this.light,
  });

  final KeyGeometry geometry;
  final ShelfColors colors;
  final bool primary, lit, light;

  static const _radius = Radius.circular(4);

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final o = g.faceOffset;
    final edge = Rect.fromLTRB(o.dx, o.dy, size.width, size.height);
    final face = Rect.fromLTRB(
      o.dx,
      o.dy,
      size.width - g.right,
      size.height - g.front,
    );
    final edgeShape = RRect.fromRectAndRadius(edge, _radius);
    final faceShape = RRect.fromRectAndRadius(face, _radius);

    // Two layers, never inset shadows: the full key in side colour, then
    // the face on top of it.
    final shadow = g.shadow(colors.edge);
    canvas.drawRRect(
      edgeShape.shift(shadow.offset).inflate(shadow.spreadRadius),
      shadow.toPaint(),
    );
    canvas.drawRRect(
      edgeShape,
      Paint()..color = primary ? ShelfColors.amberSide : colors.side,
    );
    canvas.save();
    canvas.clipRRect(edgeShape);
    final right = Paint()
      ..color = primary ? ShelfColors.amberSideRight : colors.sideRight;
    canvas.drawRect(
      Rect.fromLTRB(size.width - g.right, o.dy, size.width, size.height),
      right,
    );
    final contact = Paint()
      ..color = primary ? ShelfColors.amberContact : colors.contact;
    canvas.drawRect(
      Rect.fromLTRB(size.width - 1, o.dy, size.width, size.height),
      contact,
    );
    canvas.drawRect(
      Rect.fromLTRB(o.dx, size.height - 1, size.width, size.height),
      contact,
    );
    canvas.restore();

    final gradient = primary
        ? const LinearGradient(
            colors: [ShelfColors.amberStart, ShelfColors.amberEnd],
          )
        : LinearGradient(
            // CSS 160deg with the second colour at 70 %.
            begin: const Alignment(-0.36, -1),
            end: const Alignment(0.36, 1),
            stops: const [0, 0.7],
            colors: lit
                ? [colors.pressedTop, colors.pressedBottom]
                : [colors.faceTop, colors.faceBottom],
          );
    canvas.drawRRect(faceShape, Paint()..shader = gradient.createShader(face));

    canvas.save();
    canvas.clipRRect(faceShape);
    if (!primary) {
      canvas.drawRRect(
        faceShape.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = colors.line,
      );
    }
    void topLeft(double width, Color color) {
      final paint = Paint()..color = color;
      canvas.drawRect(
        Rect.fromLTWH(face.left, face.top, face.width, width),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(face.left, face.top, width, face.height),
        paint,
      );
    }

    if (primary) {
      topLeft(1, ShelfColors.amberHighlight);
    } else if (lit) {
      // Pressed keys catch the light in signal colour.
      topLeft(2, const Color(0x33F2B13A));
      topLeft(1, colors.signal);
    } else {
      topLeft(1, colors.highlight);
    }
    canvas.restore();

    if (light) _paintWindow(canvas, face);
  }

  /// 10 × 6 px, 10 px from the face's left edge, on its vertical centre.
  void _paintWindow(Canvas canvas, Rect face) {
    final rect = Rect.fromLTWH(face.left + 10, face.center.dy - 3, 10, 6);
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    if (lit) {
      for (final glow in [
        BoxShadow(color: colors.windowGlow, blurRadius: 18, spreadRadius: 8),
        const BoxShadow(color: Color(0x88F2B13A), blurRadius: 6),
      ]) {
        canvas.drawRRect(shape.inflate(glow.spreadRadius), glow.toPaint());
      }
      canvas.drawRRect(
        shape,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.2),
            stops: const [0, 0.7],
            colors: [const Color(0xFFFFD27A), colors.signal],
          ).createShader(rect),
      );
    } else {
      canvas.drawRRect(shape, Paint()..color = colors.window);
    }
    // Recessed: a shadow along the window's top edge.
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, 1),
      Paint()..color = Color(lit ? 0x66000000 : 0x88000000),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KeyPainter old) =>
      old.geometry.depth != geometry.depth ||
      old.colors != colors ||
      old.primary != primary ||
      old.lit != lit ||
      old.light != light;
}
