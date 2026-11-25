import 'dart:async';

import 'package:shelf_app/share/link_resolver.dart';

/// Answers every link with [answer], or throws it when it's an exception;
/// [answer] can change between calls. Records the links.
class FakeLinks implements LinkResolver {
  FakeLinks(this.answer);

  Object answer;
  final links = <Uri>[];

  /// Completes the next answer when set, to see "Finding album…".
  Completer<void>? hold;

  @override
  Future<Resolved> resolve(Uri link) async {
    links.add(link);
    await hold?.future;
    return switch (answer) {
      final Resolved r => r,
      final e => throw e,
    };
  }
}
