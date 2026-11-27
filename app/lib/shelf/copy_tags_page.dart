import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';
import 'shelf.dart';
import 'shelf_repository.dart';
import 'tag_import.dart';
import 'tag_sheet.dart';
import '../widgets/shelf_sheet.dart';

/// What "Anna's tags" ends with: the plan as it is now, and the tags to set
/// on the album, or null to leave them (Skip, Back).
typedef CopyTagsResult = ({TagImport plan, Set<String>? tagIds});

/// "Anna's tags" (TASK-48, docs/design/wireframes/copy-tags.html): the
/// friend's tags on the album, none ticked. Each goes where its target says,
/// into any of the user's groups or tags; a group the user picks for a
/// friend's group is remembered for that friend.
class CopyTagsPage extends StatefulWidget {
  const CopyTagsPage({super.key, required this.plan, required this.shelf});

  final TagImport plan;
  final ShelfRepository shelf;

  @override
  State<CopyTagsPage> createState() => _CopyTagsPageState();
}

class _CopyTagsPageState extends State<CopyTagsPage> {
  late TagImport _plan = widget.plan;

  /// Targets picked for one tag, for this album only.
  final _overrides = <String, TagTarget>{};
  final _ticked = <String>{};
  bool _applying = false, _failed = false;

  TagTarget _target(Tag t) => _overrides[t.id] ?? _plan.suggest(t, _overrides);

  /// The parent tag of the friend's [tagId] (a row too).
  String? _parent(String tagId) => _plan.groupOf(tagId).parentTagId;

  /// A sub-tag goes with its parent: ticking it ticks the parent, unticking
  /// the parent unticks it.
  void _toggle(String tagId) => setState(() {
    if (_ticked.remove(tagId)) {
      for (final t in _plan.rows) {
        for (String? p = _parent(t.id); p != null; p = _parent(p)) {
          if (p == tagId) _ticked.remove(t.id);
        }
      }
      return;
    }
    for (String? t = tagId; t != null; t = _parent(t)) {
      _ticked.add(t);
    }
  });

  List<Tag> get _matching => [
    for (final t in _plan.rows)
      if (!_ticked.contains(t.id) && _target(t).matches) t,
  ];

  void _tickMatching() => setState(() {
    for (final t in _matching) {
      for (String? id = t.id; id != null; id = _parent(id)) {
        _ticked.add(id);
      }
    }
  });

  Future<void> _choose(Tag tag) async {
    final picked = await _pickTarget(tag);
    if (picked == null || !mounted) return;
    final theirGroup = _plan.groupOf(tag.id);
    final group = picked.group;
    // Another of the user's groups for a top-level group of the friend's:
    // the default for all its tags, from now on.
    if (theirGroup.parentTagId == null &&
        group != null &&
        group.id != _plan.suggest(tag, _overrides).group?.id) {
      setState(() => _plan = _plan.withDestination(theirGroup.id, group.id));
      try {
        await widget.shelf.saveDestination(theirGroup.id, group.id);
      } catch (e, stack) {
        // Still used for this album; only remembering it failed.
        reportError(e, stack);
      }
    }
    if (!mounted) return;
    setState(() {
      // Its sub-tags follow it again.
      for (final t in _plan.rows) {
        for (String? p = _parent(t.id); p != null; p = _parent(p)) {
          if (p == tag.id) _overrides.remove(t.id);
        }
      }
      _overrides.remove(tag.id);
      if (picked != _plan.suggest(tag, _overrides)) _overrides[tag.id] = picked;
    });
  }

  /// Any of the user's groups, and in each its tags or a new one; null when
  /// dismissed.
  Future<TagTarget?> _pickTarget(Tag tag) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final current = _target(tag);
    final theirGroup = _plan.groupOf(tag.id);
    final mine = _plan.mine;
    final tagNames = {
      for (final g in mine.allGroups)
        for (final t in g.tags) t.id: t.name,
    };
    String title(TagGroup g) => switch (g.parentTagId) {
      final p? => '${g.name} · under ${tagNames[p]}',
      null => g.name,
    };
    bool has(TagGroup g) =>
        g.tags.any((t) => t.name.toLowerCase() == tag.name.toLowerCase());
    // The likely places first: where it goes now, then groups that have a
    // tag of that name.
    final groups = [
      ...mine.groups.where((g) => g.id == current.group?.id),
      ...mine.groups.where((g) => g.id != current.group?.id && has(g)),
      ...mine.groups.where((g) => g.id != current.group?.id && !has(g)),
    ];
    return showShelfSheet<TagTarget>(
      context: context,
      builder: (context) {
        void pick(TagTarget t) => Navigator.of(context).pop(t);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${tag.name} goes to', style: text.titleLarge),
                if (theirGroup.parentTagId == null) ...[
                  const SizedBox(height: 4),
                  HelpLine(
                    "Another group becomes the default for "
                    "${_plan.from.name}'s ${theirGroup.name}.",
                  ),
                ],
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final g in groups) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 4),
                          child: Text(
                            title(g),
                            style: text.labelSmall!.copyWith(color: c.muted),
                          ),
                        ),
                        for (final t in g.tags)
                          TagRow(
                            title: t.name,
                            chosen: current.tag?.id == t.id,
                            onTap: () => pick(TagTarget(group: g, tag: t)),
                          ),
                        if (!has(g))
                          TagRow(
                            title: 'New “${tag.name}” here',
                            create: true,
                            onTap: () => pick(TagTarget(group: g)),
                          ),
                      ],
                      const SizedBox(height: 16),
                      TagRow(
                        title: 'New group “${theirGroup.name}”',
                        subtitle: theirGroup.exclusive
                            ? 'one per album'
                            : 'several per album',
                        create: true,
                        onTap: () => pick(const TagTarget()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _apply() async {
    setState(() {
      _applying = true;
      _failed = false;
    });
    try {
      final (:mine, :tagIds) = await _plan.apply(widget.shelf, {
        for (final t in _plan.rows)
          if (_ticked.contains(t.id)) t.id: _target(t),
      });
      if (mounted) {
        Navigator.of(context)
            .pop<CopyTagsResult>((plan: _plan.withMine(mine), tagIds: tagIds));
      }
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) {
        setState(() {
          _applying = false;
          _failed = true;
        });
      }
    }
  }

  void _leave() =>
      Navigator.of(context).pop<CopyTagsResult>((plan: _plan, tagIds: null));

  /// Where a tag goes, in a few words.
  String _describe(Tag tag, TagTarget t) => switch (t) {
    TagTarget(:final tag?, :final group?) => '${group.name}: ${tag.name}',
    TagTarget(:final group?) => '${group.name}: new',
    _ => 'New group ${_plan.groupOf(tag.id).name}',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final name = _plan.from.name;
    final count = _ticked.length;
    final matching = _matching.length;
    return PopScope(
      // Back, like Skip, keeps the groups chosen here.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_applying) _leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    ShelfKey(
                      semanticLabel: 'Back',
                      padding: EdgeInsets.zero,
                      onPressed: _applying ? null : _leave,
                      child: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text("$name's tags", style: text.headlineSmall),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    HelpLine(
                      "Tick the tags you want on your album. Tap where one "
                      'goes to put it in any of your groups.',
                    ),
                    if (matching > 0) ...[
                      const SizedBox(height: 12),
                      ShelfKey(
                        onPressed: _applying ? null : _tickMatching,
                        child: Text(
                          matching == 1
                              ? 'Tick the one that matches'
                              : 'Tick the $matching that match',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    for (final t in _plan.rows)
                      Padding(
                        padding: EdgeInsets.only(
                          left: _parent(t.id) == null ? 0 : 24,
                        ),
                        child: TagRow(
                          title: t.name,
                          subtitle: "$name's ${_plan.groupOf(t.id).name}",
                          chosen: _ticked.contains(t.id),
                          onTap: _applying ? null : () => _toggle(t.id),
                          below: TextLink(
                            label: _describe(t, _target(t)),
                            icon: Icons.arrow_drop_down,
                            semanticLabel:
                                'Where ${t.name} goes: '
                                '${_describe(t, _target(t))}',
                            onPressed: () {
                              if (!_applying) _choose(t);
                            },
                          ),
                        ),
                      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_failed) ...[
                        const HelpLine(
                          "Couldn't copy the tags. Check your connection "
                          'and try again.',
                          error: true,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ShelfKey(
                              onPressed: _applying ? null : _leave,
                              child: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShelfKey(
                              primary: true,
                              onPressed: _applying || count == 0
                                  ? null
                                  : _apply,
                              child: Text(
                                _applying
                                    ? 'Copying…'
                                    : _failed
                                    ? 'Try again'
                                    : 'Use $count '
                                          '${count == 1 ? 'tag' : 'tags'}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
