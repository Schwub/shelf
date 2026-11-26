import 'package:flutter/foundation.dart';

import '../errors.dart';

import 'package:material_ui/material_ui.dart';

import '../search/album_search.dart';
import '../theme/shelf_colors.dart';
import '../tracks/track_editor_page.dart';
import '../tracks/track_section.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/cover.dart';
import '../widgets/help_line.dart';
import '../widgets/note.dart';
import '../widgets/rating_keys.dart';
import '../widgets/shelf_board.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'shelf.dart';
import 'import_tags_sheet.dart';
import 'shelf_repository.dart';
import 'tag_import.dart';
import 'tag_section.dart';

enum EntryResult { added, saved, removed }

/// An album on the shelf: change its rating and comment, or remove it (the
/// shelf removes it after the snackbar's Undo has passed). [EntryPage.add]
/// shows a search result to add instead, [EntryPage.manual] an album added
/// by hand; either can come [fromFriend], with their tags.
class EntryPage extends StatefulWidget {
  const EntryPage({
    super.key,
    required ShelfEntry this.entry,
    required this.shelf,
    this.groups = const [],
  }) : result = null,
       manual = null,
       fromFriend = null,
       tracks = const [];

  const EntryPage.add({
    super.key,
    required SearchResult this.result,
    required this.shelf,
    this.groups = const [],
    this.fromFriend,
    this.tracks = const [],
  }) : entry = null,
       manual = null;

  const EntryPage.manual({
    super.key,
    required ManualAlbum this.manual,
    required this.shelf,
    this.groups = const [],
    this.fromFriend,
    this.tracks = const [],
  }) : entry = null,
       result = null;

  final ShelfEntry? entry;
  final SearchResult? result;
  final ManualAlbum? manual;
  final ShelfRepository shelf;

  /// The user's visible tag groups, to tag the album with.
  final List<TagGroup> groups;

  /// Adding a friend's album: their tags the user has are set, and the
  /// missing ones offered once the page shows.
  final TagImport? fromFriend;

  /// The track list to start an added album with (a friend's); without one,
  /// MusicBrainz's is suggested.
  final List<Track> tracks;

  bool get adding => entry == null;

  Album get album =>
      entry?.album ??
      switch ((result, manual)) {
        (final r?, _) => Album(
          id: '',
          musicbrainzId: r.musicbrainzId,
          title: r.title,
          artist: r.artist,
          year: r.year,
          coverUrl: r.coverUrl,
        ),
        (_, final m?) => Album(
          id: '',
          title: m.title,
          artist: m.artist,
          year: m.year,
        ),
        _ => throw StateError('nothing to show'),
      };

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  late int? _rating = widget.entry?.rating;
  late bool _hidden = widget.entry?.hidden ?? false;
  late final _comment = TextEditingController(text: widget.entry?.comment);
  late final Set<String> _initialTags =
      widget.entry?.tagIds ?? widget.fromFriend?.preset ?? const {};
  late TagChoice _tags = TagChoice(widget.groups, _initialTags);
  bool _saving = false;
  bool _saveFailed = false;

  late final List<Track> _initialTracks = widget.entry?.tracks ?? widget.tracks;
  late List<Track> _tracks = _initialTracks;

  /// A MusicBrainz track list waiting for Use it or Not this one.
  List<Track>? _suggestion;
  TrackLookup _lookup = TrackLookup.idle;
  bool _allTracks = false;

  String? get _musicbrainzId =>
      widget.entry?.album.musicbrainzId ?? widget.result?.musicbrainzId;

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
    // A new album from MusicBrainz without a track list (a friend's) comes
    // with MusicBrainz's to approve.
    if (widget.adding && _tracks.isEmpty && _musicbrainzId != null) {
      _lookUpTracks();
    }
    if (widget.fromFriend?.missing.isNotEmpty ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _importTags());
    }
  }

  Future<void> _importTags() async {
    if (!mounted) return;
    final copied = await showImportTagsSheet(
      context,
      plan: widget.fromFriend!,
      shelf: widget.shelf,
    );
    if (copied == null || !mounted) return;
    setState(
      () => _tags = TagChoice(copied.mine.groups, {
        ..._tags.chosen,
        ...copied.preset,
      }),
    );
  }

  Future<void> _lookUpTracks() async {
    setState(() => _lookup = TrackLookup.loading);
    try {
      final tracks = await widget.shelf.trackList(_musicbrainzId!);
      if (!mounted) return;
      setState(() {
        _lookup = tracks.isEmpty ? TrackLookup.none : TrackLookup.idle;
        _suggestion = tracks.isEmpty ? null : tracks;
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _lookup = TrackLookup.failed);
    }
  }

  Future<void> _editTracks() async {
    final tracks = await Navigator.of(context).push(
      MaterialPageRoute<List<Track>>(
        builder: (_) => TrackEditorPage(tracks: _tracks),
      ),
    );
    if (tracks != null && mounted) setState(() => _tracks = tracks);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _changed =>
      _rating != widget.entry?.rating ||
      _hidden != (widget.entry?.hidden ?? false) ||
      _comment.text.trim() != (widget.entry?.comment ?? '').trim() ||
      _tags.chosen.length != _initialTags.length ||
      !_tags.chosen.containsAll(_initialTags) ||
      !listEquals(_tracks, _initialTracks);

  Future<void> _save() async {
    if (!widget.adding && !_changed) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      if (widget.manual case final manual?) {
        await widget.shelf.addManual(
          manual,
          rating: _rating,
          comment: _comment.text.trim(),
          tags: _tags.ordered(_tags.chosen),
          tracks: _tracks,
          hidden: _hidden,
          addedFrom: widget.fromFriend?.from,
        );
      } else if (widget.adding) {
        await widget.shelf.add(
          widget.result!.musicbrainzId,
          rating: _rating,
          comment: _comment.text.trim(),
          tags: _tags.ordered(_tags.chosen),
          tracks: _tracks,
          hidden: _hidden,
          addedFrom: widget.fromFriend?.from,
        );
      } else {
        await widget.shelf.save(
          widget.entry!.id,
          rating: _rating,
          comment: _comment.text.trim(),
          removeTags: _initialTags.difference(_tags.chosen),
          addTags: _tags.ordered(_tags.chosen.difference(_initialTags)),
          tracks: listEquals(_tracks, _initialTracks) ? null : _tracks,
          hidden: _hidden != widget.entry!.hidden ? _hidden : null,
        );
      }
      if (mounted) {
        Navigator.of(context)
            .pop(widget.adding ? EntryResult.added : EntryResult.saved);
      }
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
    }
  }

  /// Leaves without saving; asks first when something changed.
  Future<void> _leave() async {
    if (!_changed || await _confirmDiscard()) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmDiscard() => confirm(
    context,
    title: 'Discard changes?',
    text: "Your changes to this entry won't be saved.",
    cancel: 'Keep editing',
    confirm: 'Discard',
  );

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final album = widget.album;
    final label = text.labelSmall!.copyWith(color: c.muted);
    final addedFrom =
        widget.entry?.addedFromName ?? widget.fromFriend?.from.name;
    final setLike = widget.fromFriend?.builtins ?? const [];
    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _stage(album),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (setLike.isNotEmpty) ...[
                            Note(
                              icon: Icons.info_outline,
                              child: Text(
                                '${[for (final t in setLike) t.name].join(' and ')} '
                                "${setLike.length == 1 ? 'is' : 'are'} set "
                                "like ${widget.fromFriend!.from.name}'s.",
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(album.title, style: text.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            [
                              album.artist,
                              if (album.year != null) '${album.year}',
                            ].join(', '),
                            style: text.bodyMedium!.copyWith(color: c.muted),
                          ),
                          if (addedFrom != null) ...[
                            const SizedBox(height: 4),
                            HelpLine("Added from $addedFrom's shelf"),
                          ],
                          const SizedBox(height: 16),
                          TagSection(
                            choice: _tags,
                            onChanged: (t) => setState(() => _tags = t),
                            onCreate: (group, name) =>
                                widget.shelf.createTag(group.id, name),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Text('Rating', style: label)),
                              Text(
                                _rating == null
                                    ? 'None'
                                    : RatingKeys.describe(_rating),
                                style: label,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RatingKeys(
                            value: _rating,
                            onChanged: (v) => setState(() => _rating = v),
                          ),
                          const SizedBox(height: 24),
                          Text('Comment', style: label),
                          const SizedBox(height: 8),
                          ShelfField(
                            controller: _comment,
                            hintText: 'Comment (optional)',
                            minLines: 3,
                            maxLines: 8,
                          ),
                          const SizedBox(height: 16),
                          TrackSection(
                            tracks: _tracks,
                            onFavorite: (i) => setState(
                              () => _tracks = [
                                for (final (j, t) in _tracks.indexed)
                                  j == i
                                      ? t.copyWith(favorite: !t.favorite)
                                      : t,
                              ],
                            ),
                            onEdit: _editTracks,
                            suggestion: _suggestion,
                            onUse: () => setState(() {
                              _tracks = _suggestion!;
                              _suggestion = null;
                            }),
                            onDecline: () => setState(() => _suggestion = null),
                            lookup: _lookup,
                            onLookUp: _musicbrainzId == null
                                ? null
                                : _lookUpTracks,
                            showAll: _allTracks,
                            onShowAll: () => setState(() => _allTracks = true),
                          ),
                          const SizedBox(height: 24),
                          Text('Friends', style: label),
                          MergeSemantics(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Hide from friends'),
                                      HelpLine(
                                        "Friends don't see this album, and "
                                        'it stays out of the feed.',
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _hidden,
                                  onChanged: (v) => setState(() => _hidden = v),
                                ),
                              ],
                            ),
                          ),
                          if (!widget.adding) ...[
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ShelfKey(
                                onPressed: () =>
                                    Navigator.of(context)
                                        .pop(EntryResult.removed),
                                child: const Text('Remove from shelf'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  /// The cover standing on its board, with the close key.
  Widget _stage(Album album) {
    final photo = widget.manual?.cover;
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
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
                            child: Image.memory(photo, fit: BoxFit.cover),
                          ),
                        )
                      : Cover(album),
                ),
                const ShelfBoard(),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 20,
            child: ShelfKey(
              semanticLabel: 'Close',
              padding: EdgeInsets.zero,
              onPressed: _leave,
              child: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    final c = context.shelf;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_saveFailed) ...[
              HelpLine(
                widget.adding
                    ? "Couldn't add the album. Try again."
                    : "Couldn't save. Try again.",
                error: true,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: ShelfKey(
                    onPressed: _saving ? null : _leave,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShelfKey(
                    primary: true,
                    onPressed: _saving ? null : _save,
                    child: Text(
                      widget.adding
                          ? (_saving ? 'Adding…' : 'Add to shelf')
                          : (_saving ? 'Saving…' : 'Save'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
