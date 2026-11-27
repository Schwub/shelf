import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';
import 'shelf.dart';
import 'tag_import.dart';

/// A place while browsing the user's tags: the top (both null), one of
/// their groups, or one of their tags.
typedef _Node = ({TagGroup? group, Tag? tag});

/// The user's tags, one level per screen, to pick where the friend's group
/// or tag [start] goes (docs/design/wireframes/copy-tags-8.html, "Another
/// place"). Each level has one action; pops the target.
class PlacePickerPage extends StatefulWidget {
  const PlacePickerPage({super.key, required this.plan, required this.start});

  final TagImport plan;
  final Start start;

  @override
  State<PlacePickerPage> createState() => _PlacePickerPageState();
}

class _PlacePickerPageState extends State<PlacePickerPage> {
  late List<_Node> _at = _likely();
  final _query = TextEditingController();

  TagImport get _plan => widget.plan;
  String get _name => (widget.start.group?.name ?? widget.start.tag?.name)!;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// The way down the user's tags to their group [g].
  List<_Node> _pathTo(TagGroup g) {
    final parent = _plan.mine.groups
        .expand((m) => m.tags.map((t) => (group: m, tag: t)))
        .where((p) => p.tag.id == g.parentTagId)
        .firstOrNull;
    return [
      if (parent != null) ...[
        ..._pathTo(parent.group),
        (group: null, tag: parent.tag),
      ],
      (group: g, tag: null),
    ];
  }

  /// Opens where the start most likely goes: the user's group most like
  /// the friend's, else where it goes now, else the top.
  List<_Node> _likely() {
    final theirs = widget.start.group ?? _plan.groupOf(widget.start.tag!.id);
    final likely =
        _plan.suggestion(theirs) ?? _plan.groupPlace(theirs).existing;
    return likely == null ? const [] : _pathTo(likely);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final mine = _plan.mine.groups;
    final here = _at.lastOrNull;
    final group = widget.start.group != null;
    final q = _query.text.trim().toLowerCase();

    Widget row(String title, _Node node, {String? subtitle}) => Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _at = node.group != null
              ? _pathTo(node.group!)
              : [
                  ..._pathTo(mine.firstWhere((g) => g.tags.contains(node.tag))),
                  node,
                ];
          _query.clear();
        }),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: text.titleMedium),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: text.bodySmall!.copyWith(color: c.muted),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.muted),
            ],
          ),
        ),
      ),
    );

    final (String? action, CopyTarget? target) = switch (here) {
      null =>
        group ? ('$_name here, as a new group', const AtTop()) : (null, null),
      (group: final g?, tag: _) => (
        group ? 'Its tags into ${g.name}' : '$_name into ${g.name}',
        IntoGroup(g.id),
      ),
      (group: _, tag: final t?) =>
        group
            ? ('$_name under ${t.name}', UnderTag(t.id))
            : ('Use ${t.name}', OntoTag(t.id)),
      _ => (null, null),
    };
    final below = switch (here) {
      null => [
        for (final g in mine)
          if (g.parentTagId == null) row(g.name, (group: g, tag: null)),
      ],
      (group: final g?, tag: _) => [
        for (final t in g.tags) row(t.name, (group: null, tag: t)),
      ],
      (group: _, tag: final t?) => [
        for (final g in mine)
          if (g.parentTagId == t.id) row(g.name, (group: g, tag: null)),
      ],
      _ => const <Widget>[],
    };
    return Scaffold(
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_name, style: text.headlineSmall)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  ShelfField(
                    controller: _query,
                    hintText: 'Search my tags',
                    icon: Icons.search,
                  ),
                  if (q.isNotEmpty) ...[
                    for (final g in mine) ...[
                      if (g.name.toLowerCase().contains(q))
                        row(g.name, (group: g, tag: null), subtitle: 'group'),
                      for (final t in g.tags)
                        if (t.name.toLowerCase().contains(q))
                          row(t.name, (group: null, tag: t), subtitle: g.name),
                    ],
                  ] else ...[
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextLink(
                          label: 'My tags',
                          onPressed: () => setState(() => _at = const []),
                        ),
                        for (final (i, n) in _at.indexed) ...[
                          Text(
                            ' › ',
                            style: text.bodySmall!.copyWith(color: c.muted),
                          ),
                          TextLink(
                            label: (n.group?.name ?? n.tag?.name)!,
                            semanticLabel:
                                'Up to ${(n.group?.name ?? n.tag?.name)!}',
                            onPressed: () =>
                                setState(() => _at = _at.sublist(0, i + 1)),
                          ),
                        ],
                      ],
                    ),
                    if (action != null)
                      ShelfKey(
                        primary: true,
                        onPressed: () => Navigator.of(context).pop(target),
                        child: Text(action),
                      ),
                    const SizedBox(height: 8),
                    ...below,
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
