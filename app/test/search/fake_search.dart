import 'package:shelf_app/search/album_search.dart';

SearchResult result(String id, String title) => SearchResult(
  musicbrainzId: id,
  title: title,
  artist: 'Radiohead',
  year: 1997,
);

/// Answers from [results] by query; [fail] makes the next search fail.
class FakeSearch implements AlbumSearch {
  FakeSearch(this.results);

  final Map<String, List<SearchResult>> results;
  final queries = <String>[];
  bool fail = false;

  @override
  Future<List<SearchResult>> search(String query) async {
    queries.add(query);
    if (fail) {
      fail = false;
      throw Exception('offline');
    }
    return results[query] ?? [];
  }
}
