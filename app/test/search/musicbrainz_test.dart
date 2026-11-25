import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf_app/search/musicbrainz.dart';

final url = Uri.https('musicbrainz.org', '/ws/2/release-group');

void main() {
  test('a busy answer (503) is tried again', () async {
    var calls = 0;
    final mb = MusicBrainz(
      MockClient((_) async => http.Response('', ++calls < 3 ? 503 : 200)),
      gap: Duration.zero,
    );

    expect((await mb.get(url)).statusCode, 200);
    expect(calls, 3);
  });

  test('gives up after two retries', () async {
    var calls = 0;
    final mb = MusicBrainz(
      MockClient((_) async {
        calls++;
        return http.Response('', 503);
      }),
      gap: Duration.zero,
    );

    expect((await mb.get(url)).statusCode, 503);
    expect(calls, 3);
  });

  testWidgets('sends at most one request per gap', (tester) async {
    var sent = 0;
    final mb = MusicBrainz(
      MockClient((_) async {
        sent++;
        return http.Response('', 200);
      }),
      gap: const Duration(seconds: 1),
    );

    for (var i = 0; i < 3; i++) {
      mb.get(url);
    }
    await tester.pump();
    expect(sent, 1);
    await tester.pump(const Duration(milliseconds: 999));
    expect(sent, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(sent, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(sent, 3);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a request no longer wanted is dropped before it is sent', (
    tester,
  ) async {
    var sent = 0;
    final mb = MusicBrainz(
      MockClient((_) async {
        sent++;
        return http.Response('', 200);
      }),
      gap: const Duration(seconds: 1),
    );
    var wanted = true;
    Object? error;

    mb.get(url);
    mb.get(url, wanted: () => wanted).catchError((Object e) {
      error = e;
      return http.Response('', 200);
    });
    wanted = false;
    await tester.pump(const Duration(seconds: 2));

    expect(sent, 1);
    expect(error, isA<Superseded>());
    await tester.pump(const Duration(seconds: 1));
  });

  test('asks with the contact MusicBrainz wants', () async {
    late http.Request request;
    await MusicBrainz(
      MockClient((r) async {
        request = r;
        return http.Response('', 200);
      }),
      contact: 'someone@example.com',
      gap: Duration.zero,
    ).get(url);

    expect(request.headers['User-Agent'], 'shelf/1.0 ( someone@example.com )');
  });
}
