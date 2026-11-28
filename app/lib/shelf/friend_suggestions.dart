import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import 'path_bar.dart';
import 'shelf.dart';
import 'shelf_repository.dart';
import 'tag_import.dart';
import 'tag_section.dart';
import 'tag_target_sheet.dart';
import 'tags_check_page.dart';

/// One of the friend's tags offered on the album entry: in the user's
/// group [home] (null: it has no place in their tags yet, and goes below
/// them), as [label], the path from there. [onKey] when the user's tag is a
/// key on the page already, which is marked instead.
typedef Suggestion = ({
  Tag tag,
  TagGroup? home,
  String label,
  bool isNew,
  String? onKey,
});

/// The friend's tags on an album being added, offered inside the user's
/// own tag sections (docs/features/tags.md, "A friend's tags as
/// suggestions"): what is offered where, accepting one, and sending one
/// elsewhere.
class FriendSuggestions extends ChangeNotifier {
  FriendSuggestions(
    this._plan, {
    required this.shelf,
    required this.choice,
    required this.onChanged,
  });

  final ShelfRepository shelf;

  /// The album's tags as they are now, and the way to change them.
  final TagChoice Function() choice;
  final ValueChanged<TagChoice> onChanged;

  TagImport _plan;

  /// The plan, with the tags made on the album entry since as the user's.
  TagImport get plan => _plan = _plan.withMyGroups(choice().groups);

  /// A tag is being created: the album can't be saved meanwhile.
  bool busy = false;
  bool failed = false;

  /// What the last change took off the album, for the user to see.
  String? note;

  /// The friend's groups and tags sent elsewhere here, and the ones put
  /// back as they are: remembered, or forgotten, once a tag below them is
  /// added.
  final _changed = <String>{}, _reset = <String>{};

  /// For a friend's tag (by ID), the group or tag above it whose other tags
  /// come along when it is added.
  final _bring = <String, Start>{};

  /// The friend's tags not on the album yet, each with where it shows.
  List<Suggestion> get open {
    final plan = this.plan;
    final chosen = choice().chosen;
    bool shown(GroupPlace g) =>
        g.existing != null &&
        switch (g.parent) {
          null => true,
          final p => chosen.contains(p.existing?.id) && shown(p.group),
        };
    return [
      for (final t in plan.tags)
        if (plan.tagPlace(t) case final place
            when !chosen.contains(place.existing?.id))
          () {
            // The groups from the tag's own up to the top, with the path
            // below each.
            final below = <String>[place.name];
            GroupPlace? home;
            for (GroupPlace? g = place.group; g != null; g = g.parent?.group) {
              if (shown(g)) {
                home = g;
                break;
              }
              below.insertAll(0, [?g.parent?.name, g.name]);
            }
            final group = home?.existing;
            return (
              tag: t,
              home: group,
              label: below.join(' › '),
              isNew: place.isNew,
              onKey:
                  group != null &&
                      !group.pickFromList &&
                      identical(home, place.group)
                  ? place.existing?.id
                  : null,
            );
          }(),
    ];
  }

  /// The friend's tags that come along with [t], when the user asked.
  List<Tag> others(Tag t) => switch (_bring[t.id]) {
    final start? => [
      for (final u in plan.below(start))
        if (u.id != t.id) u,
    ],
    null => const [],
  };

  /// [choice] with the user's tags [ids] set, parents first; says which
  /// tags a one-per-album group lost.
  TagChoice _with(TagChoice choice, Iterable<String> ids) {
    final before = choice.chosen;
    for (final id in ids) {
      // A tag in a group the user hides can't be set here.
      final shown = choice.groups.any((g) => g.tags.any((t) => t.id == id));
      if (shown && !choice.chosen.contains(id)) choice = choice.toggle(id);
    }
    final names = {
      for (final g in choice.groups)
        for (final m in g.tags) m.id: m.name,
    };
    final off = [
      for (final id in before)
        if (!choice.chosen.contains(id)) ?names[id],
    ];
    note = off.isEmpty ? null : '${off.join(', ')}: off, one per album';
    return choice;
  }

  /// Puts the friend's [t] on the album where it lands in the user's tags,
  /// creating what is new, with the tags that come along; then remembers
  /// what was changed on its path.
  Future<void> accept(BuildContext context, Tag t) async {
    if (busy) return;
    final plan = this.plan;
    final others = this.others(t);
    if (others.isNotEmpty) {
      final go = await Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => TagsCheckPage(plan: plan, tag: t, others: others),
        ),
      );
      if (go != true) return;
    }
    final place = plan.tagPlace(t);
    failed = false;
    if (place.isNew || others.isNotEmpty) {
      busy = true;
      notifyListeners();
      try {
        final (:mine, :tagIds) = await plan.add(shelf, [...others, t]);
        _plan = plan.withMine(mine);
        onChanged(_with(TagChoice(mine.groups, choice().chosen), tagIds));
      } catch (e, stack) {
        reportError(e, stack);
        failed = true;
        return;
      } finally {
        busy = false;
        notifyListeners();
      }
    } else {
      onChanged(
        _with(choice(), [
          for (final a in place.ancestors.toList().reversed) a.existing!.id,
          place.existing!.id,
        ]),
      );
      notifyListeners();
    }
    _bring.remove(t.id);
    await _remember(t);
  }

  /// Puts all of [tags] on the album, one after the other.
  Future<void> acceptAll(BuildContext context, List<Tag> tags) async {
    for (final t in tags) {
      if (!context.mounted) return;
      await accept(context, t);
    }
  }

  /// Saves, for the friend's next albums, what was changed on the path of
  /// [t].
  Future<void> _remember(Tag t) async {
    try {
      for (final s in _plan.chainOf(t)) {
        final id = (s.group?.id ?? s.tag?.id)!;
        final group = s.group != null;
        if (_changed.contains(id)) {
          // A group of its own exists now: remembered as that group.
          final target = switch (_plan.targets[id]) {
            AtTop() => switch (_plan.groupPlace(s.group!).existing) {
              final made? => IntoGroup(made.id),
              null => null,
            },
            final other => other,
          };
          if (target != null) {
            await shelf.rememberCopy(id, target, group: group);
          }
          _changed.remove(id);
        } else if (_reset.contains(id)) {
          await shelf.forgetCopy(id, group: group);
          _reset.remove(id);
        }
      }
    } catch (e, stack) {
      // Still used for this album; only remembering it failed.
      reportError(e, stack);
    }
  }

  /// Sends the friend's [t] elsewhere: a sheet for the topmost part of
  /// where it lands that is new, else for the tag itself.
  Future<void> change(BuildContext context, Tag t) async {
    if (busy) return;
    final plan = this.plan;
    final start = plan
        .toPath(t)
        .firstWhere((p) => p.isNew, orElse: () => plan.toPath(t).last)
        .start;
    final picked = await showTagTargetSheet(
      context,
      plan: plan,
      tag: t,
      start: start,
      bring: _bring[t.id] == start,
    );
    if (picked == null) return;
    final id = (start.group?.id ?? start.tag?.id)!;
    // What was mapped below it on the way to this tag is replaced.
    final below = [
      for (final s in plan.mappedBelow(start, t)) (s.group?.id ?? s.tag?.id)!,
    ];
    note = null;
    if (picked.bring) {
      _bring[t.id] = start;
    } else if (_bring[t.id] == start) {
      _bring.remove(t.id);
    }
    if (picked.target != plan.target(id) || below.isNotEmpty) {
      _changed.removeAll(below);
      _reset.addAll(below);
      if (picked.target case final target?) {
        _plan = plan.remap(start, target, t);
        _changed.add(id);
        _reset.remove(id);
      } else {
        _plan = plan.withoutTargets([id, ...below]);
        _changed.remove(id);
        _reset.add(id);
      }
    }
    notifyListeners();
  }
}

/// One of the friend's tags as a faint, dashed key inside the user's tags:
/// a tap takes it, a long press sends it elsewhere.
class GhostChip extends StatelessWidget {
  const GhostChip({
    super.key,
    required this.label,
    required this.from,
    required this.isNew,
    this.count = 1,
    this.onTap,
    this.onLongPress,
  });

  final String label;

  /// The friend's name.
  final String from;

  /// The user doesn't have it yet: it is created when taken.
  final bool isNew;

  /// How many tags a tap copies, when others come along.
  final int count;
  final VoidCallback? onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          '$label, from $from${isNew ? ', new' : ''}'
          '${count > 1 ? ', with ${count - 1} more' : ''}',
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            widthFactor: 1,
            child: CustomPaint(
              foregroundPainter: DashedOutline(c.muted),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNew) ...[
                      Icon(Icons.add, size: 14, color: c.muted),
                      const SizedBox(width: 4),
                    ],
                    Flexible(child: Text(label, style: text.titleSmall)),
                    const SizedBox(width: 6),
                    Text(
                      count > 1 ? '+${count - 1} · $from' : from,
                      style: text.bodySmall!.copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
