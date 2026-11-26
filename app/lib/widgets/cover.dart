import 'package:material_ui/material_ui.dart';

import '../shelf/shelf.dart';
import '../theme/shelf_colors.dart';

/// An album cover with 2 px corners; a surface block while loading and when
/// the album has none.
class Cover extends StatelessWidget {
  const Cover(this.album, {super.key});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final blank = ColoredBox(color: c.surface);
    final url = album.coverUrl;
    return Semantics(
      image: true,
      label: 'Cover of ${album.title}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: AspectRatio(
          aspectRatio: 1,
          child: url == null
              ? blank
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : blank,
                  errorBuilder: (context, error, stack) => blank,
                ),
        ),
      ),
    );
  }
}
