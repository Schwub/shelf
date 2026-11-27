import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/shelf_colors.dart';
import '../theme/shelf_theme.dart';
import '../widgets/shelf_key.dart';
import 'friends_repository.dart';
import '../widgets/shelf_sheet.dart';

/// Opens the app on the Invitation (Android; iPhones use the code until
/// the scheme is registered there, TASK-20).
Uri inviteLink(String code) =>
    Uri.parse('de.schwubware.shelf://invite/${formatCode(code)}');

/// The message the Share key sends.
String inviteMessage(String inviter, String code) =>
    '$inviter invites you to shelf: ${inviteLink(code)} '
    '(or open shelf and enter the code ${formatCode(code)} under Friends)';

/// A new invite's link and code, to share or copy.
Future<void> showInviteSheet(
  BuildContext context, {
  required Invite invite,
  required String myName,
}) {
  final c = context.shelf;
  final link = inviteLink(invite.code).toString();
  var copied = false;
  return showShelfSheet<void>(
    context: context,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      final label = text.labelSmall!.copyWith(color: c.muted);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Invite a friend', style: text.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Send this to one friend. It works once and for 7 days.',
                style: text.bodyMedium!.copyWith(color: c.muted),
              ),
              const SizedBox(height: 20),
              Text('Link', style: label),
              const SizedBox(height: 4),
              SelectableText(link, style: text.bodyMedium),
              const SizedBox(height: 16),
              Text(
                'Or the code, in the app under Friends → Enter code',
                style: label,
              ),
              const SizedBox(height: 4),
              SelectableText(
                formatCode(invite.code),
                style: archivo(22, width: 125, weight: 700),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    // The key says it worked: a snackbar would sit under
                    // the sheet's barrier.
                    child: StatefulBuilder(
                      builder: (context, setState) => ShelfKey(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: link));
                          setState(() => copied = true);
                        },
                        child: Text(copied ? 'Link copied' : 'Copy link'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShelfKey(
                      primary: true,
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text: inviteMessage(myName, invite.code),
                          sharePositionOrigin: _origin(context),
                        ),
                      ),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Where the share popover points on iPad.
Rect? _origin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
}
