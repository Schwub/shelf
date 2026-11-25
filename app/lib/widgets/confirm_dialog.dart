import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import 'shelf_key.dart';

/// Asks before something that can't be undone; true when confirmed.
/// [primary] marks the confirm key as the way forward; destructive deletes
/// leave both keys plain and let the label say what happens.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String text,
  required String cancel,
  required String confirm,
  bool primary = true,
}) async {
  final c = context.shelf;
  final style = Theme.of(context).textTheme;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x73000000),
    builder: (context) => Dialog(
      backgroundColor: c.bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: c.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: style.titleLarge),
            const SizedBox(height: 8),
            Text(text, style: style.bodyMedium!.copyWith(color: c.muted)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ShelfKey(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShelfKey(
                    primary: primary,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}
