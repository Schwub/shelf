import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/shelf/shelf.dart';

import 'fake_shelf.dart';

ShelfEntry album(
  String id,
  String title,
  String artist, {
  int? year,
  int? rating,
}) => ShelfEntry(
  id: id,
  addedAt: added,
  album: Album(id: id, title: title, artist: artist, year: year),
  rating: rating,
);

/// Newest first, as loaded.
final shelf = [
  album('1', 'blue', 'Joni Mitchell', year: 1971, rating: 10),
  album('2', 'Kid A', 'Radiohead', year: 2000),
  album('3', 'Amnesiac', 'Radiohead', year: 2001, rating: 8),
  album('4', 'Demo', 'anna', rating: 8),
  album('5', 'OK Computer', 'Radiohead', year: 1997, rating: 9),
];

List<String> ids(ShelfSort sort) => [for (final e in sort.apply(shelf)) e.id];

void main() {
  test('date added: newest first, or oldest', () {
    expect(ids(ShelfSort.newest), ['1', '2', '3', '4', '5']);
    expect(ids(const ShelfSort(SortBy.added, reversed: true)), [
      '5',
      '4',
      '3',
      '2',
      '1',
    ]);
  });

  test('title: A–Z ignoring case, or Z–A', () {
    expect(ids(const ShelfSort(SortBy.title)), ['3', '1', '4', '2', '5']);
    expect(ids(const ShelfSort(SortBy.title, reversed: true)), [
      '5',
      '2',
      '4',
      '1',
      '3',
    ]);
  });

  test("artist: A–Z, an artist's albums from the first on", () {
    expect(ids(const ShelfSort(SortBy.artist)), ['4', '1', '5', '2', '3']);
    expect(ids(const ShelfSort(SortBy.artist, reversed: true)), [
      '5',
      '2',
      '3',
      '1',
      '4',
    ]);
  });

  test('year: newest first, or oldest; none last either way', () {
    expect(ids(const ShelfSort(SortBy.year)), ['3', '2', '5', '1', '4']);
    expect(ids(const ShelfSort(SortBy.year, reversed: true)), [
      '1',
      '5',
      '2',
      '3',
      '4',
    ]);
  });

  test('rating: highest first, or lowest; unrated last; ties newest first', () {
    expect(ids(const ShelfSort(SortBy.rating)), ['1', '5', '3', '4', '2']);
    expect(ids(const ShelfSort(SortBy.rating, reversed: true)), [
      '3',
      '4',
      '5',
      '1',
      '2',
    ]);
  });

  test('saved as a key and read back; unknown keys are newest first', () {
    for (final by in SortBy.values) {
      for (final reversed in [false, true]) {
        final sort = ShelfSort(by, reversed: reversed);
        expect(ShelfSort.parse(sort.key), sort);
      }
    }
    expect(ShelfSort.parse(null), ShelfSort.newest);
    expect(ShelfSort.parse('colour'), ShelfSort.newest);
  });
}
