import 'package:app_links/app_links.dart';

/// Invite codes from links like `de.schwubware.shelf://invite/K7Q2-M9XD`
/// that open the app (Android; docs/features/friends.md): the one it
/// started with, then those arriving while it runs. The only code that
/// imports app_links; the sign-in link goes to supabase_flutter, which
/// uses the same plugin.
Stream<String> inviteCodes() async* {
  final links = AppLinks();
  final seen = <String>{};
  // Also the link the app started with (app_links 7).
  await for (final uri in links.uriLinkStream) {
    final code = inviteCode(uri);
    if (code != null && seen.add(code)) yield code;
  }
}

/// The code in an invite link, else null.
String? inviteCode(Uri uri) =>
    uri.scheme == 'de.schwubware.shelf' &&
        uri.host == 'invite' &&
        uri.pathSegments.length == 1
    ? uri.pathSegments.single
    : null;
