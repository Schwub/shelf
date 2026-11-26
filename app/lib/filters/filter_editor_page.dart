import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../shelf/shelf.dart';
import '../shelf/shelf_repository.dart';
import '../theme/shelf_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/dates.dart';
import '../widgets/help_line.dart';
import '../widgets/rating_keys.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';
import 'tag_picker.dart';

/// A filter's conditions: tags (any or all of them), a minimum rating or
/// unrated, favorite tracks, with how many albums match. A new one when
/// [filter] is null. Pops after Save or Delete.
class FilterEditorPage extends StatefulWidget {
  const FilterEditorPage({
    super.key,
    required this.repository,
    required this.shelf,
    this.filter,
  });

  final ShelfRepository repository;

  /// For the tags to choose from and the albums to count.
  final Shelf shelf;
  final ShelfFilter? filter;

  @override
  State<FilterEditorPage> createState() => _FilterEditorPageState();
}

class _FilterEditorPageState extends State<FilterEditorPage> {
  late ShelfFilter _draft = widget.filter ?? const ShelfFilter();
  late final _name = TextEditingController(text: widget.filter?.name ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Map<String, String> get _tagNames => {
    for (final g in widget.shelf.allGroups)
      for (final t in g.tags) t.id: t.name,
  };

  Future<void> _pickTags() async {
    final picked = await showTagPicker(
      context,
      title: 'Tags',
      groups: widget.shelf.groups,
      chosen: _draft.tagIds.toSet(),
      multiple: true,
    );
    if (picked != null && mounted) {
      setState(() => _draft = _draft.copyWith(tagIds: picked.toList()));
    }
  }

  Future<void> _save() async {
    final draft = _draft.copyWith(name: _name.text.trim());
    final error = !draft.hasConditions
        ? 'Choose at least one condition.'
        : !draft.isTag && draft.name!.isEmpty
        ? 'Give the filter a name.'
        : null;
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _saving = true);
    try {
      await widget.repository.saveFilter(draft);
      if (mounted) Navigator.of(context).pop();
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Couldn’t save the filter. Check your connection and try '
              'again.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final filter = widget.filter!;
    if (!await confirm(
      context,
      title: 'Delete “${filter.label}”?',
      text: 'It leaves the filter bar. Albums and tags stay as they are.',
      cancel: 'Cancel',
      confirm: 'Delete',
      primary: false,
    )) {
      return;
    }
    try {
      await widget.repository.deleteFilter(filter.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _error = 'Couldn’t delete the filter.');
    }
  }

  bool get _between => _draft.addedFrom != null || _draft.addedTo != null;

  /// Between two days, from the date range picker; tapped again, the range
  /// goes.
  Future<void> _pickDays() async {
    if (_between) {
      setState(
        () => _draft = _draft.copyWith(
          addedFrom: () => null,
          addedTo: () => null,
        ),
      );
      return;
    }
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (range == null || !mounted) return;
    setState(
      () => _draft = _draft.copyWith(
        addedWithinDays: () => null,
        addedFrom: () => range.start,
        addedTo: () => range.end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final label = text.labelSmall!.copyWith(color: c.muted);
    final hint = text.bodySmall!.copyWith(color: c.muted);
    Widget heading(String name, {Widget? action}) => SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(child: Text(name, style: label)),
          ?action,
        ],
      ),
    );
    final matches = _draft.hasConditions
        ? widget.shelf.entries.where(_draft.matches).length
        : null;
    final names = _tagNames;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  ShelfKey(
                    semanticLabel: 'Back',
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.filter == null ? 'New filter' : 'Filter',
                      style: text.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  heading('Name'),
                  ShelfField(
                    controller: _name,
                    hintText: _draft.isTag
                        ? names[_draft.tagIds.single] ?? 'Name'
                        : 'e.g. Best of my vinyl',
                  ),
                  if (_draft.isTag) ...[
                    const SizedBox(height: 8),
                    Text('One tag alone shows by the tag’s name.', style: hint),
                  ],
                  heading(
                    'Tags',
                    action: TextLink(
                      label: 'Add',
                      icon: Icons.add,
                      semanticLabel: 'Add tags',
                      onPressed: _pickTags,
                    ),
                  ),
                  if (_draft.tagIds.isEmpty)
                    Text('Any tags', style: hint)
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final id in _draft.tagIds)
                          ShelfKey(
                            semanticLabel: 'Remove ${names[id]}',
                            onPressed: () => setState(
                              () => _draft = _draft.copyWith(
                                tagIds: [
                                  for (final t in _draft.tagIds)
                                    if (t != id) t,
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ExcludeSemantics(child: Text(names[id] ?? '?')),
                                const SizedBox(width: 6),
                                Icon(Icons.close, size: 16, color: c.muted),
                              ],
                            ),
                          ),
                      ],
                    ),
                  if (_draft.tagIds.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final (all, name) in [
                          (false, 'Any of them'),
                          (true, 'All of them'),
                        ]) ...[
                          if (all) const SizedBox(width: 8),
                          Expanded(
                            child: ShelfKey(
                              light: true,
                              selected: _draft.matchAll == all,
                              onPressed: () => setState(
                                () => _draft = _draft.copyWith(matchAll: all),
                              ),
                              child: Text(name),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  heading(
                    'Rating',
                    action: Text(
                      _draft.minRating == null
                          ? (_draft.unrated ? 'Unrated' : 'Any')
                          : 'At least ${RatingKeys.describe(_draft.minRating)}',
                      style: label,
                    ),
                  ),
                  RatingKeys(
                    value: _draft.minRating,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(
                        minRating: () => v,
                        unrated: v == null ? null : false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ShelfKey(
                      light: true,
                      selected: _draft.unrated,
                      onPressed: () => setState(
                        () => _draft = _draft.copyWith(
                          unrated: !_draft.unrated,
                          minRating: () => null,
                        ),
                      ),
                      child: const Text('Unrated'),
                    ),
                  ),
                  heading('Tracks'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ShelfKey(
                      light: true,
                      selected: _draft.favoriteTracks,
                      onPressed: () => setState(
                        () => _draft = _draft.copyWith(
                          favoriteTracks: !_draft.favoriteTracks,
                        ),
                      ),
                      child: const Text('Has favorite tracks'),
                    ),
                  ),
                  heading(
                    'Added',
                    action: Text(
                      describeAdded(_draft) ?? 'Any time',
                      style: label,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (days, name) in withinDays)
                        ShelfKey(
                          light: true,
                          selected: _draft.addedWithinDays == days,
                          onPressed: () => setState(
                            () => _draft = _draft.copyWith(
                              addedWithinDays: () =>
                                  _draft.addedWithinDays == days ? null : days,
                              addedFrom: () => null,
                              addedTo: () => null,
                            ),
                          ),
                          child: Text(name),
                        ),
                      ShelfKey(
                        light: true,
                        selected: _between,
                        onPressed: _pickDays,
                        child: const Text('Between…'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(switch (matches) {
                    null => 'Choose at least one condition.',
                    1 => 'Matches 1 album',
                    final n => 'Matches $n albums',
                  }, style: text.titleMedium),
                  if (_error case final error?) ...[
                    const SizedBox(height: 12),
                    HelpLine(error, error: true),
                  ],
                  if (widget.filter != null) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ShelfKey(
                        onPressed: _delete,
                        child: const Text('Delete filter'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ShelfKey(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShelfKey(
                        primary: true,
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving…' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The editor's choices for albums added lately.
const withinDays = [
  (7, 'Last 7 days'),
  (30, 'Last 30 days'),
  (90, 'Last 90 days'),
  (365, 'Last year'),
];

/// "Last 30 days", "1 Jun 2026 – 31 Aug 2026", "Since 1 Jun 2026"; null
/// without a date condition.
String? describeAdded(ShelfFilter f) => switch (f) {
  ShelfFilter(addedWithinDays: final days?) =>
    withinDays.where((w) => w.$1 == days).firstOrNull?.$2 ?? 'Last $days days',
  ShelfFilter(addedFrom: final from?, addedTo: final to?) =>
    '${formatDay(from)} – ${formatDay(to)}',
  ShelfFilter(addedFrom: final from?) => 'Since ${formatDay(from)}',
  ShelfFilter(addedTo: final to?) => 'Until ${formatDay(to)}',
  _ => null,
};
