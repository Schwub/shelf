import 'dart:async';

import 'package:shelf_app/shelf/shelf_data.dart';

const own = ShelfFilter(tagId: 'own', label: 'Own');
const want = ShelfFilter(tagId: 'want', label: 'Want');

ShelfEntry entry(String id, String title, {int? rating, Set<String>? tags}) =>
    ShelfEntry(
      id: id,
      album: Album(id: 'a$id', title: title, artist: 'Artist $id', year: 1997),
      rating: rating,
      tagIds: tags ?? const {},
    );

/// An in-memory shelf; [failLoad] and [failSave] make the next call fail.
class FakeShelf implements ShelfRepository {
  FakeShelf(List<ShelfEntry> entries, {this.filters = const [own, want]})
    : entries = [...entries];

  final List<ShelfEntry> entries;
  final List<ShelfFilter> filters;
  final removed = <String>[];
  bool failLoad = false, failSave = false;
  int loads = 0;

  @override
  Future<Shelf> load() async {
    loads++;
    if (failLoad) {
      failLoad = false;
      throw Exception('offline');
    }
    return Shelf(entries: [...entries], filters: filters);
  }

  @override
  Future<void> save(String entryId, {int? rating, String? comment}) async {
    if (failSave) {
      failSave = false;
      throw Exception('offline');
    }
    final i = entries.indexWhere((e) => e.id == entryId);
    final e = entries[i];
    entries[i] = ShelfEntry(
      id: e.id,
      album: e.album,
      rating: rating,
      comment: comment == null || comment.isEmpty ? null : comment,
      tagIds: e.tagIds,
    );
  }

  @override
  Future<void> remove(String entryId) async {
    removed.add(entryId);
    entries.removeWhere((e) => e.id == entryId);
  }
}
