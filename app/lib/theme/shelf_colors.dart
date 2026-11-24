import 'package:material_ui/material_ui.dart';

/// Colour tokens from docs/design/visual-system.md, evening and daylight.
@immutable
class ShelfColors extends ThemeExtension<ShelfColors> {
  const ShelfColors({
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.signal,
    required this.line,
    required this.off,
    required this.onAmber,
    required this.shadow,
    required this.faceTop,
    required this.faceBottom,
    required this.pressedTop,
    required this.pressedBottom,
    required this.side,
    required this.sideRight,
    required this.contact,
    required this.highlight,
    required this.edge,
    required this.engrave,
    required this.engraveLight,
    required this.window,
    required this.windowGlow,
    required this.press,
    required this.meter,
  });

  final Color bg, surface, text, muted, signal, line, off, onAmber, shadow;

  /// Key face gradient at rest and pressed.
  final Color faceTop, faceBottom, pressedTop, pressedBottom;

  /// Key sides: front, right (darker, away from the light), contact line.
  final Color side, sideRight, contact;

  /// Key details: top-left highlight, drop shadow, engraved label, light window.
  final Color highlight, edge, engrave, engraveLight, window, windowGlow;

  /// Inner shadow of recessed fields.
  final Color press;

  /// The five rating bars, amber to coral.
  final List<Color> meter;

  static const teak = Color(0xFFA87445);
  static const amberStart = Color(0xFFF2B13A);
  static const amberEnd = Color(0xFFE8743A);
  static const amberSide = Color(0xFFB4501E);
  static const amberSideRight = Color(0xFF9E4418);
  static const amberContact = Color(0xFF7A3010);
  static const amberHighlight = Color(0xFFFFD98A);

  static const evening = ShelfColors(
    bg: Color(0xFF1F1510),
    surface: Color(0xFF2A1D16),
    text: Color(0xFFF1E6D4),
    muted: Color(0xFFB5A28B),
    signal: Color(0xFFF0A830),
    line: Color(0x1FF1E6D4),
    off: Color(0xFF8C7C6A),
    onAmber: Color(0xFF1F1510),
    shadow: Color(0x59000000),
    faceTop: Color(0xFF3A2A20),
    faceBottom: Color(0xFF2A1D16),
    pressedTop: Color(0xFF33251C),
    pressedBottom: Color(0xFF271B14),
    side: Color(0xFF1A110C),
    sideRight: Color(0xFF120B08),
    contact: Color(0xFF060403),
    highlight: Color(0x1CFFFFFF),
    edge: Color(0x66000000),
    engrave: Color(0x99000000),
    engraveLight: Color(0x14FFFFFF),
    window: Color(0xFF0E0907),
    windowGlow: Color(0x33F2B13A),
    press: Color(0x88000000),
    meter: [
      Color(0xFFF2B13A),
      Color(0xFFF0A23A),
      Color(0xFFED923A),
      Color(0xFFEA833A),
      Color(0xFFE8743A),
    ],
  );

  static const daylight = ShelfColors(
    bg: Color(0xFFF4EDE2),
    surface: Color(0xFFFBF7F0),
    text: Color(0xFF2A1D16),
    muted: Color(0xFF665444),
    signal: Color(0xFFB06A00),
    line: Color(0x262A1D16),
    off: Color(0xFF857563),
    onAmber: Color(0xFF2A1D16),
    shadow: Color(0x265A3A1F),
    faceTop: Color(0xFFFFFFFF),
    faceBottom: Color(0xFFF1E9DE),
    pressedTop: Color(0xFFF7F2EA),
    pressedBottom: Color(0xFFECE3D6),
    side: Color(0xFFDCCFBE),
    sideRight: Color(0xFFCDBFAC),
    contact: Color(0xFFA8957D),
    highlight: Color(0xFFFFFFFF),
    edge: Color(0x265A3A1F),
    engrave: Color(0xCCFFFFFF),
    engraveLight: Color(0x10000000),
    window: Color(0xFFE4D8C8),
    windowGlow: Color(0x40F2B13A),
    press: Color(0x445A3A1F),
    meter: [
      Color(0xFFB06A00),
      Color(0xFFB16107),
      Color(0xFFB2580E),
      Color(0xFFB35015),
      Color(0xFFB4471C),
    ],
  );

  @override
  ShelfColors copyWith() => this;

  // The two themes are switched, not blended.
  @override
  ShelfColors lerp(ShelfColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension ShelfColorsContext on BuildContext {
  ShelfColors get shelf => Theme.of(this).extension<ShelfColors>()!;
}
