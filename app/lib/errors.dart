import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';

/// Error reporting (docs/architecture.md, "Error reporting"): crashes and
/// unhandled errors go to Sentry, with handled ones the app shows the user
/// added by [reportError]. The only code that imports Sentry. Without a DSN
/// (local builds, tests) nothing is sent.
///
/// [start] runs before Sentry starts (the bindings, anything that can't
/// wait), in the same zone as [app]: Flutter needs `runApp` in the zone that
/// initialized the bindings, and on web Sentry otherwise starts its own
/// ("Zone Mismatch Error on Web" in Sentry's Flutter troubleshooting docs).
Future<void> runReporting({
  required String dsn,
  required String environment,
  required void Function() start,
  required Future<void> Function() app,
}) async {
  if (dsn.isEmpty) {
    start();
    return app();
  }
  await Sentry.runZonedGuarded(
    () async {
      start();
      await SentryFlutter.init((options) {
        options
          ..dsn = dsn
          ..environment = environment
          // No emails or request bodies; the user is only their anonymous
          // account ID ([reportAs]). IP addresses: docs/architecture.md.
          ..sendDefaultPii = false;
      }, appRunner: app);
    },
    // Sentry has the error; still show it while developing.
    (error, stack) => FlutterError.dumpErrorToConsole(
      FlutterErrorDetails(exception: error, stack: stack),
      forceReport: true,
    ),
  );
}

/// An error the app handled (it shows "Couldn't …"), still worth knowing
/// about: a failing service shows up before users report it.
Future<void> reportError(Object error, StackTrace stack) =>
    Sentry.captureException(error, stackTrace: stack);

/// Reports name the signed-in account by its ID only; null when signed out.
Future<void> reportAs(String? userId) async => Sentry.configureScope(
  (scope) => scope.setUser(userId == null ? null : SentryUser(id: userId)),
);

/// [client] that leaves a breadcrumb per request, so a report shows the
/// calls before it (e.g. MusicBrainz answering 503). Failed answers aren't
/// reported on their own: the code handles them.
http.Client reportingClient(http.Client client) =>
    SentryHttpClient(client: client, failedRequestStatusCodes: const []);
