import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// A teak shelf line: 4 px with a lighter top edge and a 10 px soft shadow
/// below, painted over whatever follows.
class ShelfBoard extends StatelessWidget {
  const ShelfBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.shelf.teak,
                border: const Border(top: BorderSide(color: Color(0x33FFFFFF))),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 3,
            height: 10,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [context.shelf.shadow, const Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
