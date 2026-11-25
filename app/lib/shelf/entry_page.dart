import 'package:material_ui/material_ui.dart';

import '../search/album_search.dart';
import '../tags/tags_page.dart';
import '../theme/shelf_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/cover.dart';
import '../widgets/help_line.dart';
import '../widgets/rating_keys.dart';
import '../widgets/shelf_board.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'shelf_data.dart';
import 'tag_section.dart';

enum EntryResult { added, saved, removed }

/// An album on the shelf: change its rating and comment, or remove it (the
/// shelf removes it after the snackbar's Undo has passed). [EntryPage.add]
/// shows a search result to add instead, [EntryPage.manual] an album added
/// by hand.
class EntryPage extends StatefulWidget {
  const EntryPage({
    super.key,
    required ShelfEntry this.entry,
    required this.shelf,
    this.groups = const [],
  }) : result = null,
       manual = null;

  const EntryPage.add({
    super.key,
    required SearchResult this.result,
    required this.shelf,
    this.groups = const [],
  }) : entry = null,
       manual = null;

  const EntryPage.manual({
    super.key,
    required ManualAlbum this.manual,
    required this.shelf,
    this.groups = const [],
  }) : entry = null,
       result = null;

  final ShelfEntry? entry;
  final SearchResult? result;
  final ManualAlbum? manual;
  final ShelfRepository shelf;

  /// The user's visible tag groups, to tag the album with.
  final List<TagGroup> groups;

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
  late final _comment = TextEditingController(text: widget.entry?.comment);
  late Set<String> _initialTags = widget.entry?.tagIds ?? const {};
  late TagChoice _tags = TagChoice(widget.groups, _initialTags);
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _changed =>
      _rating != widget.entry?.rating ||
      _comment.text.trim() != (widget.entry?.comment ?? '').trim() ||
      _tags.chosen.length != _initialTags.length ||
      !_tags.chosen.containsAll(_initialTags);

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
        );
      } else if (widget.adding) {
        await widget.shelf.add(
          widget.result!.musicbrainzId,
          rating: _rating,
          comment: _comment.text.trim(),
          tags: _tags.ordered(_tags.chosen),
        );
      } else {
        await widget.shelf.save(
          widget.entry!.id,
          rating: _rating,
          comment: _comment.text.trim(),
          removeTags: _initialTags.difference(_tags.chosen),
          addTags: _tags.ordered(_tags.chosen.difference(_initialTags)),
        );
      }
      if (mounted) {
        Navigator.of(context)
            .pop(widget.adding ? EntryResult.added : EntryResult.saved);
      }
    } catch (_) {
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

  /// Opens the tag editor; the draft stays, on the edited tags.
  Future<void> _editTags() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TagsPage(shelf: widget.shelf)),
    );
    final Shelf shelf;
    try {
      shelf = await widget.shelf.load();
    } catch (_) {
      return; // The tags shown stay as they were.
    }
    if (!mounted) return;
    final existing = {
      for (final g in shelf.allGroups)
        for (final t in g.tags) t.id,
    };
    // Tags on the album from a hidden group stay on it.
    final shown = {
      for (final g in shelf.groups)
        for (final t in g.tags) t.id,
    };
    final chosen = {
      for (final id in _tags.chosen.intersection(existing))
        if (!shown.contains(id)) id,
    };
    for (final g in shelf.groups) {
      final inGroup = [
        for (final t in g.tags)
          if (_tags.chosen.contains(t.id)) t.id,
      ];
      // A group made one per album keeps the first of its chosen tags.
      chosen.addAll(g.exclusive ? inGroup.take(1) : inGroup);
    }
    setState(() {
      _initialTags = _initialTags.intersection(existing);
      _tags = TagChoice(shelf.groups, chosen);
    });
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
                          Text(album.title, style: text.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            [
                              album.artist,
                              if (album.year != null) '${album.year}',
                            ].join(', '),
                            style: text.bodyMedium!.copyWith(color: c.muted),
                          ),
                          const SizedBox(height: 16),
                          TagSection(
                            choice: _tags,
                            onChanged: (t) => setState(() => _tags = t),
                            onCreate: (group, name) =>
                                widget.shelf.createTag(group.id, name),
                            onEditTags: _editTags,
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
