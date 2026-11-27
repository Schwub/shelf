import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';
import 'map_tags_page.dart';
import 'shelf.dart';
import 'shelf_repository.dart';
import 'tag_import.dart';
import 'tag_section.dart';

/// What "Anna's tags" ends with: the album's tags, the plan with the user's
/// shelf as it is now, and which of the user's tags each of the friend's
/// went onto (by the friend's tag ID).
typedef FriendTagsResult = ({
  TagChoice choice,
  TagImport plan,
  Map<String, String> landed,
});

/// "Anna's tags" (docs/design/wireframes/copy-tags-6.html): the friend's
/// tags on the album, one per line with its full path. A tag the user has is
/// added; one they don't is copied with the friend's structure above it, or
/// the user's nearest tag above it is used instead. Nothing is added until
/// tapped.
class FriendTagsPage extends StatefulWidget {
  const FriendTagsPage({
    super.key,
    required this.plan,
    required this.shelf,
    required this.choice,
    this.landed = const {},
  });

  final TagImport plan;
  final ShelfRepository shelf;
  final TagChoice choice;
  final Map<String, String> landed;

  @override
  State<FriendTagsPage> createState() => _FriendTagsPageState();
}

class _FriendTagsPageState extends State<FriendTagsPage> {
  late TagImport _plan = widget.plan;
  late TagChoice _choice = widget.choice;
  late final _landed = {...widget.landed};
  bool _busy = false, _failed = false;

  /// What the last change took off the album, for the user to see.
  String? _note;

  /// The user's tag that the friend's tag [t] is on the album as, if it is.
  String? _on(Tag t) {
    final id = _landed[t.id] ?? _plan.tagPlace(t).existing?.id;
    return id != null && _choice.chosen.contains(id) ? id : null;
  }

  /// [choice] with the user's tags [ids] set, parents first.
  static TagChoice _with(TagChoice choice, Iterable<String> ids) {
    for (final id in ids) {
      // A tag in a group the user hides can't be set here.
      final shown = choice.groups.any((g) => g.tags.any((t) => t.id == id));
      if (shown && !choice.chosen.contains(id)) choice = choice.toggle(id);
    }
    return choice;
  }

  /// The user's tags each line set that weren't set before, parents
  /// first: Undo takes those off again.
  final _brought = <String, List<String>>{};

  /// Sets the user's tags [ids] (parents first) for the friend's [t].
  void _set(Tag t, TagChoice base, List<String> ids) {
    final before = _choice.chosen;
    _choice = _with(base, ids);
    // In a one-per-album group, the tag set before comes off: say so.
    final names = {
      for (final g in _choice.groups)
        for (final m in g.tags) m.id: m.name,
    };
    final off = [
      for (final id in base.chosen)
        if (!_choice.chosen.contains(id)) ?names[id],
    ];
    _note = off.isEmpty
        ? null
        : '${off.join(', ')} came off: only one tag per album fits there.';
    _landed[t.id] = ids.last;
    _brought[t.id] = [
      for (final id in ids)
        if (!before.contains(id) && _choice.chosen.contains(id)) id,
    ];
  }

  /// Sets the user's tag at [place], which they have, for the friend's [t].
  void _use(Tag t, TagPlace place) => setState(() {
    _failed = false;
    _set(t, _choice, [
      for (final a in place.ancestors.toList().reversed) a.existing!.id,
      place.existing!.id,
    ]);
  });

  /// Creates the friend's [t] with their structure above it, and sets it.
  Future<void> _copy(Tag t) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final (:mine, :tagIds) = await _plan.add(widget.shelf, [t]);
      if (!mounted) return;
      setState(() {
        _plan = _plan.withMine(mine);
        _set(t, TagChoice(mine.groups, _choice.chosen), tagIds);
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Remembers [target] for the friend's group or tag [id].
  Future<void> _remember(
    String id,
    CopyTarget target, {
    required bool group,
  }) async {
    try {
      await widget.shelf.rememberCopy(id, target, group: group);
    } catch (e, stack) {
      // Still used for this album; only remembering it failed.
      reportError(e, stack);
    }
  }

  /// Uses the user's tag at [place] instead of the friend's [t], from now
  /// on.
  void _useInstead(Tag t, TagPlace place) {
    final target = OntoTag(place.existing!.id);
    setState(() => _plan = _plan.withTarget(t.id, target));
    _use(t, place);
    _remember(t.id, target, group: false);
  }

  /// Maps the friend's [t], or a group or tag above it, into the user's
  /// tags (three steps on their own page), creates what that needs and sets
  /// [t]. Lines that were on and go elsewhere now come off.
  Future<void> _map(Tag t) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute<MapResult>(
        builder: (_) => MapTagsPage(plan: _plan, tag: t),
      ),
    );
    if (result == null || !mounted) return;
    final (:start, :target, :bring) = result;
    final id = (start.group?.id ?? start.tag?.id)!;
    final before = {
      for (final u in _plan.tags)
        if (u.id != t.id) u: _on(u),
    };
    // The new mapping holds for everything below its start: what was
    // mapped there on the way to this tag before is forgotten.
    final stale = _plan.mappedBelow(start, t);
    final planned = _plan.remap(start, target, t);
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final (:mine, :tagIds) = await planned.add(widget.shelf, [
        if (bring)
          for (final u in planned.below(start))
            if (u.id != t.id) u,
        t,
      ]);
      if (!mounted) return;
      setState(() {
        _plan = planned.withMine(mine);
        _choice = TagChoice(mine.groups, _choice.chosen);
        for (final MapEntry(key: u, value: was) in before.entries) {
          if (was == null || !_choice.chosen.contains(was)) continue;
          if (_plan.tagPlace(u).existing?.id != was) _takeOff(u, was);
        }
        _set(t, _choice, tagIds);
      });
      await [
        _forget([
          for (final s in stale)
            if (s.group case final g?) g.id,
        ], group: true),
        _forget([
          for (final s in stale)
            if (s.tag case final tag?) tag.id,
        ], group: false),
      ].wait;
      // A group of its own exists now: remembered as that group.
      final made = start.group == null
          ? null
          : _plan.groupPlace(start.group!).existing;
      final resolved = switch (target) {
        AtTop() => made == null ? null : IntoGroup(made.id),
        _ => target,
      };
      if (resolved != null) {
        await _remember(id, resolved, group: start.group != null);
      }
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Takes the friend's [t] off the album again: the user's tag [id],
  /// unless another line has it on too, and the parents this line set that
  /// nothing else needs.
  void _undo(Tag t, String id) => setState(() {
    _note = null;
    _takeOff(t, id);
  });

  void _takeOff(Tag t, String id) {
    _landed.remove(t.id);
    final brought = _brought.remove(t.id) ?? const <String>[];
    final shared = _plan.tags.any((u) => u.id != t.id && _on(u) == id);
    if (!shared) _choice = _choice.toggle(id);
    for (final parent in brought.reversed) {
      final needed = _choice.groups.any(
        (g) =>
            g.parentTagId == parent &&
            g.tags.any((m) => _choice.chosen.contains(m.id)),
      );
      final line = _plan.tags.any((u) => _on(u) == parent);
      if (parent != id && !needed && !line && _choice.chosen.contains(parent)) {
        _choice = _choice.toggle(parent);
      }
    }
  }

  /// Forgets what was mapped for the friend's tag [t] itself.
  void _reset(Tag t) {
    setState(() => _plan = _plan.withoutTargets([t.id]));
    _forget([t.id], group: false);
  }

  Future<void> _forget(List<String> ids, {required bool group}) async {
    try {
      await [for (final id in ids) widget.shelf.forgetCopy(id, group: group)]
          .wait;
    } catch (e, stack) {
      reportError(e, stack);
    }
  }

  void _leave() => Navigator.of(context)
      .pop<FriendTagsResult>((choice: _choice, plan: _plan, landed: _landed));

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final name = _plan.from.name;
    // The friend's tags the user has and hasn't added; in a one-per-album
    // group only one, and none when the group has a tag set already.
    final have = <Tag>[];
    final wanted = <String, String>{}; // my one-per-album group → its tag
    for (final t in _plan.tags) {
      final place = _plan.tagPlace(t);
      if (place.isNew || _on(t) != null) continue;
      // Its own tag and the parents above it: none may push out a tag
      // that is set, or that an earlier line needs.
      final chain = [place, ...place.ancestors];
      final fits = chain.every((p) {
        final group = p.group.existing!;
        if (!group.exclusive) return true;
        final set = group.tags
            .where((m) => _choice.chosen.contains(m.id))
            .firstOrNull;
        return (wanted[group.id] ?? set?.id ?? p.existing!.id) ==
            p.existing!.id;
      });
      if (!fits) continue;
      for (final p in chain) {
        if (p.group.existing!.exclusive) {
          wanted[p.group.existing!.id] = p.existing!.id;
        }
      }
      have.add(t);
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _leave();
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
                      onPressed: _busy ? null : _leave,
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
                      "$name's tags on this album. Add the ones you have, "
                      "copy one with $name's structure above it, or map it "
                      'into your own.',
                    ),
                    if (have.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextLink(
                          label: have.length == 1
                              ? 'Add the one you have'
                              : 'Add the ${have.length} you have',
                          onPressed: () {
                            if (_busy) return;
                            for (final t in have) {
                              _use(t, _plan.tagPlace(t));
                            }
                          },
                        ),
                      ),
                    for (final t in _plan.tags) _line(t),
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
                      if (_failed) ...[
                        const HelpLine(
                          "Couldn't copy the tag. Check your connection and "
                          'try again.',
                          error: true,
                        ),
                        const SizedBox(height: 8),
                      ],
                      ShelfKey(
                        primary: true,
                        onPressed: _busy ? null : _leave,
                        child: Text(_busy ? 'Copying…' : 'Done'),
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

  /// One of the friend's tags: its path, where it goes, and what to do.
  Widget _line(Tag t) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall!.copyWith(color: c.muted);
    final place = _plan.tagPlace(t);
    final on = _on(t);
    final above = place.isNew ? _plan.nearestAbove(t) : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_plan.pathOf(t).join(' › ')} ›', style: muted),
          Text(t.name, style: text.titleMedium),
          if (on != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'On the album as '
                    '${_plan.myTag(on)?.path.join(' › ') ?? t.name}',
                    style: muted,
                  ),
                ),
                TextLink(
                  label: 'Undo',
                  semanticLabel: 'Undo ${t.name}',
                  onPressed: () {
                    if (!_busy) _undo(t, on);
                  },
                ),
              ],
            )
          else ...[
            const SizedBox(height: 2),
            Text(
              place.isNew
                  ? '→ new: ${place.path.join(' › ')}'
                  : '→ my ${place.path.join(' › ')} · ${switch (place.match) {
                      Match.path => 'same place',
                      Match.name => 'same name',
                      Match.remembered => 'remembered',
                    }}',
              style: muted,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ShelfKey(
                  primary: true,
                  semanticLabel: '${place.isNew ? 'Copy' : 'Add'} ${t.name}',
                  onPressed: _busy
                      ? null
                      : () => place.isNew ? _copy(t) : _use(t, place),
                  child: Text(place.isNew ? 'Copy' : 'Add'),
                ),
                if (above != null)
                  ShelfKey(
                    semanticLabel: 'Use my ${above.name} for ${t.name}',
                    onPressed: _busy ? null : () => _useInstead(t, above),
                    child: Text('Use my ${above.name}'),
                  ),
                ShelfKey(
                  semanticLabel: 'Map ${t.name}',
                  onPressed: _busy ? null : () => _map(t),
                  child: const Text('Map…'),
                ),
                if (_plan.targets.containsKey(t.id))
                  ShelfKey(
                    semanticLabel: 'Forget where ${t.name} goes',
                    onPressed: _busy ? null : () => _reset(t),
                    child: const Text('Forget'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
