import 'package:flutter/foundation.dart';

/// The latest link shared into the app, held until the shelf takes it: a
/// link that launches the app signed out waits through the sign-in.
class SharedLinkInbox extends ValueNotifier<Uri?> {
  SharedLinkInbox(Stream<Uri> links) : super(null) {
    links.listen((link) => value = link);
  }

  Uri? take() {
    final link = value;
    value = null;
    return link;
  }
}
