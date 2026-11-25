import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A request dropped because a newer one replaced it before it was sent.
class Superseded implements Exception {}

/// The app's one way to MusicBrainz. It allows a client one request a
/// second and answers 503 beyond that, which happens quickly while typing a
/// search. So requests go one at a time, at most one per [gap], and a 503 is
/// tried again twice before it counts as an error.
class MusicBrainz {
  MusicBrainz(
    this._client, {
    String contact = '',
    this.gap = const Duration(milliseconds: 1100),
  }) : _headers = {
         // Browsers don't let a page set the User-Agent.
         if (!kIsWeb)
           'User-Agent': contact.isEmpty
               ? 'shelf/1.0'
               : 'shelf/1.0 ( $contact )',
       };

  final http.Client _client;
  final Map<String, String> _headers;
  final Duration gap;

  static const _retries = 2;

  /// When the previous request may be followed by the next.
  Future<void> _free = Future.value();

  /// GETs [url] in its turn. [wanted] is asked just before sending: a
  /// request it turns down throws [Superseded] without being sent.
  Future<http.Response> get(Uri url, {bool Function()? wanted}) async {
    for (var attempt = 0; ; attempt++) {
      await _turn();
      if (wanted != null && !wanted()) throw Superseded();
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode != 503 || attempt == _retries) return response;
    }
  }

  /// Waits for the previous request's turn, then holds the next one off for
  /// [gap].
  Future<void> _turn() {
    final previous = _free;
    final next = Completer<void>();
    _free = next.future;
    return previous.then((_) {
      Timer(gap, next.complete);
    });
  }
}
