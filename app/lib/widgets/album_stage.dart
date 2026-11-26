import 'dart:typed_data';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import '../shelf/shelf.dart';
import '../theme/shelf_colors.dart';
import 'cover.dart';
import 'shelf_board.dart';

/// The top of a screen showing one album: its cover standing on a board,
/// with the cover blurred and zoomed in behind it (docs/design/visual/
/// variations/cover-background.html, option A). [photo] is a cover picked
/// for an album added by hand; [leading] sits top left (Back), [action] top
/// right (Close).
class AlbumStage extends StatelessWidget {
  const AlbumStage(
    this.album, {
    super.key,
    this.photo,
    this.leading,
    this.action,
  });

  final Album album;
  final Uint8List? photo;
  final Widget? leading, action;

  /// How far the blur reaches below the board, fading into the page; it
  /// lies under what follows, so the layout stays as without it.
  static const _below = 56.0;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final ImageProvider? image = switch ((photo, album.coverUrl)) {
      (final bytes?, _) => MemoryImage(bytes),
      (null, final url?) => NetworkImage(url),
      _ => null,
    };
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (image != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: -_below,
              child: IgnorePointer(child: _Glow(image, colors: c)),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  child: photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.memory(photo!, fit: BoxFit.cover),
                          ),
                        )
                      : Cover(album),
                ),
                const ShelfBoard(),
              ],
            ),
          ),
          if (leading != null) Positioned(top: 12, left: 20, child: leading!),
          if (action != null) Positioned(top: 12, right: 20, child: action!),
        ],
      ),
    );
  }
}

/// The blurred cover, fading into the page background towards the bottom;
/// fainter on light themes, where colour shows more.
class _Glow extends StatelessWidget {
  const _Glow(this.image, {required this.colors});

  final ImageProvider image;
  final ShelfColors colors;

  @override
  Widget build(BuildContext context) {
    final light = colors.brightness == Brightness.light;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: light ? 0.45 : 0.55,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 36,
                sigmaY: 36,
                tileMode: TileMode.decal,
              ),
              child: Transform.scale(
                scale: 1.4,
                child: Image(
                  image: image,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.45, 1],
                colors: [colors.bg.withValues(alpha: 0), colors.bg],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
