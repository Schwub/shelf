import 'package:flutter/foundation.dart';

import '../shelf/shelf.dart';

enum FeedKind { added, rated }

/// One thing a friend did: added an album (with its rating, if they gave
/// one then) or rated one later.
@immutable
class FeedItem {
  const FeedItem({
    required this.kind,
    required this.at,
    required this.cursor,
    required this.entryId,
    required this.friendId,
    required this.friendName,
    required this.album,
    this.rating,
  });

  final FeedKind kind;
  final DateTime at;

  /// [at] exactly as the database has it, to page by: Dart on the web
  /// keeps only milliseconds.
  final String cursor;
  final String entryId, friendId, friendName;
  final Album album;
  final int? rating;
}

/// Friends' activity, newest first (docs/features/friends.md). An
/// interface so the Feed can be tested without a server.
abstract class FeedRepository {
  static const pageSize = 30;

  /// Up to [pageSize] items, the newest ones or those after [after].
  Future<List<FeedItem>> page({FeedItem? after});
}
