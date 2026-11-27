import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_key.dart';
import '../widgets/shelf_sheet.dart';
import '../widgets/text_link.dart';
import 'shelf.dart';
import 'shelf_repository.dart';
import 'tag_import.dart';
import 'tag_section.dart';
import 'tag_sheet.dart';

/// "Anna's tags" on the album entry (docs/design/wireframes/
/// copy-tags-5.html): the friend's tags on the album as keys. Tapping one
/// sets the user's tag of that name; one the user doesn't have is created,
/// after a short question when its group has no place in the user's tags
/// yet. A long press asks again where its group goes.
class FriendTags extends StatefulWidget {
  const FriendTags({
    super.key,
    required this.plan,
    required this.shelf,
    required this.choice,
    required this.onChanged,
    required this.onBusy,
  });

  final TagImport plan;
  final ShelfRepository shelf;

  /// The album's tags, changed by tapping the friend's.
  final TagChoice choice;
  final ValueChanged<TagChoice> onChanged;

  /// Whether a tag is being created: the album can't be saved meanwhile.
  final ValueChanged<bool> onBusy;

  @override
  State<FriendTags> createState() => _FriendTagsState();
}

class _FriendTagsState extends State<FriendTags> {
  late TagImport _plan = widget.plan;

  /// Where the friend's groups go, as answered here.
  final _picked = <String, CopyTarget>{};
  bool _busy = false, _failed = false;

  TagPlace _place(Tag t) => _plan.tagPlace(t, _picked);

  bool _on(Tag t) => switch (_place(t).existing) {
    final mine? => widget.choice.chosen.contains(mine.id),
    null => false,
  };

  /// [choice] with the user's tags [ids] set, parents first.
  TagChoice _with(TagChoice choice, Iterable<String> ids) {
    for (final id in ids) {
      // A tag in a group the user hides can't be set here.
      final shown = choice.groups.any((g) => g.tags.any((t) => t.id == id));
      if (shown && !choice.chosen.contains(id)) choice = choice.toggle(id);
    }
    return choice;
  }

  /// The user's tags for [place], which they have: its parents, then itself.
  static List<String> _ids(TagPlace place) => [
    for (final a in place.ancestors.toList().reversed) a.existing!.id,
    place.existing!.id,
  ];

  @override
  void didUpdateWidget(FriendTags old) {
    super.didUpdateWidget(old);
    // Tags made in the sections below are the user's now, too.
    final groups = widget.choice.groups;
    if (!identical(groups, old.choice.groups) &&
        !identical(groups, _plan.mine.groups)) {
      final shown = {for (final g in groups) g.id};
      _plan = _plan.withMine(
        Shelf(
          entries: const [],
          allGroups: [
            ...groups,
            for (final g in _plan.mine.allGroups)
              if (!shown.contains(g.id)) g,
          ],
        ),
      );
    }
  }

  void _tap(Tag t) {
    if (_on(t)) {
      widget.onChanged(widget.choice.toggle(_place(t).existing!.id));
    } else {
      _add(t, ask: _plan.groupToAsk(t, _picked));
    }
  }

  /// Sets the friend's tag [t] on the album, creating it when the user
  /// doesn't have it, after asking where its group [ask] goes. Tags set
  /// from that group before move with the answer: they come off.
  Future<void> _add(Tag t, {TagGroup? ask}) async {
    final before = {
      for (final u in _plan.tags)
        if (_on(u)) u: _place(u).existing!.id,
    };
    final had = _picked[ask?.id];
    if (ask != null) {
      final target = await showShelfSheet<CopyTarget>(
        context: context,
        builder: (_) =>
            _WhereSheet(plan: _plan, picked: _picked, tag: t, group: ask),
      );
      if (target == null || !mounted) return;
      _picked[ask.id] = target;
    }
    final moved = [
      for (final MapEntry(key: u, value: id) in before.entries)
        if (_place(u).existing?.id != id) id,
    ];
    setState(() => _failed = false);
    var groups = widget.choice.groups;
    var ids = <String>[];
    if (_place(t).isNew) {
      setState(() => _busy = true);
      widget.onBusy(true);
      try {
        final (:mine, :tagIds) = await _plan.add(widget.shelf, t, _picked);
        if (!mounted) return;
        setState(() => _plan = _plan.withMine(mine));
        groups = mine.groups;
        ids = tagIds;
      } catch (e, stack) {
        reportError(e, stack);
        if (mounted) {
          setState(() {
            _failed = true;
            // Asked again on the next try.
            if (ask != null) {
              had == null ? _picked.remove(ask.id) : _picked[ask.id] = had;
            }
          });
        }
        return;
      } finally {
        if (mounted) {
          setState(() => _busy = false);
          widget.onBusy(false);
        }
      }
    } else {
      ids = _ids(_place(t));
    }
    // The album's tags as they are now: they may have changed meanwhile.
    var choice = TagChoice(groups, widget.choice.chosen);
    for (final id in moved) {
      if (choice.chosen.contains(id)) choice = choice.toggle(id);
    }
    widget.onChanged(_with(choice, ids));
    if (ask != null) _remember(ask);
  }

  /// The answer for [group] holds for the friend's next albums too.
  Future<void> _remember(TagGroup group) async {
    final mine = _plan.groupPlace(group, _picked).existing;
    if (mine == null) return;
    try {
      await widget.shelf.rememberCopy(group.id, mine.id);
    } catch (e, stack) {
      // Still used for this album; only remembering it failed.
      reportError(e, stack);
    }
  }

  void _addAllIHave(List<Tag> have) {
    var choice = widget.choice;
    for (final t in have) {
      choice = _with(choice, _ids(_place(t)));
    }
    widget.onChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final name = _plan.from.name;
    // The friend's tags the user has and hasn't set; in a one-per-album
    // group only one, and none when the group has a tag set already.
    final have = <Tag>[];
    final taken = <String>{};
    for (final t in _plan.tags) {
      final place = _place(t);
      if (place.isNew || _on(t)) continue;
      final group = place.group.existing!;
      if (group.exclusive &&
          (group.tags.any((m) => widget.choice.chosen.contains(m.id)) ||
              !taken.add(group.id))) {
        continue;
      }
      have.add(t);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "$name's tags · tap to add",
                    style: text.labelSmall!.copyWith(color: c.muted),
                  ),
                ),
                if (have.isNotEmpty)
                  TextLink(
                    label: have.length == 1
                        ? 'Add the one you have'
                        : 'Add the ${have.length} you have',
                    onPressed: () {
                      if (!_busy) _addAllIHave(have);
                    },
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _plan.tags)
                GestureDetector(
                  onLongPress: _busy
                      ? null
                      : () => _add(t, ask: _plan.groupOf(t.id)),
                  child: ShelfKey(
                    light: true,
                    selected: _on(t),
                    semanticLabel: _place(t).isNew ? '${t.name}, new' : null,
                    onPressed: _busy ? null : () => _tap(t),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // A new one reads "…, new" instead.
                        ExcludeSemantics(
                          excluding: _place(t).isNew,
                          child: Text(t.name),
                        ),
                        if (_place(t).isNew) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.add, size: 16, color: c.muted),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_failed) ...[
            const SizedBox(height: 8),
            const HelpLine(
              "Couldn't add the tag. Check your connection and try again.",
              error: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Where does Art pop go?": the user's group most like the friend's, a
/// group like the friend's, or any of the user's groups.
class _WhereSheet extends StatefulWidget {
  const _WhereSheet({
    required this.plan,
    required this.picked,
    required this.tag,
    required this.group,
  });

  final TagImport plan;
  final Map<String, CopyTarget> picked;
  final Tag tag;
  final TagGroup group;

  @override
  State<_WhereSheet> createState() => _WhereSheetState();
}

class _WhereSheetState extends State<_WhereSheet> {
  bool _elsewhere = false;

  void _pick(CopyTarget target) => Navigator.of(context).pop(target);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final plan = widget.plan;
    final group = widget.group;
    final name = plan.from.name;
    final mine = plan.mine.groups;
    final tagNames = {
      for (final g in mine)
        for (final t in g.tags) t.id: t.name,
    };
    String title(TagGroup g) => switch (g.parentTagId) {
      final p? => '${tagNames[p]} › ${g.name}',
      null => g.name,
    };
    final now = plan.groupPlace(group, widget.picked).existing;
    // Like the friend's: the user's group in the same place, or a new one.
    final same = plan.groupPlace(group, {
      ...widget.picked,
      group.id: const CopyAsIs(),
    });
    final suggested = plan.suggestion(group);
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
            Text(
              _elsewhere
                  ? '${widget.tag.name} goes into'
                  : 'Where does ${widget.tag.name} go?',
              style: text.titleLarge,
            ),
            const SizedBox(height: 4),
            HelpLine(
              "It's from $name's group ${group.name}. $name's other "
              '${group.name} tags follow.',
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _elsewhere
                    ? [
                        for (final g in mine)
                          TagRow(
                            title: title(g),
                            chosen: g.id == now?.id,
                            onTap: () => _pick(IntoGroup(g.id)),
                          ),
                      ]
                    : [
                        if (suggested != null &&
                            suggested.id != same.existing?.id)
                          TagRow(
                            title: 'Into my ${title(suggested)}',
                            subtitle: 'suggested',
                            chosen: suggested.id == now?.id,
                            onTap: () => _pick(IntoGroup(suggested.id)),
                          ),
                        if (same.existing case final g?)
                          TagRow(
                            title: 'Into my ${title(g)}',
                            chosen: g.id == now?.id,
                            onTap: () => _pick(const CopyAsIs()),
                          )
                        else
                          TagRow(
                            title: 'New group “${group.name}”',
                            subtitle: [
                              "like $name's",
                              if (same.parent case final p?) 'under ${p.name}',
                            ].join(' · '),
                            create: true,
                            onTap: () => _pick(const CopyAsIs()),
                          ),
                        TagRow(
                          title: 'Somewhere else…',
                          onTap: () => setState(() => _elsewhere = true),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
