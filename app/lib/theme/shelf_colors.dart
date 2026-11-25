import 'package:material_ui/material_ui.dart';

/// The themes to choose from; tobacco is the default.
enum AppTheme {
  tobacco('Tobacco & copper', ShelfColors.tobacco),
  evening('Evening', ShelfColors.evening),
  daylight('Daylight', ShelfColors.daylight);

  const AppTheme(this.label, this.colors);

  final String label;
  final ShelfColors colors;
}

/// Colour tokens from docs/design/visual-system.md: tobacco, evening and
/// daylight.
@immutable
class ShelfColors extends ThemeExtension<ShelfColors> {
  const ShelfColors({
    required this.brightness,
    required this.lights,
    required this.teak,
    required this.primaryStart,
    required this.primaryEnd,
    required this.primarySide,
    required this.primarySideRight,
    required this.primaryContact,
    required this.primaryHighlight,
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

  final Brightness brightness;

  /// Chosen keys light their window (evening, daylight). Without lights
  /// (tobacco), a chosen key is pressed, its face tinted and its label in
  /// the signal colour.
  final bool lights;

  /// Shelf boards and the filter bar's board.
  final Color teak;

  /// The primary key: face from start to end (the same colour for a flat
  /// face), its sides, contact line and top-left highlight.
  final Color primaryStart, primaryEnd, primarySide, primarySideRight;
  final Color primaryContact, primaryHighlight;

  final Color bg, surface, text, muted, signal, line, off, onAmber, shadow;

  /// Key face gradient at rest and pressed.
  final Color faceTop, faceBottom, pressedTop, pressedBottom;

  /// Key sides: front, right (darker, away from the light), contact line.
  final Color side, sideRight, contact;

  /// Key details: top-left highlight, drop shadow, engraved label, light window.
  final Color highlight, edge, engrave, engraveLight, window, windowGlow;

  /// Inner shadow of recessed fields.
  final Color press;

  /// The five rating bars (amber to coral, or one colour).
  final List<Color> meter;

  /// Warmer and calmer: no gradients and no light windows, so covers carry
  /// the colour (docs/design/visual/variations/themes-warm.html, 2).
  static const tobacco = ShelfColors(
    brightness: Brightness.dark,
    lights: false,
    teak: Color(0xFF94603F),
    primaryStart: Color(0xFFB4764F),
    primaryEnd: Color(0xFFB4764F),
    primarySide: Color(0xFF7A4A2E),
    primarySideRight: Color(0xFF693F27),
    primaryContact: Color(0xFF3E2416),
    primaryHighlight: Color(0xFFD9A07A),
    bg: Color(0xFF231812),
    surface: Color(0xFF2E2019),
    text: Color(0xFFF0E2D2),
    muted: Color(0xFFB79E8A),
    signal: Color(0xFFC88A63),
    line: Color(0x1CF0E2D2),
    off: Color(0xFF806B5C),
    onAmber: Color(0xFF1F140E),
    shadow: Color(0x59000000),
    faceTop: Color(0xFF3B2A21),
    faceBottom: Color(0xFF2E2019),
    // The pressed face takes 14 % of the signal colour.
    pressedTop: Color(0xFF473125),
    pressedBottom: Color(0xFF3E2A1F),
    side: Color(0xFF1C130E),
    sideRight: Color(0xFF150E0A),
    contact: Color(0xFF080503),
    highlight: Color(0x1CFFFFFF),
    edge: Color(0x66000000),
    engrave: Color(0x99000000),
    engraveLight: Color(0x14FFFFFF),
    window: Color(0xFF0F0A07),
    windowGlow: Color(0x00000000),
    press: Color(0x88000000),
    meter: [
      Color(0xFFC88A63),
      Color(0xFFC88A63),
      Color(0xFFC88A63),
      Color(0xFFC88A63),
      Color(0xFFC88A63),
    ],
  );

  /// The original theme: amber-to-coral and light windows.
  static const evening = ShelfColors(
    brightness: Brightness.dark,
    lights: true,
    teak: Color(0xFFA87445),
    primaryStart: Color(0xFFF2B13A),
    primaryEnd: Color(0xFFE8743A),
    primarySide: Color(0xFFB4501E),
    primarySideRight: Color(0xFF9E4418),
    primaryContact: Color(0xFF7A3010),
    primaryHighlight: Color(0xFFFFD98A),
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
    brightness: Brightness.light,
    lights: true,
    teak: Color(0xFFA87445),
    primaryStart: Color(0xFFF2B13A),
    primaryEnd: Color(0xFFE8743A),
    primarySide: Color(0xFFB4501E),
    primarySideRight: Color(0xFF9E4418),
    primaryContact: Color(0xFF7A3010),
    primaryHighlight: Color(0xFFFFD98A),
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

  // Themes are switched, not blended.
  @override
  ShelfColors lerp(ShelfColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension ShelfColorsContext on BuildContext {
  ShelfColors get shelf => Theme.of(this).extension<ShelfColors>()!;
}
