import 'package:app_links/app_links.dart';

/// Invite codes from links like `de.schwubware.shelf://invite/K7Q2-M9XD`
/// that open the app (Android; docs/features/friends.md): the one it
/// started with, then those arriving while it runs. The only code that
/// imports app_links; the sign-in link goes to supabase_flutter, which
/// uses the same plugin.
Stream<String> inviteCodes() {
  final links = AppLinks();
  return inviteCodesFrom(links.getInitialLink(), links.uriLinkStream);
}

/// The stream doesn't replay the link the app started with to a late
/// listener (supabase_flutter listens first), so it is asked for; when
/// the stream brings it too, that copy is skipped once.
Stream<String> inviteCodesFrom(Future<Uri?> initial, Stream<Uri> links) async* {
  final first = await initial;
  var duplicate = first;
  if (first != null) {
    if (inviteCode(first) case final code?) yield code;
  }
  await for (final uri in links) {
    if (uri == duplicate) {
      duplicate = null;
      continue;
    }
    duplicate = null;
    if (inviteCode(uri) case final code?) yield code;
  }
}

/// The code in an invite link, else null.
String? inviteCode(Uri uri) =>
    uri.scheme == 'de.schwubware.shelf' &&
        uri.host == 'invite' &&
        uri.pathSegments.length == 1
    ? uri.pathSegments.single
    : null;
