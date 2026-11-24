import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Signing in with an emailed code (or the link in the same email).
///
/// An interface so the screens can be tested without a server.
abstract class Auth {
  bool get signedIn;

  /// Emits whenever the user signs in or out, and a [LinkFailed] error when
  /// the email's link has expired, was used or came from another device.
  Stream<bool> get changes;

  /// Sends the sign-in email; signs the user up if the email is new.
  /// Throws [TooManyEmails] when the server's email limit is reached.
  Future<void> sendCode(String email);

  /// Throws [WrongCode] when the code is wrong or has expired.
  Future<void> verifyCode(String email, String code);

  Future<void> signOut();
}

class WrongCode implements Exception {}

class TooManyEmails implements Exception {}

class LinkFailed implements Exception {}

/// An error from the link's return address: expired or used
/// (`error_code=otp_expired`, `error=access_denied`), or no code to finish
/// the sign-in because the link was requested on another device.
bool isLinkError(dynamic e) =>
    e is AuthPKCEGrantCodeExchangeError ||
    e is AuthException &&
        (e.statusCode == 'otp_expired' || e.code == 'access_denied');

/// Where the email's link returns to on phones (see AndroidManifest.xml).
const signInLink = 'de.schwubware.shelf://login';

class SupabaseAuth implements Auth {
  SupabaseAuth(this._client);

  final GoTrueClient _client;

  @override
  bool get signedIn => _client.currentSession != null;

  @override
  Stream<bool> get changes => _client.onAuthStateChange
      .map((state) => state.session != null)
      .handleError((Object _) => throw LinkFailed(), test: isLinkError);

  @override
  Future<void> sendCode(String email) async {
    try {
      await _client.signInWithOtp(
        email: email,
        // The link in the email comes back to this web app or this phone app.
        emailRedirectTo: kIsWeb ? Uri.base.origin : signInLink,
      );
    } on AuthException catch (e) {
      if (e.code == 'over_email_send_rate_limit') throw TooManyEmails();
      rethrow;
    }
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    try {
      await _client.verifyOTP(email: email, token: code, type: OtpType.email);
    } on AuthException catch (e) {
      if (e.code == 'otp_expired') throw WrongCode();
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _client.signOut();
}
