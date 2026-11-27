import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/shelf_key.dart';
import '../widgets/shelf_sheet.dart';
import 'place_picker_page.dart';
import 'shelf.dart';
import 'tag_import.dart';
import 'tag_paths.dart';
import 'tag_sheet.dart';

/// What the sheet for one part ends with: where it goes ([target]; null
/// for the friend's structure as it is), and whether the other tags below
/// it come along.
typedef TargetChoice = ({CopyTarget? target, bool bring});

/// Where the friend's group or tag [start], on the way to their tag [tag],
/// goes in the user's tags: both paths on top, then the places it can go
/// (docs/design/wireframes/copy-tags-8.html). Null when dismissed.
Future<TargetChoice?> showTagTargetSheet(
  BuildContext context, {
  required TagImport plan,
  required Tag tag,
  required Start start,
  required bool bring,
}) => showShelfSheet<TargetChoice>(
  context: context,
  builder: (_) =>
      _TargetSheet(plan: plan, tag: tag, start: start, bring: bring),
);

class _TargetSheet extends StatefulWidget {
  const _TargetSheet({
    required this.plan,
    required this.tag,
    required this.start,
    required this.bring,
  });

  final TagImport plan;
  final Tag tag;
  final Start start;
  final bool bring;

  @override
  State<_TargetSheet> createState() => _TargetSheetState();
}

class _TargetSheetState extends State<_TargetSheet> {
  String get _id => (widget.start.group?.id ?? widget.start.tag?.id)!;
  String get _name => (widget.start.group?.name ?? widget.start.tag?.name)!;

  /// The plan with the friend's structure as it is for this part.
  late final _asIs = widget.plan.withoutTargets([
    _id,
    for (final s in widget.plan.mappedBelow(widget.start, widget.tag))
      (s.group?.id ?? s.tag?.id)!,
  ]);
  late CopyTarget? _target = widget.plan.target(_id);
  late bool _bring = widget.bring;

  TagImport get _planned => switch (_target) {
    final t? => widget.plan.remap(widget.start, t, widget.tag),
    null => _asIs,
  };

  Future<void> _elsewhere() async {
    final target = await Navigator.of(context).push(
      MaterialPageRoute<CopyTarget>(
        builder: (_) => PlacePickerPage(plan: _asIs, start: widget.start),
      ),
    );
    if (target != null && mounted) setState(() => _target = target);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final name = widget.plan.from.name;
    final label = text.labelSmall!.copyWith(color: c.muted);
    Widget option(String title, CopyTarget? target, {String? subtitle}) =>
        TagRow(
          title: title,
          subtitle: subtitle,
          chosen: _target == target,
          onTap: () => setState(() => _target = target),
        );
    String path(List<String> names, {required bool isNew}) =>
        '${isNew ? '+ ' : ''}${names.join(' › ')}';

    final options = <Widget>[];
    // Places already listed, so none shows twice.
    final listed = <CopyTarget?>{null};
    void add(String title, CopyTarget target, {String? subtitle}) {
      if (listed.add(target)) {
        options.add(option(title, target, subtitle: subtitle));
      }
    }

    if (widget.start.tag case final theirs?) {
      final place = _asIs.tagPlace(theirs);
      options.add(
        option(
          path(place.path, isNew: place.isNew),
          null,
          subtitle: "like $name's",
        ),
      );
      if (place.existing case final mine?) listed.add(OntoTag(mine.id));
      if (_asIs.nearestAbove(theirs) case final above?) {
        add(above.path.join(' › '), OntoTag(above.existing!.id));
      }
      if (place.group.existing case final group?) {
        options.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text('IN MY ${group.name.toUpperCase()}', style: label),
          ),
        );
        for (final t in group.tags) {
          add(t.name, OntoTag(t.id));
        }
      }
    } else {
      final theirs = widget.start.group!;
      final place = _asIs.groupPlace(theirs);
      options.add(
        option(
          path([...?place.parent?.path, place.name], isNew: place.isNew),
          null,
          subtitle: "like $name's",
        ),
      );
      if (place.existing case final mine?) listed.add(IntoGroup(mine.id));
      final above = switch (_asIs.parentOf(theirs)) {
        final p? => _asIs.tagPlace(p).group.existing,
        null => null,
      };
      if (above != null) {
        add(above.name, IntoGroup(above.id), subtitle: 'no sub-group');
      }
      options.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text('MY GROUPS', style: label),
        ),
      );
      for (final g in widget.plan.mine.groups) {
        if (g.parentTagId == null) add(g.name, IntoGroup(g.id));
      }
    }
    // A place picked elsewhere, which none of the rows above stands for.
    if (_target case final picked? when !listed.contains(picked)) {
      final planned = _planned;
      final names = widget.start.tag != null
          ? planned.tagPlace(widget.start.tag!).path
          : switch (planned.groupPlace(widget.start.group!)) {
              final g => [...?g.parent?.path, g.name],
            };
      options.insert(1, option(names.join(' › '), picked));
    }
    final others = [
      for (final t in widget.plan.below(widget.start))
        if (t.id != widget.tag.id) t,
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TagPaths(
              plan: _planned,
              tag: widget.tag,
              marked: widget.start,
              both: true,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...options,
                  TagRow(
                    title: 'Another place…',
                    create: true,
                    onTap: _elsewhere,
                  ),
                  if (others.isNotEmpty)
                    TagRow(
                      title: others.length == 1
                          ? '+ 1 more tag from $_name'
                          : '+ ${others.length} more tags from $_name',
                      chosen: _bring,
                      onTap: () => setState(() => _bring = !_bring),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ShelfKey(
              primary: true,
              onPressed: () =>
                  Navigator.of(context)
                      .pop<TargetChoice>((target: _target, bring: _bring)),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
