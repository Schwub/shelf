import 'package:shelf_app/feed/feed_repository.dart';

/// Feed items kept in memory, newest first, paged like the real one;
/// [error] makes the next call fail.
class FakeFeed implements FeedRepository {
  FakeFeed([List<FeedItem> items = const []]) : items = [...items];

  final List<FeedItem> items;
  Object? error;
  int pages = 0;

  /// Holds the next pages back until it completes.
  Future<void>? wait;

  @override
  Future<List<FeedItem>> page({FeedItem? after}) async {
    pages++;
    if (wait case final w?) await w;
    final e = error;
    error = null;
    if (e != null) throw e;
    final start = after == null ? 0 : items.indexOf(after) + 1;
    return items.skip(start).take(FeedRepository.pageSize).toList();
  }
}
