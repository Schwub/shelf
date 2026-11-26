import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_key.dart';
import 'bulk_tags.dart';
import 'shelf.dart';
import 'tag_sheet.dart';

/// "Tags for 3 albums" (TASK-40, docs/design/wireframes/select.html): every
/// visible group with its tags, lit when all selected albums have it, with
/// how many do. Returns the changes for Apply, null for Cancel.
Future<BulkTags?> showBulkTagsSheet(
  BuildContext context, {
  required BulkTags tags,
  required Future<Tag> Function(TagGroup group, String name) onCreate,
}) {
  final c = context.shelf;
  return showModalBottomSheet<BulkTags>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: c.bg,
    barrierColor: const Color(0x73000000),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      side: BorderSide(color: c.line),
    ),
    builder: (_) => _BulkTagsSheet(tags: tags, onCreate: onCreate),
  );
}

class _BulkTagsSheet extends StatefulWidget {
  const _BulkTagsSheet({required this.tags, required this.onCreate});

  final BulkTags tags;
  final Future<Tag> Function(TagGroup group, String name) onCreate;

  @override
  State<_BulkTagsSheet> createState() => _BulkTagsSheetState();
}

class _BulkTagsSheetState extends State<_BulkTagsSheet> {
  late BulkTags _tags = widget.tags;

  /// "all 3", "2 of 3", "taken off 2", or nothing.
  String? _count(Tag t) {
    final n = _tags.count(t.id);
    final of = _tags.entries.length;
    return switch (_tags.state(t.id)) {
      TagState.all => 'all $of',
      TagState.some => '$n of $of',
      TagState.none when n > 0 => 'taken off $n',
      TagState.none => null,
    };
  }

  /// A group picked from a list (Genre) can be long: it shows the tags some
  /// album has, and Add opens the usual list to put more on.
  Future<void> _add(TagGroup group) async {
    final result = await showTagSheet(
      context,
      group: group,
      chosen: const {},
      onCreate: (name) => widget.onCreate(group, name),
    );
    if (result == null || !mounted) return;
    setState(() {
      var tags = _tags.withGroup(result.group);
      for (final id in result.chosen) {
        if (tags.state(id) != TagState.all) tags = tags.toggle(id);
      }
      _tags = tags;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final parentName = {
      for (final g in _tags.groups)
        for (final t in g.tags) t.id: t.name,
    };
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
              'Tags for ${_tags.entries.length} albums',
              style: text.titleLarge,
            ),
            const SizedBox(height: 4),
            const HelpLine(
              'Tap to put a tag on all of them; tap again to take it off '
              'all.',
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final g in _tags.groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: Text(
                        [
                          g.parentTagId == null
                              ? g.name
                              : '${g.name} · under ${parentName[g.parentTagId]}',
                          if (g.exclusive) 'one per album',
                        ].join(' · '),
                        style: text.labelSmall!.copyWith(color: c.muted),
                      ),
                    ),
                    for (final t in g.tags)
                      if (!g.pickFromList || _count(t) != null)
                        TagRow(
                          title: t.name,
                          subtitle: _count(t),
                          chosen: _tags.state(t.id) == TagState.all,
                          onTap: () =>
                              setState(() => _tags = _tags.toggle(t.id)),
                        ),
                    if (g.pickFromList)
                      TagRow(
                        title: 'Add ${g.name.toLowerCase()}',
                        create: true,
                        onTap: () => _add(g),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
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
                    onPressed: _tags.changed
                        ? () => Navigator.of(context).pop(_tags)
                        : null,
                    child: const Text('Apply'),
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
