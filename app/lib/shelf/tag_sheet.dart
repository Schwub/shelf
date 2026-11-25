import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'shelf_data.dart';

/// What the Add sheet ends with: the group (with any tags created in it)
/// and the chosen tags.
typedef TagSheetResult = ({TagGroup group, Set<String> chosen});

/// The Add sheet of a multiple-choice group: search its tags, tick them, or
/// create a new one when nothing matches. Null when dismissed.
Future<TagSheetResult?> showTagSheet(
  BuildContext context, {
  required TagGroup group,
  required Set<String> chosen,
  required Future<Tag> Function(String name) onCreate,
}) {
  final c = context.shelf;
  return showModalBottomSheet<TagSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.bg,
    barrierColor: const Color(0x73000000),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      side: BorderSide(color: c.line),
    ),
    builder: (_) => _TagSheet(group: group, chosen: chosen, onCreate: onCreate),
  );
}

class _TagSheet extends StatefulWidget {
  const _TagSheet({
    required this.group,
    required this.chosen,
    required this.onCreate,
  });

  final TagGroup group;
  final Set<String> chosen;
  final Future<Tag> Function(String name) onCreate;

  @override
  State<_TagSheet> createState() => _TagSheetState();
}

class _TagSheetState extends State<_TagSheet> {
  late TagGroup _group = widget.group;
  late final Set<String> _chosen = {...widget.chosen};
  final _query = TextEditingController();
  String? _failed;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() => _failed = null));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// "shoegaze" becomes "Shoegaze".
  String get _newName {
    final q = _query.text.trim();
    return q.isEmpty ? q : q[0].toUpperCase() + q.substring(1);
  }

  Future<void> _create() async {
    final name = _newName;
    setState(() => _creating = true);
    try {
      final tag = await widget.onCreate(name);
      if (!mounted) return;
      setState(() {
        _group = _group.withTag(tag);
        _chosen.add(tag.id);
        _creating = false;
        _query.clear();
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) {
        setState(() {
          _creating = false;
          _failed = name;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final query = _query.text.trim().toLowerCase();
    // Alphabetical, to scroll or search through a long list.
    final matches = [
      for (final t in _group.tags)
        if (t.name.toLowerCase().contains(query)) t,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final exact = _group.tags.any((t) => t.name.toLowerCase() == query);
    final lower = _group.name.toLowerCase();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
              Text(_group.name, style: text.titleLarge),
              const SizedBox(height: 12),
              ShelfField(
                controller: _query,
                hintText: 'Search $lower',
                icon: Icons.search,
              ),
              if (_failed != null) ...[
                const SizedBox(height: 12),
                HelpLine(
                  "Couldn't create “$_failed”. Check your connection and try "
                  'again.',
                  error: true,
                ),
              ],
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in matches)
                      _Row(
                        title: t.name,
                        chosen: _chosen.contains(t.id),
                        onTap: () => setState(
                          () => _chosen.contains(t.id)
                              ? _chosen.remove(t.id)
                              : _chosen.add(t.id),
                        ),
                      ),
                    if (query.isNotEmpty && !exact)
                      _Row(
                        title: 'Create “$_newName”',
                        subtitle: 'New tag in ${_group.name}',
                        create: true,
                        onTap: _creating ? null : _create,
                      ),
                    if (query.isNotEmpty && matches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'No $lower matches “${_query.text.trim()}”.',
                          style: text.bodySmall!.copyWith(color: c.muted),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ShelfKey(
                primary: true,
                onPressed: () =>
                    Navigator.of(context).pop((group: _group, chosen: _chosen)),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 56 px list row with a light window (lit = chosen), or a + for Create.
class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.chosen = false,
    this.create = false,
  });

  final String title;
  final String? subtitle;
  final bool chosen, create;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: create ? null : chosen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: create
                    ? Icon(Icons.add, size: 16, color: c.muted)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 10,
                          height: 6,
                          decoration: BoxDecoration(
                            color: chosen ? c.signal : c.window,
                            borderRadius: BorderRadius.circular(2),
                            border: chosen ? null : Border.all(color: c.off),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: text.bodySmall!.copyWith(color: c.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
