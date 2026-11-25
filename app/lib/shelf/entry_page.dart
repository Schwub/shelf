import 'package:material_ui/material_ui.dart';

import '../search/album_search.dart';
import '../theme/shelf_colors.dart';
import '../widgets/cover.dart';
import '../widgets/help_line.dart';
import '../widgets/rating_keys.dart';
import '../widgets/shelf_board.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'shelf_data.dart';

enum EntryResult { added, saved, removed }

/// An album on the shelf: change its rating and comment, or remove it (the
/// shelf removes it after the snackbar's Undo has passed). [EntryPage.add]
/// shows a search result to add instead. Tags are TASK-16.
class EntryPage extends StatefulWidget {
  const EntryPage({
    super.key,
    required ShelfEntry this.entry,
    required this.shelf,
  }) : result = null;

  const EntryPage.add({
    super.key,
    required SearchResult this.result,
    required this.shelf,
  }) : entry = null;

  final ShelfEntry? entry;
  final SearchResult? result;
  final ShelfRepository shelf;

  bool get adding => entry == null;

  Album get album =>
      entry?.album ??
      Album(
        id: '',
        musicbrainzId: result!.musicbrainzId,
        title: result!.title,
        artist: result!.artist,
        year: result!.year,
        coverUrl: result!.coverUrl,
      );

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  late int? _rating = widget.entry?.rating;
  late final _comment = TextEditingController(text: widget.entry?.comment);
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
      _comment.text.trim() != (widget.entry?.comment ?? '').trim();

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
      if (widget.adding) {
        await widget.shelf.add(
          widget.result!.musicbrainzId,
          rating: _rating,
          comment: _comment.text.trim(),
        );
      } else {
        await widget.shelf.save(
          widget.entry!.id,
          rating: _rating,
          comment: _comment.text.trim(),
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

  Future<bool> _confirmDiscard() async {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final discard = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x73000000),
      builder: (context) => Dialog(
        backgroundColor: c.bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: c.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Discard changes?', style: text.titleLarge),
              const SizedBox(height: 8),
              Text(
                "Your changes to this entry won't be saved.",
                style: text.bodyMedium!.copyWith(color: c.muted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ShelfKey(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Keep editing'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShelfKey(
                      primary: true,
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Discard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return discard ?? false;
  }

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
                          const SizedBox(height: 24),
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
                SizedBox(width: 200, child: Cover(album)),
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
