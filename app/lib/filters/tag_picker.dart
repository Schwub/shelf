import 'package:material_ui/material_ui.dart';

import '../shelf/shelf.dart';
import '../theme/shelf_colors.dart';
import '../widgets/list_row.dart';
import '../widgets/shelf_key.dart';
import '../widgets/shelf_sheet.dart';

/// All tags by group, for filters. With [multiple] they are ticked and Done
/// returns the chosen ones; otherwise tapping a tag returns it alone.
/// [extra] goes above the groups (Add filter's "Custom filter…").
Future<Set<String>?> showTagPicker(
  BuildContext context, {
  required String title,
  required List<TagGroup> groups,
  Set<String> chosen = const {},
  bool multiple = false,
  Widget? extra,
}) {
  return showShelfSheet<Set<String>>(
    context: context,
    builder: (_) => _TagPicker(
      title: title,
      groups: groups,
      chosen: chosen,
      multiple: multiple,
      extra: extra,
    ),
  );
}

class _TagPicker extends StatefulWidget {
  const _TagPicker({
    required this.title,
    required this.groups,
    required this.chosen,
    required this.multiple,
    this.extra,
  });

  final String title;
  final List<TagGroup> groups;
  final Set<String> chosen;
  final bool multiple;
  final Widget? extra;

  @override
  State<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<_TagPicker> {
  late final _chosen = {...widget.chosen};

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final parentName = {
      for (final g in widget.groups)
        for (final t in g.tags) t.id: t.name,
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
            Text(widget.title, style: text.titleLarge),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ?widget.extra,
                  for (final g in widget.groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: Text(
                        g.parentTagId == null
                            ? g.name
                            : '${g.name} · under ${parentName[g.parentTagId]}',
                        style: text.labelSmall!.copyWith(color: c.muted),
                      ),
                    ),
                    for (final t in g.tags)
                      ListRow(
                        title: t.name,
                        trailing: _chosen.contains(t.id)
                            ? Icon(Icons.check, color: c.signal)
                            : null,
                        onTap: () {
                          if (!widget.multiple) {
                            Navigator.of(context).pop({t.id});
                            return;
                          }
                          setState(
                            () => _chosen.contains(t.id)
                                ? _chosen.remove(t.id)
                                : _chosen.add(t.id),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
            if (widget.multiple) ...[
              const SizedBox(height: 16),
              ShelfKey(
                primary: true,
                onPressed: () => Navigator.of(context).pop(_chosen),
                child: const Text('Done'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
