import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../shelf/shelf.dart';
import '../theme/shelf_colors.dart';

/// An album cover with 2 px corners: a surface block while loading, and
/// [CoverArt] when the album has none or it can't be loaded.
class Cover extends StatelessWidget {
  const Cover(this.album, {super.key});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final url = album.coverUrl;
    final art = CoverArt(album);
    return Semantics(
      image: true,
      label: 'Cover of ${album.title}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: AspectRatio(
          aspectRatio: 1,
          child: url == null
              ? art
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : ColoredBox(color: c.surface),
                  errorBuilder: (context, error, stack) => art,
                ),
        ),
      ),
    );
  }
}

/// A made-up cover for an album without one, in the spirit of the visual
/// mockups' test covers: one of [patterns] in one of [_palettes], with
/// angles, positions and counts varied too. All of it comes from the title
/// and artist, so an album always gets the same cover.
class CoverArt extends StatelessWidget {
  const CoverArt(this.album, {super.key});

  final Album album;

  static const patterns = 12;

  /// Four colours each: ground, two strong ones, an accent.
  static const _palettes = [
    [
      Color(0xFFE9E4DC),
      Color(0xFFD23A2C),
      Color(0xFF2B3A55),
      Color(0xFFF2B13A),
    ],
    [
      Color(0xFF3A1660),
      Color(0xFFF2732C),
      Color(0xFFFFD84A),
      Color(0xFFE0457B),
    ],
    [
      Color(0xFF0E2A4D),
      Color(0xFF1D4F8A),
      Color(0xFF4F86C6),
      Color(0xFFE9E4DC),
    ],
    [
      Color(0xFFF4F1E8),
      Color(0xFF1AA38C),
      Color(0xFF0F5C52),
      Color(0xFFE8743A),
    ],
    [
      Color(0xFF7A3E12),
      Color(0xFFE0A11B),
      Color(0xFFF5D23A),
      Color(0xFF2D1B0E),
    ],
    [
      Color(0xFF5B2A86),
      Color(0xFFE0457B),
      Color(0xFFF39B3A),
      Color(0xFF1C0F2E),
    ],
    [
      Color(0xFFE8D7B8),
      Color(0xFF1B6F8F),
      Color(0xFF7FC3C9),
      Color(0xFF2A1D16),
    ],
    [
      Color(0xFF9AA6B2),
      Color(0xFFFAFAFA),
      Color(0xFFCFD6DD),
      Color(0xFF3B4A5E),
    ],
    [
      Color(0xFF2D4A2E),
      Color(0xFFC78A3B),
      Color(0xFF6B3D1E),
      Color(0xFFE9D8A6),
    ],
    [
      Color(0xFF111111),
      Color(0xFFF1E6D4),
      Color(0xFFD23A2C),
      Color(0xFF7A7A7A),
    ],
    [
      Color(0xFFF7E1D7),
      Color(0xFFDEDBD2),
      Color(0xFF4A5759),
      Color(0xFFB0C4B1),
    ],
    [
      Color(0xFF1F2041),
      Color(0xFF4B3F72),
      Color(0xFFFFC857),
      Color(0xFF119DA4),
    ],
    [
      Color(0xFFFFF3E2),
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFF1A535C),
    ],
    [
      Color(0xFF0B3C49),
      Color(0xFFFFFDF7),
      Color(0xFFF2545B),
      Color(0xFF731963),
    ],
    [
      Color(0xFFFFB627),
      Color(0xFFFF9505),
      Color(0xFFE2711D),
      Color(0xFF3D2645),
    ],
    [
      Color(0xFFE6E8E6),
      Color(0xFF3F88C5),
      Color(0xFFF49D37),
      Color(0xFF140F2D),
    ],
    [
      Color(0xFF2B2D42),
      Color(0xFF8D99AE),
      Color(0xFFEDF2F4),
      Color(0xFFEF233C),
    ],
    [
      Color(0xFFCAD2C5),
      Color(0xFF84A98C),
      Color(0xFF52796F),
      Color(0xFF354F52),
    ],
    [
      Color(0xFF3C1518),
      Color(0xFF69140E),
      Color(0xFFA44200),
      Color(0xFFF2F3AE),
    ],
    [
      Color(0xFFF0EAD2),
      Color(0xFFDDE5B6),
      Color(0xFFA98467),
      Color(0xFF6C584C),
    ],
  ];

  /// FNV-1a: the same on every platform and run, unlike String.hashCode.
  static int seed(Album album) {
    var hash = 0x811c9dc5;
    for (final unit in '${album.title}\u0000${album.artist}'.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  /// Which palette and pattern [album] gets (the details vary within).
  static ({int palette, int pattern}) of(Album album) {
    final s = seed(album);
    return (palette: s % _palettes.length, pattern: s ~/ 32 % patterns);
  }

  @override
  Widget build(BuildContext context) {
    final (:palette, :pattern) = of(album);
    return CustomPaint(
      painter: _CoverPainter(
        _palettes[palette],
        pattern,
        math.Random(seed(album)),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.colors, this.pattern, math.Random random)
    // Drawn from once, up front, so every paint looks the same.
    : _r = List.generate(8, (_) => random.nextDouble());

  final List<Color> colors;
  final int pattern;
  final List<double> _r;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final [ground, a, b, accent] = colors;
    final rect = Offset.zero & size;
    // Rings and the rotated split reach past the edges.
    canvas.clipRect(rect);
    Paint fill(Color color) => Paint()..color = color;
    Paint shade(Gradient g) => Paint()..shader = g.createShader(rect);
    double r(int i, double from, double to) => from + _r[i] * (to - from);
    canvas.drawRect(rect, fill(ground));
    switch (pattern) {
      case 0: // A hard diagonal split with a stripe.
        canvas.save();
        canvas.translate(s / 2, s / 2);
        canvas.rotate(r(0, -0.9, 0.9));
        canvas.drawRect(
          Rect.fromLTRB(-s, r(1, -s * .1, s * .2), s, s),
          fill(b),
        );
        canvas.drawRect(
          Rect.fromLTRB(
            -s,
            r(1, -s * .1, s * .2),
            s,
            r(1, -s * .1, s * .2) + s * r(2, .04, .1),
          ),
          fill(a),
        );
        canvas.restore();
      case 1: // A sun.
        canvas.drawRect(
          rect,
          shade(
            RadialGradient(
              center: Alignment(r(0, -.6, .6), r(1, -.6, .6)),
              radius: r(2, .8, 1.3),
              colors: [accent, a, b],
              stops: const [0, .45, 1],
            ),
          ),
        );
      case 2: // Sky to ground.
        canvas.drawRect(
          rect,
          shade(
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [b, a, ground],
              stops: [0, r(0, .35, .7), 1],
            ),
          ),
        );
      case 3: // A sweep around one point.
        canvas.drawRect(
          rect,
          shade(
            SweepGradient(
              center: Alignment(r(0, -.5, .5), r(1, -.5, .5)),
              startAngle: r(2, 0, math.pi),
              endAngle: r(2, 0, math.pi) + math.pi * 2,
              colors: [a, b, accent, a],
              transform: GradientRotation(r(3, 0, math.pi * 2)),
            ),
          ),
        );
      case 4: // Bands.
        final n = 3 + (_r[0] * 5).floor();
        for (var i = 0; i < n; i++) {
          canvas.drawRect(
            Rect.fromLTWH(0, s * i / n, s, s / n + 1),
            fill([a, b, accent, ground][i % 4]),
          );
        }
      case 5: // Rings.
        final c = Offset(s * r(0, .3, .7), s * r(1, .3, .7));
        final n = 4 + (_r[2] * 4).floor();
        for (var i = n; i > 0; i--) {
          canvas.drawCircle(c, s * .9 * i / n, fill([a, b, accent][i % 3]));
        }
      case 6: // One big circle.
        canvas.drawCircle(
          Offset(s * r(0, .25, .75), s * r(1, .25, .75)),
          s * r(2, .2, .45),
          fill(a),
        );
        canvas.drawCircle(
          Offset(s * r(3, .2, .8), s * r(4, .2, .8)),
          s * r(5, .04, .1),
          fill(accent),
        );
      case 7: // A sunset over a horizon.
        final horizon = s * r(0, .55, .72);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, s, horizon),
          shade(
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [b, a],
            ),
          ),
        );
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, 0, s, horizon));
        canvas.drawCircle(
          Offset(s * r(1, .3, .7), horizon),
          s * r(2, .15, .3),
          fill(accent),
        );
        canvas.restore();
        canvas.drawRect(
          Rect.fromLTWH(0, horizon, s, s - horizon),
          fill(ground),
        );
      case 8: // Blocks.
        final x = s * r(0, .3, .7), y = s * r(1, .3, .7);
        canvas.drawRect(Rect.fromLTWH(0, 0, x, y), fill(a));
        canvas.drawRect(Rect.fromLTWH(x, 0, s - x, y), fill(b));
        canvas.drawRect(Rect.fromLTWH(0, y, x, s - y), fill(accent));
      case 9: // A mountain.
        final peak = Offset(s * r(0, .3, .7), s * r(1, .2, .45));
        canvas.drawRect(rect, fill(b));
        canvas.drawPath(
          Path()
            ..moveTo(0, s)
            ..lineTo(peak.dx, peak.dy)
            ..lineTo(s, s * r(2, .5, .8))
            ..lineTo(s, s)
            ..close(),
          fill(a),
        );
        canvas.drawCircle(
          Offset(s * r(3, .15, .85), s * .18),
          s * .07,
          fill(accent),
        );
      case 10: // A grid of dots.
        final n = 3 + (_r[0] * 4).floor();
        final step = s / n;
        for (var i = 0; i < n; i++) {
          for (var j = 0; j < n; j++) {
            canvas.drawCircle(
              Offset(step * (i + .5), step * (j + .5)),
              step * r(1, .2, .4),
              fill((i + j) % 3 == 0 ? accent : a),
            );
          }
        }
      default: // Two soft colour fields.
        final split = s * r(0, .4, .6);
        Paint field(Color color) =>
            fill(color)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .02);
        canvas.drawRect(
          Rect.fromLTRB(s * .1, s * .08, s * .9, split - s * .03),
          field(a),
        );
        canvas.drawRect(
          Rect.fromLTRB(s * .1, split + s * .03, s * .9, s * .92),
          field(b),
        );
    }
  }

  @override
  bool shouldRepaint(_CoverPainter old) =>
      old.colors != colors || old.pattern != pattern || old._r != _r;
}
