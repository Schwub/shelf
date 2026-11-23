import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shelf_app/share/share_receiver.dart';

void main() {
  test('emits the link that opened the app, then links shared later', () {
    ReceiveSharingIntent.setMockValues(
      initialMedia: [
        SharedMediaFile(
          path: 'Listen on Spotify: https://open.spotify.com/album/abc',
          type: SharedMediaType.text,
        ),
      ],
      mediaStream: Stream.value([
        SharedMediaFile(path: '/tmp/cover.jpg', type: SharedMediaType.image),
        SharedMediaFile(
          path: 'https://artist.bandcamp.com/album/x',
          type: SharedMediaType.url,
        ),
      ]),
    );

    expect(
      sharedLinks(),
      emitsInOrder([
        Uri.parse('https://open.spotify.com/album/abc'),
        Uri.parse('https://artist.bandcamp.com/album/x'),
        emitsDone,
      ]),
    );
  });
}
