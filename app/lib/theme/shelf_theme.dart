import 'package:material_ui/material_ui.dart';

import 'shelf_colors.dart';

/// Archivo is bundled as a variable font: width and weight are axes.
TextStyle archivo(double size, {double width = 112, double weight = 600}) =>
    TextStyle(
      fontFamily: 'Archivo',
      fontSize: size,
      fontVariations: [
        FontVariation.width(width),
        FontVariation.weight(weight),
      ],
      fontFeatures: const [FontFeature.tabularFigures()],
    );

TextStyle plex(double size, {double weight = 400}) => TextStyle(
  fontFamily: 'IBM Plex Sans',
  fontSize: size,
  fontVariations: [FontVariation.weight(weight)],
);

/// The app theme: evening for dark, daylight for light (follows the system).
ThemeData shelfTheme(Brightness brightness) {
  final c = brightness == Brightness.dark
      ? ShelfColors.evening
      : ShelfColors.daylight;
  // The six sizes of the visual system.
  final text = TextTheme(
    headlineSmall: archivo(24, width: 125, weight: 700),
    titleLarge: archivo(18, width: 125, weight: 700),
    titleMedium: plex(15, weight: 600),
    bodyMedium: plex(14),
    labelLarge: archivo(13),
    labelMedium: plex(13, weight: 600),
    bodySmall: plex(12),
    labelSmall: plex(12, weight: 600),
  ).apply(bodyColor: c.text, displayColor: c.text);
  return ThemeData(
    brightness: brightness,
    fontFamily: 'IBM Plex Sans',
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.signal,
      onPrimary: c.onAmber,
      secondary: c.signal,
      onSecondary: c.onAmber,
      error: c.signal,
      onError: c.onAmber,
      surface: c.bg,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      outline: c.line,
    ),
    textTheme: text,
    extensions: [c],
  );
}
