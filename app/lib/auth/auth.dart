import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Signing in with an emailed code (or the link in the same email).
///
/// An interface so the screens can be tested without a server.
abstract class Auth {
  bool get signedIn;

  /// Emits whenever the user signs in or out.
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

class SupabaseAuth implements Auth {
  SupabaseAuth(this._client);

  final GoTrueClient _client;

  @override
  bool get signedIn => _client.currentSession != null;

  @override
  Stream<bool> get changes =>
      _client.onAuthStateChange.map((state) => state.session != null);

  @override
  Future<void> sendCode(String email) async {
    try {
      await _client.signInWithOtp(
        email: email,
        // The link in the email comes back to this web app; app links on
        // phones are a separate task.
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
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
