import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// A bottom sheet in shelf's look, over the navigation bar like a dialog.
Future<T?> showShelfSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final c = context.shelf;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: c.bg,
    barrierColor: const Color(0x73000000),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      side: BorderSide(color: c.line),
    ),
    builder: builder,
  );
}
