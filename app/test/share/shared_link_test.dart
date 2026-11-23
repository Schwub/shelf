import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/share/shared_link.dart';

void main() {
  group('extractSharedUrl', () {
    test('finds the URL in Spotify share text', () {
      expect(
        extractSharedUrl(
          'Listen to Blue Lines on Spotify: '
          'https://open.spotify.com/album/1Xy7wIGW4Eh7mHzZ6p1PTU?si=abc',
        ),
        Uri.parse(
          'https://open.spotify.com/album/1Xy7wIGW4Eh7mHzZ6p1PTU?si=abc',
        ),
      );
    });

    test('accepts a bare Bandcamp URL', () {
      expect(
        extractSharedUrl('https://artist.bandcamp.com/album/some-album'),
        Uri.parse('https://artist.bandcamp.com/album/some-album'),
      );
    });

    test('returns null when there is no URL', () {
      expect(extractSharedUrl('just some text'), isNull);
    });

    test('ignores non-web schemes', () {
      expect(extractSharedUrl('spotify:album:1Xy7wIGW4Eh7mHzZ6p1PTU'), isNull);
    });

    test('takes the first of several URLs', () {
      expect(
        extractSharedUrl('https://a.example/one and https://b.example/two'),
        Uri.parse('https://a.example/one'),
      );
    });

    test('drops trailing punctuation', () {
      expect(
        extractSharedUrl('Check this out (https://a.example/album).'),
        Uri.parse('https://a.example/album'),
      );
    });
  });
}
