import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';
import 'shelf.dart';
import 'shelf_repository.dart';
import 'tag_import.dart';
import 'tag_paths.dart';
import 'tag_section.dart';
import 'tag_target_sheet.dart';
import 'tags_check_page.dart';

/// What "Anna's tags" ends with: the album's tags, the plan with the user's
/// shelf as it is now, and which of the user's tags each of the friend's
/// went onto (by the friend's tag ID).
typedef FriendTagsResult = ({
  TagChoice choice,
  TagImport plan,
  Map<String, String> landed,
});

/// "Anna's tags" (docs/design/wireframes/copy-tags-8.html): the friend's
/// tags on the album, each with the path it comes from and the path it
/// lands at in the user's tags. One key adds it (creating what is new);
/// tapping a part of where it lands sends that part elsewhere. Nothing is
/// added until tapped.
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

  /// The friend's groups and tags sent elsewhere here, and the ones put
  /// back as they are: remembered, or forgotten, once a tag below them is
  /// added.
  final _changed = <String>{}, _reset = <String>{};

  /// For a friend's tag (by ID), the group or tag above it whose other tags
  /// come along when it is added.
  final _bring = <String, Start>{};

  /// The user's tags each line set that weren't set before, parents
  /// first: Undo takes those off again.
  final _brought = <String, List<String>>{};

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
    _note = off.isEmpty ? null : '${off.join(', ')}: off, one per album';
    _landed[t.id] = ids.last;
    _brought[t.id] = [
      for (final id in ids)
        if (!before.contains(id) && _choice.chosen.contains(id)) id,
    ];
  }

  /// The friend's tags that come along with [t], when the user asked.
  List<Tag> _others(Tag t) => switch (_bring[t.id]) {
    final start? => [
      for (final u in _plan.below(start))
        if (u.id != t.id) u,
    ],
    null => const [],
  };

  /// Adds the friend's [t] to the album where its path lands, creating
  /// what is new, with the tags that come along; then remembers what was
  /// changed on its path.
  Future<void> _add(Tag t) async {
    final others = _others(t);
    if (others.isNotEmpty) {
      final go = await Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => TagsCheckPage(plan: _plan, tag: t, others: others),
        ),
      );
      if (go != true || !mounted) return;
    }
    final place = _plan.tagPlace(t);
    if (place.isNew || others.isNotEmpty) {
      setState(() {
        _busy = true;
        _failed = false;
      });
      try {
        final (:mine, :tagIds) = await _plan.add(widget.shelf, [...others, t]);
        if (!mounted) return;
        setState(() {
          _plan = _plan.withMine(mine);
          _set(t, TagChoice(mine.groups, _choice.chosen), tagIds);
        });
      } catch (e, stack) {
        reportError(e, stack);
        if (mounted) setState(() => _failed = true);
        return;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } else {
      setState(() {
        _failed = false;
        _set(t, _choice, [
          for (final a in place.ancestors.toList().reversed) a.existing!.id,
          place.existing!.id,
        ]);
      });
    }
    _bring.remove(t.id);
    await _remember(t);
  }

  /// Saves, for the friend's next albums, what was changed on the path of
  /// [t].
  Future<void> _remember(Tag t) async {
    try {
      for (final s in _plan.chainOf(t)) {
        final id = (s.group?.id ?? s.tag?.id)!;
        final group = s.group != null;
        if (_changed.remove(id)) {
          // A group of its own exists now: remembered as that group.
          final target = switch (_plan.targets[id]) {
            AtTop() => switch (_plan.groupPlace(s.group!).existing) {
              final made? => IntoGroup(made.id),
              null => null,
            },
            final other => other,
          };
          if (target != null) {
            await widget.shelf.rememberCopy(id, target, group: group);
          }
        } else if (_reset.remove(id)) {
          await widget.shelf.forgetCopy(id, group: group);
        }
      }
    } catch (e, stack) {
      // Still used for this album; only remembering it failed.
      reportError(e, stack);
    }
  }

  /// Sends the friend's group or tag [start], on the path of [t],
  /// elsewhere. Lines that were on and land elsewhere now come off.
  Future<void> _change(Tag t, Start start) async {
    final choice = await showTagTargetSheet(
      context,
      plan: _plan,
      tag: t,
      start: start,
      bring: _bring[t.id] == start,
    );
    if (choice == null || !mounted) return;
    final id = (start.group?.id ?? start.tag?.id)!;
    final before = {for (final u in _plan.tags) u: _on(u)};
    // What was mapped below it on the way to this tag is replaced.
    final below = [
      for (final s in _plan.mappedBelow(start, t)) (s.group?.id ?? s.tag?.id)!,
    ];
    setState(() {
      _note = null;
      _changed.removeAll(below);
      _reset.addAll(below);
      if (choice.target case final target?) {
        _plan = _plan.remap(start, target, t);
        _changed.add(id);
        _reset.remove(id);
      } else {
        _plan = _plan.withoutTargets([id, ...below]);
        _changed.remove(id);
        _reset.add(id);
      }
      if (choice.bring) {
        _bring[t.id] = start;
      } else {
        _bring.remove(t.id);
      }
      for (final MapEntry(key: u, value: was) in before.entries) {
        if (was != null && _plan.tagPlace(u).existing?.id != was) {
          _takeOff(u, was);
        }
      }
    });
  }

  void _undo(Tag t, String id) => setState(() {
    _note = null;
    _takeOff(t, id);
  });

  /// Takes the friend's [t] off the album again: the user's tag [id],
  /// unless another line has it on too, and the parents this line set that
  /// nothing else needs.
  void _takeOff(Tag t, String id) {
    _landed.remove(t.id);
    final brought = _brought.remove(t.id) ?? const <String>[];
    final shared = _plan.tags.any((u) => u.id != t.id && _on(u) == id);
    if (!shared && _choice.chosen.contains(id)) _choice = _choice.toggle(id);
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
      if (place.isNew || _on(t) != null || _others(t).isNotEmpty) continue;
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
                    if (have.isNotEmpty)
                      TextLink(
                        label: 'Add ${have.length} = mine',
                        semanticLabel: have.length == 1
                            ? 'Add the one you have'
                            : 'Add the ${have.length} you have',
                        onPressed: () async {
                          if (_busy) return;
                          for (final t in have) {
                            await _add(t);
                          }
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [for (final t in _plan.tags) _line(t)],
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

  /// One of the friend's tags: where it comes from, where it lands, and
  /// the key that puts it there.
  Widget _line(Tag t) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final on = _on(t);
    final isNew = _plan.tagPlace(t).isNew;
    final others = _others(t);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TagPaths(
            plan: _plan,
            tag: t,
            landed: on,
            onChange: on != null || _busy ? null : (s) => _change(t, s),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: Row(
              children: [
                if (on != null) ...[
                  Icon(Icons.check, size: 16, color: c.muted),
                  const SizedBox(width: 4),
                  Text(
                    'On the album',
                    style: text.bodySmall!.copyWith(color: c.muted),
                  ),
                  const SizedBox(width: 12),
                  ShelfKey(
                    semanticLabel: 'Undo ${t.name}',
                    onPressed: _busy ? null : () => _undo(t, on),
                    child: const Text('Undo'),
                  ),
                ] else
                  ShelfKey(
                    primary: true,
                    semanticLabel: '${isNew ? 'Copy' : 'Add'} ${t.name}',
                    onPressed: _busy ? null : () => _add(t),
                    child: Text(
                      others.isEmpty
                          ? (isNew ? 'Copy' : 'Add')
                          : 'Copy ${others.length + 1} tags',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
