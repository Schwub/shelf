import 'package:material_ui/material_ui.dart';

import '../shelf/shelf.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/list_row.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import '../widgets/shelf_sheet.dart';

/// What the tag's sheet ends with; renaming happens in the sheet.
enum TagAction { subGroup, delete }

/// Rename a tag, open or add its sub-group, or delete it. [onRename] saves
/// a new name and returns the inline error, if any.
Future<TagAction?> showTagActions(
  BuildContext context, {
  required Tag tag,
  required TagGroup? subGroup,
  required bool canHaveSubGroup,
  required Future<String?> Function(String name) onRename,
}) {
  return showShelfSheet<TagAction>(
    context: context,
    builder: (_) => _TagActions(
      tag: tag,
      subGroup: subGroup,
      canHaveSubGroup: canHaveSubGroup,
      onRename: onRename,
    ),
  );
}

class _TagActions extends StatefulWidget {
  const _TagActions({
    required this.tag,
    required this.subGroup,
    required this.canHaveSubGroup,
    required this.onRename,
  });

  final Tag tag;
  final TagGroup? subGroup;
  final bool canHaveSubGroup;
  final Future<String?> Function(String name) onRename;

  @override
  State<_TagActions> createState() => _TagActionsState();
}

class _TagActionsState extends State<_TagActions> {
  late final _name = TextEditingController(text: widget.tag.name);
  late String _saved = widget.tag.name;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Saves a changed name; true when there's nothing left to save.
  Future<bool> _rename() async {
    final name = _name.text.trim();
    if (name == _saved) return true;
    if (name.isEmpty) {
      setState(() => _error = 'Give the tag a name.');
      return false;
    }
    final error = await widget.onRename(name);
    if (!mounted) return false;
    setState(() {
      _error = error;
      if (error == null) _saved = name;
    });
    return error == null;
  }

  Future<void> _close(TagAction action) async {
    if (await _rename() && mounted) Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final sub = widget.subGroup;
    return PopScope(
      // Closing the sheet keeps a changed name.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _rename();
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          28 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.off,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(_saved, style: text.titleLarge),
            const SizedBox(height: 16),
            Text('Name', style: text.labelSmall!.copyWith(color: c.muted)),
            const SizedBox(height: 8),
            ShelfField(
              controller: _name,
              hintText: 'Tag name',
              onSubmitted: (_) => _rename(),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              HelpLine(error, error: true),
            ],
            if (widget.canHaveSubGroup)
              ListRow(
                title: sub == null
                    ? 'Add sub-group'
                    : 'Edit sub-group “${sub.name}”',
                subtitle: 'Shown on an album while $_saved is pressed',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _close(TagAction.subGroup),
              ),
            const SizedBox(height: 20),
            if (widget.tag.builtin != null)
              const HelpLine('Built-in tags can’t be deleted.')
            else
              Align(
                alignment: Alignment.centerLeft,
                child: ShelfKey(
                  onPressed: () => _close(TagAction.delete),
                  child: const Text('Delete tag'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
