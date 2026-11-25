import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf_app/search/album_search.dart';

void main() {
  test('asks MusicBrainz for albums and reads the results', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      // The fields shelf reads from a release-group search (recorded shape).
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'release-groups': [
              {
                'id': 'b1392450-e666-3926-a536-22c65f834433',
                'title': 'OK Computer',
                'first-release-date': '1997-05-21',
                'artist-credit': [
                  {'name': 'Radiohead', 'joinphrase': ''},
                ],
              },
              {
                'id': 'x',
                'title': 'Ágætis byrjun',
                'first-release-date': '',
                'artist-credit': [
                  {'name': 'Sigur Rós'},
                ],
              },
            ],
          }),
        ),
        200,
      );
    });

    final results = await MusicBrainzSearch(
      client,
      contact: 'someone@example.com',
    ).search('  ok computer ');

    expect(sent.url.host, 'musicbrainz.org');
    expect(sent.url.path, '/ws/2/release-group');
    expect(
      sent.url.queryParameters['query'],
      '(ok AND computer) AND primarytype:album',
    );
    expect(sent.headers['User-Agent'], 'shelf/1.0 ( someone@example.com )');
    expect(results.first.title, 'OK Computer');
    expect(results.first.artist, 'Radiohead');
    expect(results.first.year, 1997);
    expect(
      results.first.thumbnailUrl,
      'https://coverartarchive.org/release-group/b1392450-e666-3926-a536-22c65f834433/front-250',
    );
    expect(results.last.title, 'Ágætis byrjun');
    expect(results.last.year, isNull);
  });

  test('query syntax in the text is escaped', () {
    expect(
      MusicBrainzSearch.query('AC/DC: Back in Black!'),
      r'(AC\/DC\: AND Back AND in AND Black\!) AND primarytype:album',
    );
  });

  test('a server error fails the search', () async {
    final client = MockClient((_) async => http.Response('', 503));
    expect(
      MusicBrainzSearch(client).search('x'),
      throwsA(isA<http.ClientException>()),
    );
  });
}
