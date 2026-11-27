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

/// "Anna's tags" (TASK-48, docs/design/wireframes/copy-tags.html): the
/// friend's whole tag tree. Their groups go where the user says, tags are
/// ticked to copy (the album's new ones are already), and a sub-tag brings
/// its parent. Returns the plan as it ends: after copying, or with only the
/// destinations changed after Skip.
class CopyTagsPage extends StatefulWidget {
  const CopyTagsPage({super.key, required this.plan, required this.shelf});

  final TagImport plan;
  final ShelfRepository shelf;

  @override
  State<CopyTagsPage> createState() => _CopyTagsPageState();
}

class _CopyTagsPageState extends State<CopyTagsPage> {
  late TagImport _plan = widget.plan;
  late final Set<String> _picked = {
    for (final m in widget.plan.missing)
      if (widget.plan.copyable(m.tag.id)) m.tag.id,
  };
  bool _copying = false, _failed = false;

  Shelf get _theirs => _plan.theirs;

  late final _groupOfTag = {
    for (final g in _theirs.allGroups)
      for (final t in g.tags) t.id: g,
  };

  /// The friend's ticked tags under [tagId], at any depth.
  Set<String> _under(String tagId) => {
    for (final g in _theirs.groups)
      if (g.parentTagId == tagId)
        for (final t in g.tags) ...{t.id, ..._under(t.id)},
  };

  /// A sub-tag can't be copied without its parent: they go together.
  void _toggle(String tagId) => setState(() {
    if (_picked.remove(tagId)) {
      _picked.removeAll(_under(tagId));
      return;
    }
    _picked.add(tagId);
    for (
      var parent = _groupOfTag[tagId]?.parentTagId;
      parent != null && _plan.copyable(parent);
      parent = _groupOfTag[parent]?.parentTagId
    ) {
      _picked.add(parent);
    }
  });

  Future<void> _choose(TagGroup group) async {
    final choice = await _pickDestination(group);
    if (choice == null || !mounted) return;
    final (:destination) = choice;
    setState(() {
      _plan = _plan.withDestination(group, destination);
      _picked
        ..removeWhere((id) => !_plan.copyable(id))
        // The album's new tags are ticked again when their group is back.
        ..addAll([
          for (final m in _plan.missing)
            if (_plan.copyable(m.tag.id)) m.tag.id,
        ]);
    });
    try {
      await widget.shelf.saveDestination(group.id, destination);
    } catch (e, stack) {
      // Still used for this album; only remembering it failed.
      reportError(e, stack);
    }
  }

  /// The choice, or null when dismissed; its destination is null for a new
  /// group (no remembered choice).
  Future<({Destination? destination})?> _pickDestination(TagGroup group) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    // Built-in groups are statuses (Collection, Listening), not places to
    // copy to; they match the friend's by key anyway.
    final mine = [
      for (final g in _plan.mine.groups)
        if (g.parentTagId == null && g.builtin == null) g,
    ];
    final current = _plan.target(group);
    // Hidden groups too: a group of that name catches the copies anyway.
    final sameName = _plan.mine.allGroups.any(
      (g) =>
          g.parentTagId == null &&
          g.name.toLowerCase() == group.name.toLowerCase(),
    );
    String have(TagGroup g) {
      final names = {for (final t in g.tags) t.name.toLowerCase()};
      final n = group.tags.where((t) => names.contains(t.name.toLowerCase()));
      return 'has ${n.length} of ${group.tags.length}';
    }

    return showModalBottomSheet<({Destination? destination})>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: c.bg,
      barrierColor: const Color(0x73000000),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: c.line),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Copy ${_plan.from.name}'s ${group.name} into",
                style: text.titleLarge,
              ),
              const SizedBox(height: 4),
              const HelpLine(
                'Tags with the same name are matched; the others are '
                'added. Remembered for this friend.',
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final g in mine)
                      TagRow(
                        title: 'My ${g.name}',
                        subtitle: have(g),
                        chosen: !current.nowhere && current.into?.id == g.id,
                        onTap: () =>
                            Navigator.of(context)
                                .pop((destination: Destination.into(g.id))),
                      ),
                    if (!sameName)
                      TagRow(
                        title: 'A new group “${group.name}”',
                        subtitle: group.exclusive
                            ? 'one per album'
                            : 'several per album',
                        chosen: !current.nowhere && current.into == null,
                        onTap: () =>
                            Navigator.of(context).pop((destination: null)),
                      ),
                    TagRow(
                      title: "Don't copy this group",
                      chosen: current.nowhere,
                      onTap: () =>
                          Navigator.of(context)
                              .pop((destination: const Destination.nowhere())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy() async {
    setState(() {
      _copying = true;
      _failed = false;
    });
    try {
      final after = await _plan.copy(widget.shelf, _picked);
      if (mounted) Navigator.of(context).pop(after);
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) {
        setState(() {
          _copying = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final name = _plan.from.name;
    final count = _picked.length;
    return PopScope(
      // Back, like Skip, keeps the destinations chosen here.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_copying) Navigator.of(context).pop(_plan);
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
                      onPressed: _copying
                          ? null
                          : () => Navigator.of(context).pop(_plan),
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
                      "Tick $name's tags to copy. Tags on this album are "
                      'ticked already.',
                    ),
                    for (final g in _theirs.groups)
                      if (g.parentTagId == null) ..._group(g),
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
                              onPressed: _copying
                                  ? null
                                  : () => Navigator.of(context).pop(_plan),
                              child: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShelfKey(
                              primary: true,
                              onPressed: _copying || count == 0 ? null : _copy,
                              child: Text(
                                _copying
                                    ? 'Copying…'
                                    : _failed
                                    ? 'Try again'
                                    : 'Copy $count '
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

  /// A top-level group: its name, kind and destination, then its tags with
  /// the sub-groups under each.
  List<Widget> _group(TagGroup g) {
    final text = Theme.of(context).textTheme;
    final c = context.shelf;
    final target = _plan.target(g);
    final where = switch ((g.builtin, target)) {
      (_?, _) => null,
      (_, (nowhere: true, into: _)) => "Don't copy",
      (_, (nowhere: false, into: final into?)) => 'Into my ${into.name}',
      _ => 'New group',
    };
    return [
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name, style: text.titleMedium),
                  Text(
                    [
                      if (g.builtin != null) 'built-in',
                      g.exclusive ? 'one per album' : 'several per album',
                    ].join(' · '),
                    style: text.bodySmall!.copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            if (where == null || _copying)
              Text(
                where ?? 'Matches yours',
                style: text.bodySmall!.copyWith(color: c.muted),
              )
            else
              TextLink(
                label: where,
                icon: Icons.arrow_drop_down,
                semanticLabel: 'Where ${g.name} goes: $where',
                onPressed: () => _choose(g),
              ),
          ],
        ),
      ),
      if (!target.nowhere)
        for (final t in g.tags) ..._tag(t, depth: 0),
    ];
  }

  List<Widget> _tag(Tag t, {required int depth}) {
    final text = Theme.of(context).textTheme;
    final c = context.shelf;
    final onAlbum = _plan.tagIds.contains(t.id);
    final has = _plan.has(t.id);
    final marks = [
      if (onAlbum) 'on this album',
      if (has) 'you have it' else 'new',
    ].join(' · ');
    return [
      Padding(
        padding: EdgeInsets.only(left: depth * 24.0),
        child: TagRow(
          title: t.name,
          subtitle: marks,
          chosen: _picked.contains(t.id) || _plan.setOnAlbum(t.id),
          onTap: _plan.copyable(t.id) && !_copying ? () => _toggle(t.id) : null,
        ),
      ),
      for (final sub in _theirs.groups)
        if (sub.parentTagId == t.id) ...[
          Padding(
            padding: EdgeInsets.only(left: (depth + 1) * 24.0, top: 12),
            child: Text(
              '${sub.name} · under ${t.name}',
              style: text.labelSmall!.copyWith(color: c.muted),
            ),
          ),
          for (final s in sub.tags) ..._tag(s, depth: depth + 1),
        ],
    ];
  }
}
