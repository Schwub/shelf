import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/cover.dart';
import '../widgets/rating_meter.dart';
import '../widgets/shelf_board.dart';
import 'shelf_data.dart';

/// Spines standing on boards, artist and title rotated. Tapping a spine
/// pulls it up and shows its details below; tapping it again opens it.
class SpinesView extends StatefulWidget {
  const SpinesView({super.key, required this.entries, required this.onOpen});

  final List<ShelfEntry> entries;
  final ValueChanged<ShelfEntry> onOpen;

  static const spineWidth = 30.0, gap = 4.0;

  /// Spine colours until colours come from the covers: muted, warm and cool.
  static const _palette = [
    Color(0xFFE3E6E8),
    Color(0xFFC0392B),
    Color(0xFF2B2522),
    Color(0xFF2F5597),
    Color(0xFFB9A98A),
    Color(0xFFEDE3CC),
    Color(0xFF7D5BA6),
    Color(0xFF8E9BA6),
  ];

  /// Stable per album, so the shelf looks the same every time.
  static int _hash(String id) =>
      id.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x3fffffff);
  static Color colorOf(Album a) => _palette[_hash(a.id) % _palette.length];
  static double heightOf(Album a) => 156 + (_hash(a.id) ~/ 7 % 5) * 8;

  @override
  State<SpinesView> createState() => _SpinesViewState();
}

class _SpinesViewState extends State<SpinesView> {
  String? _pulled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const step = SpinesView.spineWidth + SpinesView.gap;
        final perRow = ((constraints.maxWidth - 40 + SpinesView.gap) ~/ step)
            .clamp(1, 1000);
        final entries = widget.entries;
        final rows = [
          for (var i = 0; i < entries.length; i += perRow)
            entries.sublist(i, (i + perRow).clamp(0, entries.length)),
        ];
        final pulled = entries.where((e) => e.id == _pulled).firstOrNull;
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            for (final row in rows) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, e) in row.indexed) ...[
                      if (i > 0) const SizedBox(width: SpinesView.gap),
                      _spine(context, e),
                    ],
                  ],
                ),
              ),
              const ShelfBoard(),
              if (pulled != null && row.contains(pulled))
                _details(context, pulled),
            ],
          ],
        );
      },
    );
  }

  Widget _spine(BuildContext context, ShelfEntry e) {
    final c = context.shelf;
    final color = SpinesView.colorOf(e.album);
    final pale = color.computeLuminance() > 0.5;
    final pulled = e.id == _pulled;
    return Semantics(
      button: true,
      selected: pulled,
      label: '${e.album.title} by ${e.album.artist}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => pulled ? widget.onOpen(e) : setState(() => _pulled = e.id),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 150),
          offset: Offset(0, pulled ? -8 / SpinesView.heightOf(e.album) : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: SpinesView.spineWidth,
                height: SpinesView.heightOf(e.album),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  border: pale ? Border.all(color: c.line) : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Center(
                    child: Text(
                      '${e.album.artist} · ${e.album.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: pale
                            ? ShelfColors.daylight.text
                            : ShelfColors.evening.text,
                      ),
                    ),
                  ),
                ),
              ),
              // The signal light at the foot of a pulled spine.
              if (pulled)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 6,
                  height: 4,
                  color: c.signal,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _details(BuildContext context, ShelfEntry e) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final year = e.album.year == null ? '' : ', ${e.album.year}';
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onOpen(e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              SizedBox(width: 56, child: Cover(e.album)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.album.title, style: text.titleMedium),
                    Text(
                      '${e.album.artist}$year',
                      style: text.bodySmall!.copyWith(color: c.muted),
                    ),
                    if (e.rating case final rating?) ...[
                      const SizedBox(height: 8),
                      RatingMeter(rating),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
