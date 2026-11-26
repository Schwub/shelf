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

/// A made-up cover for an album without one, like the test covers of the
/// visual mockups (docs/design/visual/screens/): colours and pattern come
/// from the title and artist, so an album always gets the same one.
class CoverArt extends StatelessWidget {
  const CoverArt(this.album, {super.key});

  final Album album;

  /// Colour sets from the mockups' covers.
  static const _palettes = [
    [Color(0xFFE9E4DC), Color(0xFFD23A2C), Color(0xFF2B3A55)],
    [Color(0xFFFFD84A), Color(0xFFF2732C), Color(0xFF3A1660)],
    [Color(0xFF1D4F8A), Color(0xFF4F86C6), Color(0xFF0E2A4D)],
    [Color(0xFFF4F1E8), Color(0xFF1AA38C), Color(0xFF0F5C52)],
    [Color(0xFFF5D23A), Color(0xFFE0A11B), Color(0xFF7A3E12)],
    [Color(0xFF5B2A86), Color(0xFFE0457B), Color(0xFFF39B3A)],
    [Color(0xFF1B6F8F), Color(0xFF7FC3C9), Color(0xFFE8D7B8)],
    [Color(0xFFFAFAFA), Color(0xFFCFD6DD), Color(0xFF9AA6B2)],
    [Color(0xFFC78A3B), Color(0xFF6B3D1E), Color(0xFF2D4A2E)],
  ];

  /// FNV-1a: the same on every platform and run, unlike String.hashCode.
  static int seed(Album album) {
    var hash = 0x811c9dc5;
    for (final unit in '${album.title}\u0000${album.artist}'.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  /// Which colours and pattern [album] gets.
  static ({List<Color> colors, int pattern}) of(Album album) {
    final s = seed(album);
    return (colors: _palettes[s % _palettes.length], pattern: s ~/ 16 % 4);
  }

  @override
  Widget build(BuildContext context) {
    final (:colors, :pattern) = of(album);
    final [a, b, d] = colors;
    final gradient = switch (pattern) {
      // A hard diagonal split with a stripe.
      0 => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, a, b, b, d, d],
        stops: const [0, 0.42, 0.42, 0.5, 0.5, 1],
      ),
      // A sun.
      1 => RadialGradient(
        center: const Alignment(-0.4, -0.4),
        radius: 1.1,
        colors: [a, b, d],
        stops: const [0, 0.45, 1],
      ),
      // Sky to ground.
      2 => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [d, b, a],
        stops: const [0, 0.55, 1],
      ),
      // A sweep around one point.
      _ => SweepGradient(
        center: const Alignment(-0.2, 0.2),
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [a, b, d, a],
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: const SizedBox.expand(),
    );
  }
}
