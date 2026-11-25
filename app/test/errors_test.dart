import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shelf_app/errors.dart';

void main() {
  test('without a DSN the app runs and nothing is reported', () async {
    var ran = false;
    await runReporting(
      dsn: '',
      environment: 'test',
      app: () async => ran = true,
    );

    expect(ran, isTrue);
    expect(Sentry.isEnabled, isFalse);
    // A no-op, not an error.
    await reportError(Exception('offline'), StackTrace.current);
  });

  test('a report names the account by its ID only', () async {
    final sent = <SentryEvent>[];
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o0.ingest.de.sentry.io/0'
        ..beforeSend = (event, _) {
          sent.add(event);
          return null; // Captured here, never sent.
        };
    });
    addTearDown(Sentry.close);

    await reportAs('3f1c2a4e-account-id');
    await reportError(
      Exception('MusicBrainz answered 503'),
      StackTrace.current,
    );

    final event = sent.single;
    expect(event.user?.id, '3f1c2a4e-account-id');
    expect(event.user?.email, isNull);
    expect(event.user?.ipAddress, isNull);
    expect(event.throwable.toString(), contains('503'));
  });
}
