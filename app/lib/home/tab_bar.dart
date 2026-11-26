import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/shelf_key.dart';

/// One tab: its icon (outlined, filled while chosen) and name.
typedef ShelfTab = ({IconData icon, IconData selectedIcon, String label});

/// The app's tabs as a row of low keys, quieter than a screen's own: the
/// chosen one is pressed down with its label in the signal colour, like the
/// other choice keys.
class ShelfTabBar extends StatelessWidget {
  const ShelfTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<ShelfTab> tabs;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            children: [
              for (final (i, tab) in tabs.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: ShelfKey(
                    low: true,
                    selected: i == selected,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: () => onSelected(i),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          i == selected ? tab.selectedIcon : tab.icon,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
