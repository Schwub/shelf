import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/auth/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('expired, used and other-device links count as failed links', () {
    // What getSessionFromUrl throws for ?error=access_denied&error_code=otp_expired
    expect(
      isLinkError(
        AuthException(
          'Email link is invalid or has expired',
          statusCode: 'otp_expired',
          code: 'access_denied',
        ),
      ),
      isTrue,
    );
    expect(isLinkError(AuthPKCEGrantCodeExchangeError('no verifier')), isTrue);
  });

  test('other auth errors are not link errors', () {
    expect(
      isLinkError(AuthException('Invalid Refresh Token', code: 'refresh')),
      isFalse,
    );
    expect(isLinkError(Exception('offline')), isFalse);
  });
}
