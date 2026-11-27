import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import '../widgets/shelf_sheet.dart';
import '../widgets/text_link.dart';
import 'shelf.dart';
import 'shelf_repository.dart';
import 'tag_import.dart';
import 'tag_sheet.dart';

/// What "Anna's tags" ends with: the plan, the targets picked so far, and
/// the tags to set on the album, or null to leave them (Skip, Back).
typedef CopyTagsResult = ({
  TagImport plan,
  Map<String, CopyTarget> picked,
  Set<String>? tagIds,
});

/// "Anna's tags" (TASK-49, docs/design/wireframes/copy-tags-4.html): the
/// friend's tags on the album in their tree, none ticked. Each group and tag
/// goes where its target says: Copy keeps the friend's structure, or any
/// place in the user's tags.
class CopyTagsPage extends StatefulWidget {
  const CopyTagsPage({
    super.key,
    required this.plan,
    required this.shelf,
    this.picked = const {},
  });

  final TagImport plan;
  final ShelfRepository shelf;
  final Map<String, CopyTarget> picked;

  @override
  State<CopyTagsPage> createState() => _CopyTagsPageState();
}

class _CopyTagsPageState extends State<CopyTagsPage> {
  late final TagImport _plan = widget.plan;
  late final _picked = {...widget.picked};
  final _ticked = <String>{};
  String? _note;
  bool _applying = false, _failed = false;

  TagPlace _place(Tag t) => _plan.tagPlace(t, _picked);

  /// Ticking a tag; unticking takes the ticked tags that need it along.
  /// In a one-per-album group, the newer tick wins.
  void _toggle(Tag t) => setState(() {
    _note = null;
    if (_ticked.remove(t.id)) {
      _ticked.removeWhere(
        (u) => _place(_plan.theirTag(u)).ancestors.any((a) => a.from == t.id),
      );
      return;
    }
    _ticked.add(t.id);
    _onePerAlbum();
  });

  /// In each of the user's one-per-album groups, keeps the newest ticked tag
  /// (ticks are kept in order) and unticks the others, saying so.
  void _onePerAlbum() {
    final kept = <String, String>{}; // group key → tag kept
    final dropped = <String>[];
    for (final u in _ticked.toList().reversed) {
      final group = _place(_plan.theirTag(u)).group;
      if (!group.exclusive) continue;
      if (kept.containsKey(group.key)) {
        dropped.add(u);
        _note =
            'Your ${group.name} takes one tag per album, so '
            '${_plan.theirTag(u).name} was unticked for '
            '${_plan.theirTag(kept[group.key]!).name}.';
      } else {
        kept[group.key] = u;
      }
    }
    _ticked.removeAll(dropped);
  }

  /// The album's tags you have, or took from this friend before.
  List<Tag> get _suggested => [
    for (final t in _plan.tags)
      if (_plan.tagIds.contains(t.id) &&
          !_ticked.contains(t.id) &&
          (!_place(t).isNew || _plan.memory.taken.contains(t.id)))
        t,
  ];

  void _tickSuggested() {
    for (final t in _suggested) {
      if (!_ticked.contains(t.id)) _toggle(t);
    }
  }

  Future<void> _choose({TagGroup? group, Tag? tag}) async {
    final target = await showShelfSheet<CopyTarget>(
      context: context,
      builder: (_) =>
          _TargetSheet(plan: _plan, picked: _picked, group: group, tag: tag),
    );
    if (target == null || !mounted) return;
    setState(() {
      _note = null;
      _picked[(group?.id ?? tag?.id)!] = target;
      _onePerAlbum();
    });
  }

  Future<void> _apply() async {
    setState(() {
      _applying = true;
      _failed = false;
    });
    try {
      final (:mine, :tagIds) = await _plan.apply(
        widget.shelf,
        _ticked,
        _picked,
      );
      try {
        await _plan.remember(widget.shelf, _ticked, _picked);
      } catch (e, stack) {
        // The tags are copied; only remembering the choices failed.
        reportError(e, stack);
      }
      if (mounted) {
        Navigator.of(context).pop<CopyTagsResult>((
          plan: _plan.withMine(mine),
          picked: _picked,
          tagIds: tagIds,
        ));
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
      Navigator.of(context)
          .pop<CopyTagsResult>((plan: _plan, picked: _picked, tagIds: null));

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final name = _plan.from.name;
    final count = _ticked.length;
    final suggested = _suggested;
    final took = suggested.any((t) => _plan.memory.taken.contains(t.id));
    final along = _plan.along(_ticked, _picked);
    final creates = _plan.creates(_ticked, _picked);
    return PopScope(
      // Back, like Skip, keeps the targets picked here.
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
                      "$name's tags on this album, in $name's structure. "
                      'Tap where one goes to keep that structure (Copy) or '
                      'put it anywhere in yours.',
                    ),
                    if (suggested.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ShelfKey(
                        onPressed: _applying
                            ? null
                            : () => setState(_tickSuggested),
                        child: Text(
                          'Tick the ${suggested.length == 1 ? 'one' : suggested.length} '
                          'you have${took ? ' or took before' : ''}',
                        ),
                      ),
                    ],
                    for (final r in _plan.rows)
                      Padding(
                        padding: EdgeInsets.only(left: r.depth * 12.0),
                        child: switch (r) {
                          (group: final g?, tag: _, depth: _) => _groupRow(g),
                          (group: _, tag: final t?, depth: _) => _tagRow(
                            t,
                            along: along.contains(t.id),
                          ),
                          _ => const SizedBox.shrink(),
                        },
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
                      if (_note case final note?) ...[
                        HelpLine(note),
                        const SizedBox(height: 8),
                      ],
                      if (creates.isNotEmpty) ...[
                        HelpLine('Creates: ${creates.join(', ')}'),
                        const SizedBox(height: 8),
                      ],
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

  Widget _link(String label, String semanticLabel, VoidCallback onPressed) =>
      Align(
        alignment: Alignment.centerLeft,
        child: TextLink(
          label: label,
          icon: Icons.arrow_drop_down,
          semanticLabel: semanticLabel,
          onPressed: () {
            if (!_applying) onPressed();
          },
        ),
      );

  /// A group of the friend's: its kind and where it goes.
  Widget _groupRow(TagGroup g) {
    final text = Theme.of(context).textTheme;
    final c = context.shelf;
    final place = _plan.groupPlace(g, _picked);
    final where = switch (place) {
      GroupPlace(existing: final e?) => 'your ${e.name} · have',
      GroupPlace(parent: final p?) =>
        'new sub-group ${place.name} under ${p.name}',
      _ => 'new group ${place.name}',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(g.name, style: text.titleMedium),
          Text(
            [
              "${_plan.from.name}'s group",
              if (g.builtin != null) 'built-in',
              g.exclusive ? 'one per album' : 'several per album',
            ].join(' · '),
            style: text.bodySmall!.copyWith(color: c.muted),
          ),
          _link(
            '→ $where',
            'Where ${g.name} goes: $where',
            () => _choose(group: g),
          ),
        ],
      ),
    );
  }

  Widget _tagRow(Tag t, {required bool along}) {
    final place = _place(t);
    final where = '${place.path} · ${place.isNew ? 'new' : 'have'}';
    return TagRow(
      title: t.name,
      subtitle: [
        if (_plan.memory.taken.contains(t.id)) 'took before',
        if (!_plan.tagIds.contains(t.id)) 'not on this album',
        if (along) 'comes along',
      ].join(' · ').emptyToNull,
      chosen: _ticked.contains(t.id),
      along: along,
      onTap: _applying ? null : () => _toggle(t),
      below: _link(
        '→ $where',
        'Where ${t.name} goes: $where',
        () => _choose(tag: t),
      ),
    );
  }
}

extension on String {
  String? get emptyToNull => isEmpty ? null : this;
}

/// Where one of the friend's groups or tags goes: Copy first, then the
/// user's tags folded, with a search.
class _TargetSheet extends StatefulWidget {
  const _TargetSheet({
    required this.plan,
    required this.picked,
    this.group,
    this.tag,
  });

  final TagImport plan;
  final Map<String, CopyTarget> picked;
  final TagGroup? group;
  final Tag? tag;

  @override
  State<_TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends State<_TargetSheet> {
  final _query = TextEditingController();
  final _open = <String>{};

  TagImport get _plan => widget.plan;
  String get _id => (widget.group?.id ?? widget.tag?.id)!;
  String get _name => (widget.group?.name ?? widget.tag?.name)!;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// The target in effect: chosen, else the default (Copy, or for a tag
  /// the same-name tag it found elsewhere).
  late final CopyTarget _effective = () {
    if (_plan.chosen(_id, widget.picked) case final t?) return t;
    if (widget.tag case final tag?) {
      final place = _plan.tagPlace(tag, widget.picked);
      final copy = _plan.tagPlace(tag, {
        ...widget.picked,
        _id: const CopyAsIs(),
      });
      if (place.key != copy.key) return OntoTag(place.existing!.id);
    }
    return const CopyAsIs();
  }();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    // The user's groups down to where it goes now are open.
    GroupPlace? g = widget.group != null
        ? _plan.groupPlace(widget.group!, widget.picked)
        : _plan.tagPlace(widget.tag!, widget.picked).group;
    while (g != null) {
      if (g.existing case final e?) _open.add(e.id);
      g = g.parent?.group;
    }
  }

  Widget _option(
    String title,
    CopyTarget target, {
    String? subtitle,
    int depth = 0,
  }) => Padding(
    padding: EdgeInsets.only(left: depth * 16.0),
    child: TagRow(
      title: title,
      subtitle: subtitle,
      chosen: target == _effective,
      onTap: () => Navigator.of(context).pop(target),
    ),
  );

  Widget _folder(String id, String title, String count, int depth) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final open = _open.contains(id);
    return Semantics(
      button: true,
      expanded: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => open ? _open.remove(id) : _open.add(id)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.only(left: depth * 16.0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Icon(
                open ? Icons.arrow_drop_down : Icons.arrow_right,
                color: c.muted,
              ),
              Expanded(child: Text(title, style: text.titleMedium)),
              Text(count, style: text.bodySmall!.copyWith(color: c.muted)),
            ],
          ),
        ),
      ),
    );
  }

  /// One of the user's groups, and when open its tags with their
  /// sub-groups.
  List<Widget> _myGroup(TagGroup g, int depth) {
    final mine = _plan.mine;
    final subs = [
      for (final t in g.tags)
        for (final s in mine.groups)
          if (s.parentTagId == t.id) s,
    ];
    return [
      _folder(
        g.id,
        g.name,
        [
          '${g.tags.length} ${g.tags.length == 1 ? 'tag' : 'tags'}',
          if (g.builtin != null) 'built-in',
        ].join(' · '),
        depth,
      ),
      if (_open.contains(g.id)) ...[
        _option('Into ${g.name}', IntoGroup(g.id), depth: depth + 1),
        for (final t in g.tags) ...[
          if (widget.tag != null)
            _option(t.name, OntoTag(t.id), depth: depth + 1)
          else
            _option(
              'Under ${t.name}',
              UnderTag(t.id),
              subtitle: 'as a sub-group',
              depth: depth + 1,
            ),
          for (final s in subs)
            if (s.parentTagId == t.id) ..._myGroup(s, depth + 2),
        ],
      ],
    ];
  }

  /// Search results: the user's groups and tags whose name has [q].
  List<Widget> _found(String q) {
    final mine = _plan.mine;
    final tagNames = {
      for (final g in mine.groups)
        for (final t in g.tags) t.id: t.name,
    };
    String where(TagGroup g) => switch (g.parentTagId) {
      final p? => '${tagNames[p]} › ${g.name}',
      null => g.name,
    };
    bool has(String name) => name.toLowerCase().contains(q);
    return [
      for (final g in mine.groups) ...[
        if (has(g.name)) _option('Into ${where(g)}', IntoGroup(g.id)),
        for (final t in g.tags)
          if (has(t.name))
            widget.tag != null
                ? _option('${where(g)} › ${t.name}', OntoTag(t.id))
                : _option(
                    'Under ${where(g)} › ${t.name}',
                    UnderTag(t.id),
                    subtitle: 'as a sub-group',
                  ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.shelf;
    final q = _query.text.trim().toLowerCase();
    final mine = _plan.mine;
    final copy = widget.group != null
        ? _plan.groupPlace(widget.group!, {
            ...widget.picked,
            _id: const CopyAsIs(),
          })
        : null;
    final copyTag = widget.tag != null
        ? _plan.tagPlace(widget.tag!, {...widget.picked, _id: const CopyAsIs()})
        : null;
    final label = text.labelSmall!.copyWith(color: c.muted);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$_name goes to', style: text.titleLarge),
            const SizedBox(height: 8),
            ShelfField(
              controller: _query,
              hintText: 'Find a tag or group',
              icon: Icons.search,
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (q.isNotEmpty)
                    ..._found(q)
                  else ...[
                    _option(
                      copyTag != null
                          ? 'Copy: ${copyTag.path}'
                          : 'Copy: ${copy!.isNew ? 'new ' : ''}${copy.parent == null ? 'group' : 'sub-group'} ${copy.name}',
                      const CopyAsIs(),
                      subtitle: "like ${_plan.from.name}'s",
                    ),
                    if (widget.group?.parentTagId != null)
                      _option(
                        'Your top level: group “${widget.group!.name}”',
                        const AtRoot(),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: Text('Your tags', style: label),
                    ),
                    for (final g in mine.groups)
                      if (g.parentTagId == null) ..._myGroup(g, 0),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
