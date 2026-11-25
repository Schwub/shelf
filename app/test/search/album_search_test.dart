import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf_app/search/album_search.dart';
import 'package:shelf_app/search/musicbrainz.dart';

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
      MusicBrainz(client, gap: Duration.zero),
    ).search('  ok computer ');

    expect(sent.url.host, 'musicbrainz.org');
    expect(sent.url.path, '/ws/2/release-group');
    expect(
      sent.url.queryParameters['query'],
      '(ok AND computer) AND primarytype:album',
    );
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
    final client = MockClient((_) async => http.Response('', 500));
    expect(
      MusicBrainzSearch(MusicBrainz(client, gap: Duration.zero)).search('x'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('a busy MusicBrainz (503) is asked again, not an error', () async {
    var calls = 0;
    final client = MockClient(
      (_) async => ++calls == 1
          ? http.Response('', 503)
          : http.Response('{"release-groups": []}', 200),
    );
    expect(
      await MusicBrainzSearch(MusicBrainz(client, gap: Duration.zero))
          .search('x'),
      isEmpty,
    );
    expect(calls, 2);
  });

  testWidgets('typing on drops the searches still waiting', (tester) async {
    final queries = <String>[];
    final search = MusicBrainzSearch(
      MusicBrainz(
        MockClient((request) async {
          queries.add(request.url.queryParameters['query']!);
          return http.Response('{"release-groups": []}', 200);
        }),
        gap: const Duration(seconds: 1),
      ),
    );

    search.search('ok').ignore();
    await tester.pump(const Duration(milliseconds: 300));
    search.search('ok com').ignore();
    search.search('ok computer').ignore();
    await tester.pump(const Duration(seconds: 3));

    expect(queries, [
      MusicBrainzSearch.query('ok'),
      MusicBrainzSearch.query('ok computer'),
    ]);
  });
}
