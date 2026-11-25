import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../shelf/entry_page.dart';
import '../shelf/shelf_data.dart';
import '../theme/shelf_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/help_line.dart';
import '../widgets/list_row.dart';
import '../widgets/note.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'tag_actions_sheet.dart';

/// Edits one tag group: name, one or several tags per album, its tags (add,
/// rename, reorder, delete, sub-group) and hiding or deleting the group.
/// Changes save as they're made. [TagGroupPage.create] makes a new group,
/// or a sub-group under [parentTag], with "Create group".
class TagGroupPage extends StatefulWidget {
  const TagGroupPage({
    super.key,
    required this.shelf,
    required String this.groupId,
  }) : parentTag = null;

  const TagGroupPage.create({super.key, required this.shelf, this.parentTag})
    : groupId = null;

  final ShelfRepository shelf;
  final String? groupId;

  /// The tag a new sub-group goes under.
  final Tag? parentTag;

  @override
  State<TagGroupPage> createState() => _TagGroupPageState();
}

/// A change that didn't save: the message, and how to try it again.
typedef _Failure = ({String message, Future<void> Function()? retry});

class _TagGroupPageState extends State<TagGroupPage> {
  bool get _creating => widget.groupId == null;

  Shelf? _shelf;
  bool _loadFailed = false;
  final _name = TextEditingController();
  final _newTag = TextEditingController();
  bool _addingTag = false;
  String? _nameError, _tagError;
  _Failure? _failed;

  /// Albums with several of this group's tags, after switching to one per
  /// album was refused.
  List<ShelfEntry>? _several;

  /// The tags in their order; reordering updates it before the save.
  List<Tag> _tags = [];

  // A new group's choices, saved with "Create group".
  bool _exclusive = false, _pickFromList = false;

  @override
  void initState() {
    super.initState();
    if (!_creating) _load(initial: true);
  }

  @override
  void dispose() {
    _name.dispose();
    _newTag.dispose();
    super.dispose();
  }

  TagGroup? get _group =>
      _shelf?.allGroups.where((g) => g.id == widget.groupId).firstOrNull;

  Future<void> _load({bool initial = false}) async {
    setState(() => _loadFailed = false);
    try {
      final shelf = await widget.shelf.load();
      if (!mounted) return;
      setState(() {
        _shelf = shelf;
        final group = _group;
        if (group == null) return;
        _tags = [...group.tags];
        if (initial) _name.text = group.name;
        if (_several != null) _several = _withSeveral(group);
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted && _shelf == null) setState(() => _loadFailed = true);
    }
  }

  List<ShelfEntry> _withSeveral(TagGroup group) {
    final ids = {for (final t in group.tags) t.id};
    return [
      for (final e in _shelf!.entries)
        if (e.tagIds.intersection(ids).length > 1) e,
    ];
  }

  /// Saves [change] and reloads; shows the save error with Try again.
  /// [onDuplicate] shows the inline error for a name already used.
  Future<bool> _save(
    String what,
    Future<void> Function() change, {
    void Function()? onDuplicate,
  }) async {
    setState(() {
      _failed = null;
      _several = null;
    });
    try {
      await change();
    } on DuplicateName {
      if (mounted) setState(() => onDuplicate?.call());
      return false;
    } on SeveralTags {
      if (mounted) setState(() => _several = _withSeveral(_group!));
      return false;
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) {
        setState(
          () => _failed = (
            message:
                'Couldn’t save $what. Check your connection and try again.',
            retry: () => _save(what, change, onDuplicate: onDuplicate),
          ),
        );
      }
      return false;
    }
    if (mounted) await _load();
    return true;
  }

  Future<void> _saveName() async {
    final group = _group;
    final name = _name.text.trim();
    if (group == null || name == group.name) {
      setState(() => _nameError = null);
      return;
    }
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the group a name.');
      return;
    }
    setState(() => _nameError = null);
    await _save(
      '“$name”',
      () => widget.shelf.updateGroup(group.id, name: name),
      onDuplicate: () =>
          _nameError = 'You already have a group called “$name”.',
    );
  }

  Future<void> _setExclusive(bool exclusive) async {
    if (_creating) {
      setState(() => _exclusive = exclusive);
      return;
    }
    final group = _group!;
    if (group.exclusive == exclusive) return;
    await _save(
      'the change to ${exclusive ? 'one' : 'several'} per album',
      () => widget.shelf.updateGroup(group.id, exclusive: exclusive),
    );
  }

  Future<void> _setPickFromList(bool pick) async {
    if (_creating) {
      setState(() => _pickFromList = pick);
      return;
    }
    final group = _group!;
    if (group.pickFromList == pick) return;
    await _save(
      'how “${group.name}” shows on albums',
      () => widget.shelf.updateGroup(group.id, pickFromList: pick),
    );
  }

  String get _groupName => _creating ? _name.text.trim() : (_group?.name ?? '');

  Future<void> _addTag() async {
    final name = _newTag.text.trim();
    if (name.isEmpty) {
      setState(() => _tagError = 'Give the tag a name.');
      return;
    }
    final duplicate =
        '${_groupName.isEmpty ? 'This group' : _groupName} '
        'already has “$name”.';
    if (_creating) {
      if (_tags.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
        setState(() => _tagError = duplicate);
        return;
      }
      setState(() {
        _tags.add(Tag(id: name, groupId: '', name: name));
        _newTag.clear();
        _tagError = null;
      });
      return;
    }
    setState(() => _tagError = null);
    final saved = await _save(
      '“$name”',
      () => widget.shelf.createTag(_group!.id, name),
      onDuplicate: () => _tagError = duplicate,
    );
    if (saved && mounted) setState(_newTag.clear);
  }

  Future<void> _reorderTags(int from, int to) async {
    setState(() => _tags.insert(to, _tags.removeAt(from)));
    if (_creating) return;
    final saved = await _save(
      'the new order',
      () => widget.shelf.reorderTags([for (final t in _tags) t.id]),
    );
    if (!saved && mounted) await _load();
  }

  Future<void> _tagActions(Tag tag) async {
    final shelf = _shelf;
    final group = _group;
    if (_creating || shelf == null || group == null) {
      // A new group's tags are only names until it's created.
      setState(() => _tags.remove(tag));
      return;
    }
    final sub = shelf.subGroupOf(tag.id);
    final action = await showTagActions(
      context,
      tag: tag,
      subGroup: sub,
      // Sub-groups go one level deep.
      canHaveSubGroup: group.parentTagId == null,
      onRename: (name) async {
        String? error;
        await _save(
          '“$name”',
          () => widget.shelf.renameTag(tag.id, name),
          onDuplicate: () => error = '${group.name} already has “$name”.',
        );
        return error;
      },
    );
    if (!mounted) return;
    switch (action) {
      case TagAction.subGroup:
        await _push(
          sub != null
              ? TagGroupPage(shelf: widget.shelf, groupId: sub.id)
              : TagGroupPage.create(shelf: widget.shelf, parentTag: tag),
        );
      case TagAction.delete:
        if (await confirm(
          context,
          title: 'Delete “${tag.name}”?',
          text: _tagDeleteText(shelf, tag),
          cancel: 'Cancel',
          confirm: 'Delete',
          primary: false,
        )) {
          await _save(
            'the deletion of “${tag.name}”',
            () => widget.shelf.deleteTag(tag.id),
          );
        }
      case null:
        break;
    }
  }

  Future<void> _push(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) await _load();
  }

  Future<void> _delete() async {
    final shelf = _shelf!, group = _group!;
    if (!await confirm(
      context,
      title: 'Delete “${group.name}”?',
      text: _groupDeleteText(shelf, group),
      cancel: 'Cancel',
      confirm: 'Delete',
      primary: false,
    )) {
      return;
    }
    final deleted = await _save(
      'the deletion of “${group.name}”',
      () => widget.shelf.deleteGroup(group.id),
    );
    if (deleted && mounted) Navigator.of(context).pop();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Give the group a name.');
      return;
    }
    setState(() {
      _nameError = null;
      _failed = null;
    });
    try {
      await widget.shelf.createGroup(
        name,
        exclusive: _exclusive,
        pickFromList: _pickFromList,
        parentTagId: widget.parentTag?.id,
        tags: [for (final t in _tags) t.name],
      );
    } on DuplicateName {
      if (mounted) {
        setState(() => _nameError = 'You already have a group called “$name”.');
      }
      return;
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) {
        setState(
          () => _failed = (
            message:
                'Couldn’t save “$name”. Check your connection and try again.',
            retry: _create,
          ),
        );
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final group = _group;
    final title = _creating
        ? (widget.parentTag != null ? 'New sub-group' : 'New group')
        : group?.name ?? '';
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  ShelfKey(
                    semanticLabel: 'Back',
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: text.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    if (_loadFailed) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 96, 28, 24),
        children: [
          Text(
            'Couldn’t load this group',
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            style: text.bodyMedium!.copyWith(color: c.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: ShelfKey(
              primary: true,
              onPressed: () => _load(initial: true),
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }
    final group = _group;
    if (!_creating && group == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final label = text.labelSmall!.copyWith(color: c.muted);
    final hint = text.bodySmall!.copyWith(color: c.muted, height: 1.45);
    Widget heading(String name) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(name, style: label),
    );
    final parent = widget.parentTag?.name ?? _parentName(group);
    final exclusive = _creating ? _exclusive : group!.exclusive;
    final pickFromList = _creating ? _pickFromList : group!.pickFromList;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (_failed case final failed?)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Note(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(failed.message),
                  if (failed.retry case final retry?) ...[
                    const SizedBox(height: 8),
                    ShelfKey(onPressed: retry, child: const Text('Try again')),
                  ],
                ],
              ),
            ),
          ),
        if (_several case final several?) _severalNote(group!, several),
        if (parent != null)
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Sub-group under '),
                TextSpan(
                  text: parent,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ': shown on an album while $parent is pressed.'),
              ],
            ),
            style: text.bodyMedium!.copyWith(color: c.muted),
          ),
        heading('Name'),
        Focus(
          // Leaving the field saves the name.
          onFocusChange: (focused) {
            if (!focused && !_creating) _saveName();
          },
          child: ShelfField(
            controller: _name,
            hintText: 'e.g. Mood',
            onSubmitted: (_) => _creating ? null : _saveName(),
          ),
        ),
        if (_nameError case final error?) ...[
          const SizedBox(height: 8),
          HelpLine(error, error: true),
        ],
        heading('Tags per album'),
        if (group?.builtin ?? false)
          Text('One per album. Built-in groups stay that way.', style: hint)
        else
          Row(
            children: [
              for (final (one, name) in [
                (true, 'One'),
                (false, 'Several'),
              ]) ...[
                if (!one) const SizedBox(width: 8),
                Expanded(
                  child: ShelfKey(
                    light: true,
                    selected: exclusive == one,
                    onPressed: () => _setExclusive(one),
                    child: Text(name),
                  ),
                ),
              ],
            ],
          ),
        heading('On albums'),
        Row(
          children: [
            for (final (pick, name) in [
              (false, 'All as keys'),
              (true, 'Pick from a list'),
            ]) ...[
              if (pick) const SizedBox(width: 8),
              Expanded(
                child: ShelfKey(
                  light: true,
                  selected: pickFromList == pick,
                  onPressed: () => _setPickFromList(pick),
                  child: Text(name),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          pickFromList
              ? 'Albums show only their chosen tags; Add picks more.'
              : 'Albums show every tag as a key.',
          style: hint,
        ),
        heading('Tags'),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: _reorderTags,
          children: [
            for (final (i, tag) in _tags.indexed)
              ListRow(
                key: ValueKey(tag.id),
                title: tag.name,
                subtitle: _creating ? null : _tagLine(_shelf!, tag),
                mark: tag.builtin ? 'Built-in' : null,
                leading: ReorderableDragStartListener(
                  index: i,
                  child: Semantics(
                    label: 'Reorder ${tag.name}',
                    child: const Icon(Icons.drag_handle),
                  ),
                ),
                trailing: Semantics(
                  label: _creating ? 'Remove ${tag.name}' : 'More',
                  button: true,
                  child: Icon(_creating ? Icons.close : Icons.more_horiz),
                ),
                onTap: () => _tagActions(tag),
              ),
          ],
        ),
        if (_addingTag)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ShelfField(
                        controller: _newTag,
                        hintText: 'Tag name',
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShelfKey(
                      semanticLabel: 'Add',
                      padding: EdgeInsets.zero,
                      onPressed: _addTag,
                      child: const Icon(Icons.check),
                    ),
                  ],
                ),
                if (_tagError case final error?) ...[
                  const SizedBox(height: 8),
                  HelpLine(error, error: true),
                ],
              ],
            ),
          )
        else
          ListRow(
            title: 'Add tag',
            leading: const Icon(Icons.add, size: 16),
            onTap: () => setState(() => _addingTag = true),
          ),
        const SizedBox(height: 20),
        ..._footer(context, group, hint),
      ],
    );
  }

  List<Widget> _footer(BuildContext context, TagGroup? group, TextStyle hint) {
    if (_creating) {
      return [
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
                onPressed: _create,
                child: const Text('Create group'),
              ),
            ),
          ],
        ),
      ];
    }
    return [
      if (group!.builtin) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: ShelfKey(
            light: true,
            selected: group.hidden,
            onPressed: () => _save(
              group.hidden ? 'showing the group' : 'hiding the group',
              () => widget.shelf.updateGroup(group.id, hidden: !group.hidden),
            ),
            child: const Text('Hide this group'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Hidden tags disappear from albums and filters, but stay saved.',
          style: hint,
        ),
        const SizedBox(height: 16),
        const Note(
          icon: Icons.info_outline,
          child: Text(
            'Built-in groups can be renamed or hidden, not deleted. '
            'Friends’ shelves use them to compare.',
          ),
        ),
      ] else
        Align(
          alignment: Alignment.centerLeft,
          child: ShelfKey(
            onPressed: _delete,
            child: const Text('Delete group'),
          ),
        ),
      const SizedBox(height: 16),
      Text('Changes are saved as you make them.', style: hint),
    ];
  }

  Widget _severalNote(TagGroup group, List<ShelfEntry> several) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Note(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Can’t switch to One: ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      '${_albums(several.length)} more than one '
                      '${group.name} tag. Change them first.',
                ),
              ],
            ),
          ),
          for (final entry in several)
            ListRow(
              title: entry.album.title,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _push(
                EntryPage(
                  entry: entry,
                  shelf: widget.shelf,
                  groups: _shelf!.groups,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  String? _parentName(TagGroup? group) {
    final parentId = group?.parentTagId;
    if (parentId == null) return null;
    for (final g in _shelf!.allGroups) {
      for (final t in g.tags) {
        if (t.id == parentId) return t.name;
      }
    }
    return null;
  }
}

/// "3 albums have", "1 album has".
String _albums(int n) => n == 1 ? '1 album has' : '$n albums have';

String _count(int n, String noun) => n == 1 ? '1 $noun' : '$n ${noun}s';

/// "On 12 albums · opens Format".
String _tagLine(Shelf shelf, Tag tag) {
  final n = shelf.albumsWith(tag.id);
  final on = n == 0 ? 'On no albums' : 'On ${_count(n, 'album')}';
  final sub = shelf.subGroupOf(tag.id);
  return sub == null ? on : '$on · opens ${sub.name}';
}

/// What else goes with a deleted tag or group: "Its sub-group “From whom”
/// (2 tags) and 1 filter go too."
String _goesToo(Shelf shelf, Iterable<Tag> tags) {
  final ids = {for (final t in tags) t.id};
  final subs = [
    for (final g in shelf.allGroups)
      if (ids.contains(g.parentTagId)) g,
  ];
  for (final s in subs) {
    ids.addAll(s.tags.map((t) => t.id));
  }
  // Filters left with nothing to match by go with their tags.
  final filters = shelf.allFilters
      .where(
        (f) =>
            f.tagIds.isNotEmpty &&
            f.tagIds.every(ids.contains) &&
            f.minRating == null &&
            !f.unrated &&
            !f.favoriteTracks,
      )
      .length;
  final items = [
    for (final s in subs)
      'sub-group “${s.name}” (${_count(s.tags.length, 'tag')})',
    if (filters > 0) _count(filters, 'filter'),
  ];
  if (items.isEmpty) return '';
  final plural = items.length > 1 || filters > 1;
  final list = items.length == 1
      ? items.single
      : '${items.take(items.length - 1).join(', ')} and ${items.last}';
  final start = subs.isEmpty ? list : 'Its $list';
  return ' $start ${plural ? 'go' : 'goes'} too.';
}

String _tagDeleteText(Shelf shelf, Tag tag) {
  final n = shelf.albumsWith(tag.id);
  final albums = switch (n) {
    0 => 'It isn’t on any albums.',
    1 => 'It’s on 1 album and will be removed from it.',
    _ => 'It’s on $n albums and will be removed from them.',
  };
  return '$albums${_goesToo(shelf, [tag])}';
}

String _groupDeleteText(Shelf shelf, TagGroup group) {
  final ids = {for (final t in group.tags) t.id};
  final n = shelf.entries.where((e) => e.tagIds.any(ids.contains)).length;
  final k = group.tags.length;
  final tags = k == 1 ? 'Its tag is' : 'Its $k tags are';
  final albums = k == 0
      ? 'It has no tags.'
      : switch (n) {
          0 => '$tags on no albums.',
          1 => '$tags on 1 album and will be removed from it.',
          _ => '$tags on $n albums and will be removed from them.',
        };
  return '$albums${_goesToo(shelf, group.tags)}';
}
