import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';
import 'shelf.dart';
import 'tag_import.dart';
import 'tag_sheet.dart';

/// What Map ends with: the friend's group or tag the mapping starts at,
/// where it goes, and whether everything below it comes along.
typedef MapResult = ({Start start, CopyTarget target, bool bring});

/// A place while browsing the user's tags: the top (both null), one of
/// their groups, or one of their tags.
typedef _Node = ({TagGroup? group, Tag? tag});

/// Map one of the friend's tags into the user's tags, in three steps
/// (docs/design/wireframes/copy-tags-6.html): where in the friend's path
/// to start, where that goes in the user's tags, and a check of what it
/// creates.
class MapTagsPage extends StatefulWidget {
  const MapTagsPage({super.key, required this.plan, required this.tag});

  final TagImport plan;

  /// The friend's tag the user is mapping.
  final Tag tag;

  @override
  State<MapTagsPage> createState() => _MapTagsPageState();
}

class _MapTagsPageState extends State<MapTagsPage> {
  int _step = 0;
  late Start _start = _firstNew();
  List<_Node> _at = const [];
  CopyTarget? _target;
  bool _bring = false;
  final _query = TextEditingController();

  TagImport get _plan => widget.plan;
  String get _startName => (_start.group?.name ?? _start.tag?.name)!;

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

  /// The first part of the friend's path the user has no place for: the
  /// likely starting point. The tag itself when they have it all.
  Start _firstNew() {
    final chain = _plan.chainOf(widget.tag);
    return chain.firstWhere(
      (s) => s.group != null
          ? _plan.groupPlace(s.group!).isNew
          : _plan.tagPlace(s.tag!).isNew,
      orElse: () => chain.last,
    );
  }

  /// The way down the user's tags to their group [g].
  List<_Node> _pathTo(TagGroup g) {
    final mine = _plan.mine.groups;
    final parent = mine
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

  /// Step two opens where the start most likely goes: the user's group
  /// most like the friend's, else where it goes now.
  void _toWhere() {
    final theirs = _start.group ?? _plan.groupOf(_start.tag!.id);
    final likely =
        _plan.suggestion(theirs) ?? _plan.groupPlace(theirs).existing;
    setState(() {
      _step = 1;
      _at = likely == null ? const [] : _pathTo(likely);
      _query.clear();
    });
  }

  void _pick(CopyTarget target) => setState(() {
    _target = target;
    _bring = false;
    _step = 2;
  });

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
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
                      onPressed: _back,
                      child: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Map ${widget.tag.name}',
                        style: text.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  'Step ${_step + 1} of 3',
                  style: text.labelSmall!.copyWith(color: c.muted),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: switch (_step) {
                    0 => _whatToBring(),
                    1 => _whereItGoes(),
                    _ => _check(),
                  },
                ),
              ),
              if (_step != 1)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.bg,
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: ShelfKey(
                      primary: true,
                      onPressed: _step == 0
                          ? _toWhere
                          : () => Navigator.of(context).pop<MapResult>((
                              start: _start,
                              target: _target!,
                              bring: _bring,
                            )),
                      child: Text(_step == 0 ? 'Next' : _mapLabel),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step one: the starting point in the friend's path.
  List<Widget> _whatToBring() {
    final text = Theme.of(context).textTheme;
    final name = _plan.from.name;
    final chain = _plan.chainOf(widget.tag);
    return [
      Text('What do you want to bring?', style: text.titleLarge),
      const SizedBox(height: 4),
      HelpLine(
        "Pick where to start in $name's path. Everything from there down to "
        '${widget.tag.name} comes along.',
      ),
      for (final (i, s) in chain.indexed)
        Padding(
          padding: EdgeInsets.only(left: i * 16.0),
          child: TagRow(
            title: (s.group?.name ?? s.tag?.name)!,
            subtitle: switch (s) {
              (group: final g?, tag: _) =>
                g.parentTagId == null
                    ? "$name's whole group"
                    : 'from this sub-group',
              _ => i == chain.length - 1 ? 'only this tag' : 'from this tag',
            },
            chosen: s == _start,
            onTap: () => setState(() => _start = s),
          ),
        ),
    ];
  }

  /// Step two: the user's tags, one level at a time.
  List<Widget> _whereItGoes() {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final mine = _plan.mine.groups;
    final here = _at.lastOrNull;
    final group = _start.group != null;
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
        group
            ? ('Put $_startName here as a new group', const AtTop())
            : (null, null),
      (group: final g?, tag: _) => (
        group
            ? 'Put its tags into ${g.name}'
            : 'Put $_startName here, in ${g.name}',
        IntoGroup(g.id),
      ),
      (group: _, tag: final t?) =>
        group
            ? ('Hang $_startName here, under ${t.name}', UnderTag(t.id))
            : ('Use ${t.name} instead of $_startName', OntoTag(t.id)),
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
    return [
      Text('Where does $_startName go?', style: text.titleLarge),
      const SizedBox(height: 8),
      ShelfField(
        controller: _query,
        hintText: 'Find one of my tags or groups',
        icon: Icons.search,
      ),
      if (q.isNotEmpty) ...[
        for (final g in mine) ...[
          if (g.name.toLowerCase().contains(q))
            row(g.name, (group: g, tag: null), subtitle: 'group'),
          for (final t in g.tags)
            if (t.name.toLowerCase().contains(q))
              row(t.name, (group: null, tag: t), subtitle: 'in ${g.name}'),
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
              Text(' › ', style: text.bodySmall!.copyWith(color: c.muted)),
              TextLink(
                label: (n.group?.name ?? n.tag?.name)!,
                semanticLabel: 'Up to ${(n.group?.name ?? n.tag?.name)!}',
                onPressed: () => setState(() => _at = _at.sublist(0, i + 1)),
              ),
            ],
          ],
        ),
        if (action != null)
          ShelfKey(
            primary: true,
            onPressed: () => _pick(target!),
            child: Text(action),
          )
        else
          HelpLine('Open a group to put $_startName in it.'),
        const SizedBox(height: 8),
        if (below.isEmpty && here?.tag != null)
          HelpLine('No sub-groups under ${here!.tag!.name}.')
        else if (here != null)
          HelpLine(
            here.group != null
                ? 'Or open one of its tags:'
                : 'Or open one of its sub-groups:',
          ),
        ...below,
      ],
    ];
  }

  /// The friend's tags that come along when everything below the start
  /// does: all but the tag being mapped.
  List<Tag> get _others => [
    for (final t in _plan.below(_start))
      if (t.id != widget.tag.id) t,
  ];

  String get _mapLabel {
    final n = _bring ? _others.length + 1 : 1;
    return n == 1 ? 'Map' : 'Map $n tags';
  }

  /// Step three: what the mapping does.
  List<Widget> _check() {
    final text = Theme.of(context).textTheme;
    final c = context.shelf;
    final name = _plan.from.name;
    final planned = _plan.remap(_start, _target!, widget.tag);
    final others = _others;
    final (:creates, :merges) = planned.preview([
      if (_bring) ...others,
      widget.tag,
    ]);
    final muted = text.bodySmall!.copyWith(color: c.muted);
    String myGroup(String id) =>
        _plan.mine.groups.firstWhere((g) => g.id == id).name;
    final theirs = "$name's $_startName";
    final what = switch (_target!) {
      IntoGroup(:final groupId) when _start.group != null =>
        'The tags of $theirs join my ${myGroup(groupId)}.',
      IntoGroup(:final groupId) => '$theirs goes into my ${myGroup(groupId)}.',
      OntoTag(:final tagId) =>
        '$theirs becomes my ${_plan.myTag(tagId)!.name}.',
      UnderTag(:final tagId) =>
        '$theirs hangs under my ${_plan.myTag(tagId)!.name}.',
      AtTop() => '$theirs becomes a group of its own.',
    };
    return [
      Text('Check', style: text.titleLarge),
      const SizedBox(height: 8),
      Text(what, style: text.titleMedium),
      const SizedBox(height: 4),
      Text(
        '${widget.tag.name} lands at '
        '${planned.tagPlace(widget.tag).path.join(' › ')}.',
        style: muted,
      ),
      const SizedBox(height: 16),
      Text('Creates', style: text.labelSmall!.copyWith(color: c.muted)),
      const SizedBox(height: 4),
      if (creates.isEmpty) Text('Nothing new.', style: muted),
      for (final line in creates.take(8)) Text(line, style: muted),
      if (creates.length > 8)
        Text('and ${creates.length - 8} more', style: muted),
      for (final MapEntry(:key, :value) in merges.entries) ...[
        const SizedBox(height: 8),
        HelpLine("$value of $name's tags become my $key."),
      ],
      if (others.isNotEmpty) ...[
        const SizedBox(height: 16),
        TagRow(
          title: others.length == 1
              ? 'Also bring the other tag below $_startName'
              : 'Also bring the other ${others.length} tags below $_startName',
          subtitle: 'Copied into my tags, not set on this album.',
          chosen: _bring,
          onTap: () => setState(() => _bring = !_bring),
        ),
      ],
      const SizedBox(height: 16),
      HelpLine("Remembered for $name's next albums."),
    ];
  }
}
