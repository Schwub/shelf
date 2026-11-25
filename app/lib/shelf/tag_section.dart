import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/shelf_key.dart';
import 'shelf_data.dart';
import 'tag_sheet.dart';

/// The chosen tags of an entry and the rules for changing them: one tag per
/// exclusive group, and a tag's sub-tags go when it goes.
@immutable
class TagChoice {
  const TagChoice(this.groups, this.chosen);

  final List<TagGroup> groups;
  final Set<String> chosen;

  TagGroup _groupOf(String tagId) =>
      groups.firstWhere((g) => g.tags.any((t) => t.id == tagId));

  /// [tagId] and every tag in the sub-groups under it, recursively.
  Set<String> _withSubTags(String tagId) => {
    tagId,
    for (final g in groups)
      if (g.parentTagId == tagId)
        for (final t in g.tags) ..._withSubTags(t.id),
  };

  TagChoice toggle(String tagId) {
    if (chosen.contains(tagId)) {
      return TagChoice(groups, chosen.difference(_withSubTags(tagId)));
    }
    final group = _groupOf(tagId);
    final released = group.exclusive
        ? {
            for (final t in group.tags)
              if (t.id != tagId && chosen.contains(t.id)) ..._withSubTags(t.id),
          }
        : <String>{};
    return TagChoice(groups, {...chosen.difference(released), tagId});
  }

  /// Chosen tags in an order the database accepts: a parent before the
  /// tags of its sub-groups.
  List<String> ordered(Iterable<String> tagIds) {
    int depth(String tagId) {
      final parent = _groupOf(tagId).parentTagId;
      return parent == null ? 0 : depth(parent) + 1;
    }

    return tagIds.toList()..sort((a, b) => depth(a).compareTo(depth(b)));
  }
}

/// The user's tag groups on the album entry (visual-system.md, "Tag groups
/// on the album entry"). Groups with up to six tags show them all as keys;
/// larger ones show the chosen tags. Multiple-choice groups have Add.
class TagSection extends StatelessWidget {
  const TagSection({
    super.key,
    required this.choice,
    required this.onChanged,
    required this.onCreate,
    required this.onEditTags,
  });

  final TagChoice choice;
  final ValueChanged<TagChoice> onChanged;

  /// Creates a tag in a group (from the Add sheet) and returns it.
  final Future<Tag> Function(TagGroup group, String name) onCreate;

  /// Opens the tag editor.
  final VoidCallback onEditTags;

  static const showAllUpTo = 6;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in choice.groups)
          if (g.parentTagId == null) ..._group(context, g),
        // Space around it, so it doesn't read as part of the last group.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _TextLink(label: 'Edit tags', onPressed: onEditTags),
          ),
        ),
      ],
    );
  }

  List<Widget> _group(BuildContext context, TagGroup group) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final chosenTags = [
      for (final t in group.tags)
        if (choice.chosen.contains(t.id)) t,
    ];
    final shown = group.tags.length <= showAllUpTo ? group.tags : chosenTags;
    Widget key(Tag t, {bool expand = false}) {
      final k = ShelfKey(
        light: true,
        selected: choice.chosen.contains(t.id),
        onPressed: () => onChanged(choice.toggle(t.id)),
        child: Text(t.name),
      );
      return expand ? Expanded(child: k) : k;
    }

    final subGroups = [
      for (final t in chosenTags)
        for (final g in choice.groups)
          if (g.parentTagId == t.id) g,
    ];
    return [
      SizedBox(
        // 48 for the Add link's touch area; tighter without it.
        height: group.exclusive ? 32 : 48,
        child: Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: text.labelSmall!.copyWith(color: c.muted),
              ),
            ),
            if (!group.exclusive)
              _TextLink(
                label: 'Add',
                icon: Icons.add,
                semanticLabel: 'Add ${group.name.toLowerCase()}',
                onPressed: () => _openSheet(context, group),
              ),
          ],
        ),
      ),
      if (shown.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'No ${group.name.toLowerCase()} yet',
            style: text.labelMedium!.copyWith(
              color: c.muted,
              fontVariations: const [FontVariation.weight(400)],
            ),
          ),
        )
      // Built-in two-tag groups fill the row with equal keys.
      else if (group.builtin && group.tags.length == 2)
        Row(
          children: [
            key(group.tags[0], expand: true),
            const SizedBox(width: 8),
            key(group.tags[1], expand: true),
          ],
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in shown) key(t)],
        ),
      for (final sub in subGroups)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.line, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _group(context, sub),
            ),
          ),
        ),
      const SizedBox(height: 8),
    ];
  }

  Future<void> _openSheet(BuildContext context, TagGroup group) async {
    final result = await showTagSheet(
      context,
      group: group,
      chosen: choice.chosen,
      onCreate: (name) => onCreate(group, name),
    );
    if (result == null) return;
    // The sheet may have created tags: take the group as the sheet left it.
    final groups = [
      for (final g in choice.groups) g.id == group.id ? result.group : g,
    ];
    var next = TagChoice(groups, choice.chosen);
    for (final t in result.group.tags) {
      if (result.chosen.contains(t.id) != next.chosen.contains(t.id)) {
        next = next.toggle(t.id);
      }
    }
    onChanged(next);
  }
}

/// An underlined muted link with a 48 px touch area: "Add" on a group's
/// label line, "Edit tags" under the groups.
class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
      color: c.muted,
      decoration: TextDecoration.underline,
      decorationColor: c.muted,
    );
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: c.muted),
                const SizedBox(width: 4),
              ],
              Text(label, style: style),
            ],
          ),
        ),
      ),
    );
  }
}
