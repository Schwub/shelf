import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_key.dart';
import 'shelf_repository.dart';
import 'tag_import.dart';
import 'tag_sheet.dart';

/// Offers the friend's tags the user doesn't have, all ticked. Returns the
/// plan after copying the ticked ones, or null for Skip.
Future<TagImport?> showImportTagsSheet(
  BuildContext context, {
  required TagImport plan,
  required ShelfRepository shelf,
}) {
  final c = context.shelf;
  return showModalBottomSheet<TagImport>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    // Closed by Skip, or the barrier and back while not copying: closed
    // during a copy, the copies would not reach the album.
    enableDrag: false,
    backgroundColor: c.bg,
    barrierColor: const Color(0x73000000),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      side: BorderSide(color: c.line),
    ),
    builder: (_) => _ImportTagsSheet(plan: plan, shelf: shelf),
  );
}

class _ImportTagsSheet extends StatefulWidget {
  const _ImportTagsSheet({required this.plan, required this.shelf});

  final TagImport plan;
  final ShelfRepository shelf;

  @override
  State<_ImportTagsSheet> createState() => _ImportTagsSheetState();
}

class _ImportTagsSheetState extends State<_ImportTagsSheet> {
  late final Set<String> _picked = {
    for (final m in widget.plan.missing) m.tag.id,
  };
  bool _copying = false, _failed = false;

  /// The missing tags hanging under [tagId], at any depth.
  Set<String> _under(String tagId) => {
    for (final m in widget.plan.missing)
      if (m.group.parentTagId == tagId) ...{m.tag.id, ..._under(m.tag.id)},
  };

  /// A sub-tag can't be copied without its parent tag: they go together.
  void _toggle(MissingTag m) => setState(() {
    if (_picked.remove(m.tag.id)) {
      _picked.removeAll(_under(m.tag.id));
      return;
    }
    _picked.add(m.tag.id);
    final byId = {for (final x in widget.plan.missing) x.tag.id: x};
    for (
      var p = byId[m.group.parentTagId];
      p != null;
      p = byId[p.group.parentTagId]
    ) {
      _picked.add(p.tag.id);
    }
  });

  Future<void> _copy() async {
    setState(() {
      _copying = true;
      _failed = false;
    });
    try {
      final after = await widget.plan.copy(widget.shelf, _picked);
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

  /// "Genre" for a tag going into the user's group, "Label · new group,
  /// several per album" for a new one.
  static String _section(MissingTag m) => switch (m.into) {
    final into? => into.name,
    null =>
      '${m.group.name} · new group, '
          '${m.group.exclusive ? 'one' : 'several'} per album',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final missing = widget.plan.missing;
    final sections = <String, List<MissingTag>>{};
    for (final m in missing) {
      (sections[_section(m)] ??= []).add(m);
    }
    final count = _picked.length;
    return PopScope(
      canPop: !_copying,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.off,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.plan.from.name} has ${missing.length} '
                "${missing.length == 1 ? 'tag' : 'tags'} you don't",
                style: text.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Copy them to your tags? You can edit them later.',
                style: text.bodyMedium!.copyWith(color: c.muted),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final MapEntry(key: title, value: tags)
                        in sections.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 4),
                        child: Text(
                          title,
                          style: text.labelSmall!.copyWith(color: c.muted),
                        ),
                      ),
                      for (final m in tags)
                        TagRow(
                          title: m.tag.name,
                          subtitle: m.into == null
                              ? 'New group and tag'
                              : 'New tag in your ${m.into!.name}',
                          chosen: _picked.contains(m.tag.id),
                          onTap: _copying ? null : () => _toggle(m),
                        ),
                    ],
                  ],
                ),
              ),
              if (_failed) ...[
                const SizedBox(height: 12),
                const HelpLine(
                  "Couldn't copy the tags. Check your connection and try again.",
                  error: true,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ShelfKey(
                      onPressed: _copying
                          ? null
                          : () => Navigator.of(context).pop(),
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
                            : 'Add $count ${count == 1 ? 'tag' : 'tags'}',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
