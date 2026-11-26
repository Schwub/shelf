import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/shelf/bulk_tags.dart';

import 'fake_shelf.dart';

void main() {
  // Kid A: Own, Vinyl, Listened. Blue: Own, CD. Promises: Want, Want to
  // listen.
  final selected = [
    entry('1', 'Kid A', tags: {'own', 'vinyl', 'listened'}),
    entry('2', 'Blue', tags: {'own', 'cd'}),
    entry('3', 'Promises', tags: {'want', 'want to listen'}),
  ];
  BulkTags bulk() => BulkTags(suggestedGroups, selected);

  test('all, some or none of the albums have a tag', () {
    final b = bulk();
    expect(b.state('own'), TagState.some);
    expect(b.count('own'), 2);
    expect(b.state('tape'), TagState.none);
    expect(
      BulkTags(suggestedGroups, selected.take(2).toList()).state('own'),
      TagState.all,
    );
    expect(b.changed, isFalse);
  });

  test(
    'a tag goes on all, and replaces the others of a one-per-album group',
    () {
      final b = bulk().toggle('listened');

      expect(b.state('listened'), TagState.all);
      expect(b.state('want to listen'), TagState.none);
      expect(b.changes.add, ['listened']);
      expect(b.changes.remove, {'want to listen'});
    },
  );

  test('a sub-tag puts its parent on, and the parent replaces Want', () {
    final b = bulk().toggle('tape');

    expect(b.state('own'), TagState.all);
    expect(b.state('want'), TagState.none);
    expect(b.changes.add, ['own', 'tape'], reason: 'parents first');
    expect(b.changes.remove, {'want'});
  });

  test('a tag on all comes off all, with its sub-tags', () {
    final b = BulkTags(
      suggestedGroups,
      selected.take(2).toList(),
    ).toggle('own');

    expect(b.state('own'), TagState.none);
    expect(b.state('vinyl'), TagState.none);
    expect(b.changes.remove, {'own', 'vinyl', 'cd'});
    expect(b.changes.add, isEmpty);
  });

  test('tapped twice, a tag the albums partly had comes off all', () {
    final b = bulk().toggle('own').toggle('own');

    expect(b.state('own'), TagState.none);
    expect(b.changes.remove, containsAll(['own', 'vinyl', 'cd']));
    expect(b.changes.add, isEmpty);
  });

  test('a tag no album had, on and off again, changes nothing', () {
    final b = bulk().toggle('tape').toggle('tape');

    expect(b.state('tape'), TagState.none);
    expect(b.changes.add, ['own'], reason: 'Own stays put on');
    expect(b.changes.remove, {'want'});
  });
}
