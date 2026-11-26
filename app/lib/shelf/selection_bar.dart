import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/shelf_key.dart';

/// My shelf's bottom row while selecting (TASK-40): Tags, Hide (Show when
/// all selected are hidden) and Remove, off while nothing is selected.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.count,
    required this.allHidden,
    required this.onTags,
    required this.onHide,
    required this.onRemove,
  });

  final int count;
  final bool allHidden;
  final VoidCallback onTags, onHide, onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final some = count > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              for (final (i, (label, action)) in [
                ('Tags', onTags),
                (allHidden ? 'Show' : 'Hide', onHide),
                ('Remove', onRemove),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: ShelfKey(
                    onPressed: some ? action : null,
                    child: Text(label),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
