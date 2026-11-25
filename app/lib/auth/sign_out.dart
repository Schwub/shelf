import 'package:material_ui/material_ui.dart';

import '../widgets/confirm_dialog.dart';
import 'auth.dart';

/// Asks before signing out; the auth gate then shows the sign-in screen.
Future<void> confirmSignOut(BuildContext context, Auth auth) async {
  if (await confirm(
    context,
    title: 'Sign out?',
    text: 'You can sign in again with your email.',
    cancel: 'Cancel',
    confirm: 'Sign out',
  )) {
    await auth.signOut();
  }
}
