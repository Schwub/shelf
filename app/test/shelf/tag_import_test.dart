import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/shelf/tag_import.dart';

import 'fake_shelf.dart';

/// A friend's tag, with IDs of its own so nothing matches by ID.
Tag theirTag(String group, String name, {String? builtin}) =>
    Tag(id: 'their-$name', groupId: group, name: name, builtin: builtin);

/// Anna's groups: Collection renamed to "Records", Own renamed to "Have",
/// Format under it; Genre in other case; Label (several per album, picked
/// from a list) and Mood the user doesn't have.
final annasGroups = [
  TagGroup(
    id: 'a-collection',
    name: 'Records',
    exclusive: true,
    builtin: 'collection',
    tags: [
      theirTag('a-collection', 'Want', builtin: 'want'),
      theirTag('a-collection', 'Have', builtin: 'own'),
    ],
  ),
  TagGroup(
    id: 'a-format',
    name: 'format',
    exclusive: false,
    parentTagId: 'their-Have',
    tags: [theirTag('a-format', 'vinyl'), theirTag('a-format', 'Shellac')],
  ),
  TagGroup(
    id: 'a-listening',
    name: 'Listening',
    exclusive: true,
    builtin: 'listening',
    tags: [theirTag('a-listening', 'Listened', builtin: 'listened')],
  ),
  TagGroup(
    id: 'a-genre',
    name: 'GENRE',
    exclusive: false,
    pickFromList: true,
    tags: [theirTag('a-genre', 'jazz'), theirTag('a-genre', 'Shoegaze')],
  ),
  TagGroup(
    id: 'a-label',
    name: 'Label',
    exclusive: false,
    pickFromList: true,
    tags: [theirTag('a-label', 'Parlophone')],
  ),
  TagGroup(
    id: 'a-mood',
    name: 'Mood',
    exclusive: true,
    tags: [theirTag('a-mood', 'Rainy day')],
  ),
];

const anna = (userId: 'anna', name: 'Anna');

TagImport plan(
  Set<String> tags, {
  List<TagGroup>? theirs,
  List<TagGroup>? mine,
  Map<String, String> destinations = const {},
}) => TagImport(
  from: anna,
  theirs: Shelf(entries: const [], allGroups: theirs ?? annasGroups),
  tagIds: {for (final t in tags) 'their-$t'},
  mine: Shelf(entries: const [], allGroups: mine ?? suggestedGroups),
  destinations: destinations,
);

/// Where the suggestions put each row: "group/tag", "group/+" for a new tag
/// there, "+" for a new group.
List<String> targets(TagImport p) => [
  for (final t in p.rows)
    switch (p.suggest(t)) {
      TagTarget(:final tag?, :final group?) => '${group.id}/${tag.id}',
      TagTarget(:final group?) => '${group.id}/+',
      _ => '+',
    },
];

final pressing = TagGroup(
  id: 'a-pressing',
  name: 'Pressing',
  exclusive: true,
  parentTagId: 'their-Parlophone',
  tags: [theirTag('a-pressing', 'First')],
);

void main() {
  test("only the album's tags are rows, parents before sub-tags", () {
    final p = plan({'vinyl', 'Have', 'Rainy day', 'jazz'});

    expect(
      [for (final t in p.rows) t.name],
      ['Have', 'jazz', 'Rainy day', 'vinyl'],
    );
  });

  test("the friend's hidden groups are left out", () {
    final theirs = [
      for (final g in annasGroups)
        g.id == 'a-mood' ? g.copyWith(hidden: true) : g,
    ];
    expect(
      plan({'jazz', 'Rainy day'}, theirs: theirs).rows.map((t) => t.name),
      ['jazz'],
    );
  });

  test('built-in tags match by key, whatever they are called', () {
    expect(targets(plan({'Have', 'Listened'})), [
      'collection/own',
      'listening/listened',
    ]);
  });

  test('other tags match by group and name, ignoring case', () {
    expect(targets(plan({'jazz', 'Shoegaze'})), ['genre/jazz', 'genre/+']);
  });

  test('a sub-group matches under the matching parent tag', () {
    expect(targets(plan({'Have', 'vinyl', 'Shellac'})), [
      'collection/own',
      'format/vinyl',
      'format/+',
    ]);
  });

  test("a group I don't have is suggested as a new one", () {
    expect(targets(plan({'Parlophone', 'Rainy day'})), ['+', '+']);
  });

  test('a group goes where it went before', () {
    final p = plan({'Parlophone'}, destinations: {'a-label': 'genre'});

    expect(targets(p), ['genre/+']);
    expect(targets(plan({'Parlophone'}).withDestination('a-label', 'genre')), [
      'genre/+',
    ]);
  });

  test('a remembered group that is gone is ignored', () {
    expect(targets(plan({'jazz'}, destinations: {'a-genre': 'gone'})), [
      'genre/jazz',
    ]);
  });

  test('tags in a built-in group I hide are left out, with their sub-tags', () {
    final mine = [
      for (final g in suggestedGroups)
        g.id == 'collection' ? g.copyWith(hidden: true) : g,
    ];
    final p = plan({'Have', 'vinyl', 'jazz'}, mine: mine);

    expect([for (final t in p.rows) t.name], ['jazz']);
  });

  test("a sub-tag whose parent tag isn't on the album is left out", () {
    expect(plan({'vinyl', 'jazz'}).rows.map((t) => t.name), ['jazz']);
  });

  test('nothing is suggested into a group I hide', () {
    final mine = [
      for (final g in suggestedGroups)
        g.id == 'genre' ? g.copyWith(hidden: true) : g,
    ];
    expect(targets(plan({'jazz'}, mine: mine)), ['+']);
  });

  test("a sub-tag follows the target picked for its parent", () {
    final p = plan({'Have', 'vinyl'});
    final collection = suggestedGroups.first;
    final want = collection.tags.first;

    expect(
      p.suggest(p.rows.last, {
        'their-Have': TagTarget(group: collection, tag: want),
      }),
      const TagTarget(),
      reason: 'no Format under Want: a new group',
    );
  });

  group('apply', () {
    late FakeShelf shelf;
    setUp(() => shelf = FakeShelf([]));

    test('sets matches and creates only the ticked new tags', () async {
      final p = plan({'jazz', 'Shoegaze', 'Parlophone', 'Rainy day'});
      final rows = {for (final t in p.rows) t.name: t};

      final after = await p.apply(shelf, {
        for (final name in ['jazz', 'Shoegaze', 'Parlophone'])
          rows[name]!.id: p.suggest(rows[name]!),
      });

      expect(after.tagIds, {'jazz', 'shoegaze', 'parlophone'});
      final label = shelf.groups.firstWhere((g) => g.name == 'Label');
      expect(label.exclusive, isFalse);
      expect(label.pickFromList, isTrue);
      expect(shelf.groups.any((g) => g.name == 'Mood'), isFalse);
      expect(
        after.mine.allGroups.any((g) => g.name == 'Label'),
        isTrue,
        reason: 'the shelf after',
      );
    });

    test('puts a tag into any tag or group of mine', () async {
      final p = plan({'Parlophone', 'Rainy day'});
      final genre = suggestedGroups.firstWhere((g) => g.id == 'genre');

      final after = await p.apply(shelf, {
        'their-Parlophone': TagTarget(group: genre),
        'their-Rainy day': TagTarget(group: genre, tag: genre.tags.first),
      });

      expect(after.tagIds, {'parlophone', genre.tags.first.id});
      expect(
        shelf.groups.firstWhere((g) => g.id == 'genre').tags.map((t) => t.name),
        contains('Parlophone'),
      );
      expect(shelf.groups.any((g) => g.name == 'Label'), isFalse);
    });

    test('a sub-tag goes under its parent and brings it along', () async {
      final p = plan(
        {'Parlophone', 'First'},
        theirs: [...annasGroups, pressing],
      );

      final after = await p.apply(shelf, {
        for (final t in p.rows) t.id: p.suggest(t),
      });

      expect(after.tagIds, {'parlophone', 'first'});
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Pressing').parentTagId,
        'parlophone',
      );
    });

    test("a sub-tag of mine brings my parent tag", () async {
      final p = plan({'Have', 'vinyl'});
      final format = suggestedGroups.firstWhere((g) => g.id == 'format');

      final after = await p.apply(shelf, {
        'their-vinyl': TagTarget(group: format, tag: format.tags.first),
      });

      expect(after.tagIds, {'vinyl', 'own'});
    });

    test('trying again after a failure creates nothing twice', () async {
      final p = plan({'Shoegaze', 'Rainy day'});
      final ticked = {for (final t in p.rows) t.id: p.suggest(t)};
      shelf.failEdit = true; // The new group fails; Shoegaze is created.

      await expectLater(p.apply(shelf, ticked), throwsException);
      final after = await p.apply(shelf, ticked);

      expect(after.tagIds, {'shoegaze', 'rainy day'});
      expect(
        shelf.groups
            .firstWhere((g) => g.id == 'genre')
            .tags
            .where((t) => t.name == 'Shoegaze'),
        hasLength(1),
      );
    });
  });
}
