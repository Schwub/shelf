import 'package:material_ui/material_ui.dart';

import '../shelf/shelf_data.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/note.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';

/// Where looking up the track list on MusicBrainz stands.
enum TrackLookup { idle, loading, failed, none }

/// The album entry's track list: numbered tracks with a star for the
/// favorites, a MusicBrainz suggestion to approve, or ways to get one.
/// The entry holds the draft; this only shows it.
class TrackSection extends StatelessWidget {
  const TrackSection({
    super.key,
    required this.tracks,
    required this.onFavorite,
    required this.onEdit,
    this.suggestion,
    this.onUse,
    this.onDecline,
    this.lookup = TrackLookup.idle,
    this.onLookUp,
    this.showAll = false,
    this.onShowAll,
  });

  final List<Track> tracks;
  final ValueChanged<int> onFavorite;
  final VoidCallback onEdit;

  /// A MusicBrainz track list waiting for Use it or Not this one.
  final List<Track>? suggestion;
  final VoidCallback? onUse, onDecline;

  final TrackLookup lookup;

  /// Null for albums MusicBrainz doesn't know (added by hand).
  final VoidCallback? onLookUp;

  final bool showAll;
  final VoidCallback? onShowAll;

  /// Longer lists show the favorites (or the first tracks) until "Show all".
  static const shortList = 12;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium!.copyWith(color: c.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Tracks',
                  style: text.labelSmall!.copyWith(color: c.muted),
                ),
              ),
              if (suggestion == null)
                TextLink(
                  label: tracks.isEmpty ? 'Enter tracks' : 'Edit tracks',
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
        if (suggestion case final suggested?)
          _suggestion(context, suggested)
        else if (lookup == TrackLookup.loading)
          Row(
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.signal,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(child: Text('Looking up the track list…', style: muted)),
            ],
          )
        else if (tracks.isEmpty) ...[
          if (lookup == TrackLookup.failed)
            const HelpLine(
              'Couldn’t get the track list from MusicBrainz.',
              error: true,
            )
          else
            Text(
              lookup == TrackLookup.none
                  ? 'MusicBrainz has no track list for this album.'
                  : 'No track list yet.',
              style: muted,
            ),
          if (onLookUp case final lookUp? when lookup != TrackLookup.none)
            Align(
              alignment: Alignment.centerLeft,
              child: TextLink(
                label: lookup == TrackLookup.failed
                    ? 'Try again'
                    : 'Get track list',
                onPressed: lookUp,
              ),
            ),
        ] else
          ..._list(context),
      ],
    );
  }

  List<Widget> _list(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final favorites = [
      for (final (i, t) in tracks.indexed)
        if (t.favorite) i,
    ];
    final shown = showAll || tracks.length <= shortList
        ? [for (var i = 0; i < tracks.length; i++) i]
        : favorites.isNotEmpty
        ? favorites
        : [for (var i = 0; i < 5; i++) i];
    final discs = tracks.map((t) => t.disc).toSet().length > 1;
    return [
      for (final (n, i) in shown.indexed) ...[
        if (discs && (n == 0 || tracks[shown[n - 1]].disc != tracks[i].disc))
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              'Disc ${tracks[i].disc}',
              style: text.labelSmall!.copyWith(color: c.muted),
            ),
          ),
        _TrackRow(track: tracks[i], onFavorite: () => onFavorite(i)),
      ],
      if (shown.length < tracks.length)
        Align(
          alignment: Alignment.centerLeft,
          child: TextLink(
            label: 'Show all ${tracks.length} tracks',
            onPressed: onShowAll ?? () {},
          ),
        ),
    ];
  }

  Widget _suggestion(BuildContext context, List<Track> suggested) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return Note(
      icon: Icons.album_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Track list from MusicBrainz: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: suggested.length == 1
                      ? '1 track'
                      : '${suggested.length} tracks',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final t in suggested)
            Text(
              '${t.position}. ${t.title}',
              style: text.bodySmall!.copyWith(color: c.muted),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ShelfKey(
                  onPressed: onDecline,
                  child: const Text('Not this one'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShelfKey(
                  primary: true,
                  onPressed: onUse,
                  child: const Text('Use it'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "4:44"; null without a length.
String? trackLength(int? ms) {
  if (ms == null) return null;
  final s = (ms / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.track, required this.onFavorite});

  final Track track;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall!.copyWith(color: c.muted);
    final length = trackLength(track.lengthMs);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('${track.position}', style: muted)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(track.title, style: text.bodyMedium),
            ),
          ),
          if (length != null) Text(length, style: muted),
          Semantics(
            button: true,
            toggled: track.favorite,
            label: 'Favorite: ${track.title}',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onFavorite,
              child: SizedBox.square(
                dimension: 48,
                child: Icon(
                  track.favorite ? Icons.star : Icons.star_border,
                  size: 20,
                  color: track.favorite ? c.signal : c.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
