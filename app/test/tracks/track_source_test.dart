import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf_app/shelf/shelf_data.dart';
import 'package:shelf_app/tracks/track_source.dart';

Map<String, dynamic> release(String id, String date, List<int> discs) => {
  'id': id,
  'date': date,
  'media': [
    for (final n in discs) {'track-count': n},
  ],
};

http.Response json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  group('pickRelease', () {
    test('takes the earliest release with the most common track counts', () {
      // OK Computer's releases (recorded shape, trimmed): the 1997 CDs, a
      // 3-disc box set and a deluxe edition with a bonus disc.
      expect(
        MusicBrainzTracks.pickRelease([
          release('deluxe', '1997-05-21', [12, 3]),
          release('jp', '1997-05-21', [12]),
          release('box', '2009-03-24', [12, 14, 3]),
          release('uk', '1997-06-16', [12]),
          release('undated', '', [12]),
        ]),
        'jp',
      );
    });

    test('is null without releases or media', () {
      expect(MusicBrainzTracks.pickRelease([]), isNull);
      expect(MusicBrainzTracks.pickRelease([release('x', '2001', [])]), isNull);
    });
  });

  test('reads the chosen release\'s tracks, disc by disc', () async {
    final urls = <Uri>[];
    final client = MockClient((request) async {
      urls.add(request.url);
      if (request.url.path == '/ws/2/release') {
        return json({
          'releases': [
            release('r1', '2000-10-02', [5, 5]),
          ],
        });
      }
      return json({
        'media': [
          {
            'position': 1,
            'tracks': [
              {
                'position': 1,
                'title': 'Everything in Its Right Place',
                'length': 251000,
              },
            ],
          },
          {
            'position': 2,
            'tracks': [
              {'position': 1, 'title': 'Kid A', 'length': null},
            ],
          },
        ],
      });
    });

    final tracks = await MusicBrainzTracks(
      client,
      retryAfter: Duration.zero,
    ).trackList('rg');

    expect(urls.first.queryParameters, containsPair('release-group', 'rg'));
    expect(urls.first.queryParameters, containsPair('status', 'official'));
    expect(urls.last.path, '/ws/2/release/r1');
    expect(tracks, const [
      Track(
        title: 'Everything in Its Right Place',
        position: 1,
        lengthMs: 251000,
      ),
      Track(title: 'Kid A', disc: 2, position: 1),
    ]);
  });

  test('retries once when MusicBrainz is busy, then fails', () async {
    var calls = 0;
    final busy = MockClient((_) async {
      calls++;
      return json({}, 503);
    });
    await expectLater(
      MusicBrainzTracks(busy, retryAfter: Duration.zero).trackList('rg'),
      throwsA(isA<http.ClientException>()),
    );
    expect(calls, 2);
  });

  test('no official release means no track list', () async {
    final client = MockClient((_) async => json({'releases': []}));
    expect(
      await MusicBrainzTracks(
        client,
        retryAfter: Duration.zero,
      ).trackList('rg'),
      isEmpty,
    );
  });
}
