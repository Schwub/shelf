import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/share/link_resolver.dart';

void main() {
  test('reads what the resolve-link function answers', () {
    final found = Resolved.fromJson({
      'kind': 'album',
      'musicbrainz_id': 'b1392450-e666-3926-a536-22c65f834433',
      'title': 'OK Computer',
      'artist': 'Radiohead',
      'year': 1997,
    });
    expect(
      (found as FoundAlbum).album.coverUrl,
      'https://coverartarchive.org/release-group/'
      'b1392450-e666-3926-a536-22c65f834433/front-500',
    );

    final unknown = Resolved.fromJson({
      'kind': 'unknown',
      'title': 'halftone paradise',
      'artist': 'Ewan Moore',
      'year': null,
      'cover_url': 'https://f4.bcbits.com/img/a4247304255_5.jpg',
    });
    expect(
      (unknown as UnknownAlbum).coverUrl,
      'https://f4.bcbits.com/img/a4247304255_5.jpg',
    );
    expect(unknown.year, isNull);

    final track = Resolved.fromJson({'kind': 'not_album', 'what': 'track'});
    expect((track as NotAnAlbum).what, 'track');
  });
}
