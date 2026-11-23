final _url = RegExp(r'https?://\S+');
final _trailingPunctuation = RegExp(r'''[.,;:!?)\]}'"]+$''');

/// The first web URL in text shared from another app, or null.
///
/// Apps share either a bare URL or a sentence ending in one
/// ("Listen to … on Spotify: https://open.spotify.com/album/…").
Uri? extractSharedUrl(String text) {
  final match = _url.firstMatch(text);
  if (match == null) return null;
  return Uri.tryParse(match[0]!.replaceFirst(_trailingPunctuation, ''));
}
