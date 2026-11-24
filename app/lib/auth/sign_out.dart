import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/shelf_key.dart';
import 'auth.dart';

/// Asks before signing out; the auth gate then shows the sign-in screen.
Future<void> confirmSignOut(BuildContext context, Auth auth) async {
  final c = context.shelf;
  final text = Theme.of(context).textTheme;
  final signOut = await showDialog<bool>(
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
            Text('Sign out?', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              'You can sign in again with your email.',
              style: text.bodyMedium!.copyWith(color: c.muted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ShelfKey(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShelfKey(
                    primary: true,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (signOut ?? false) await auth.signOut();
}
