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
  Map<String, Destination> destinations = const {},
}) => TagImport(
  from: anna,
  theirs: Shelf(entries: const [], allGroups: theirs ?? annasGroups),
  tagIds: {for (final t in tags) 'their-$t'},
  mine: Shelf(entries: const [], allGroups: mine ?? suggestedGroups),
  destinations: destinations,
);

List<String> missingNames(TagImport p) => [
  for (final m in p.missing) m.tag.name,
];

void main() {
  test('built-in tags match by key, whatever they are called', () {
    final p = plan({'Have', 'Listened'});

    expect(p.preset, {'own', 'listened'});
    expect([for (final t in p.builtins) t.name], ['Own', 'Listened']);
    expect(p.missing, isEmpty);
  });

  test('other tags match by group and name, ignoring case', () {
    final p = plan({'jazz', 'Shoegaze'});

    expect(p.preset, {'jazz'});
    expect(missingNames(p), ['Shoegaze']);
    expect(p.missing.single.into?.id, 'genre');
  });

  test('a sub-group matches under the matching parent tag', () {
    final p = plan({'Have', 'vinyl', 'Shellac'});

    expect(p.preset, {'own', 'vinyl'});
    expect(missingNames(p), ['Shellac']);
    expect(p.missing.single.into?.id, 'format');
  });

  test('a missing group is offered as a new one with its tags', () {
    final p = plan({'Parlophone', 'Rainy day'});

    expect(missingNames(p), ['Parlophone', 'Rainy day']);
    expect([for (final m in p.missing) m.into], [null, null]);
    expect(p.missing.every((m) => m.ready), isTrue);
  });

  test('a sub-tag waits for its missing parent tag', () {
    final theirs = [
      ...annasGroups,
      TagGroup(
        id: 'a-pressing',
        name: 'Pressing',
        exclusive: true,
        parentTagId: 'their-Parlophone',
        tags: [theirTag('a-pressing', 'First')],
      ),
    ];
    final p = plan({'Parlophone', 'First'}, theirs: theirs);

    expect(missingNames(p), ['Parlophone', 'First']);
    expect(p.missing.last.ready, isFalse);
  });

  test("a sub-tag under a parent that isn't used is left out", () {
    final mine = [
      for (final g in suggestedGroups)
        g.id == 'listening' ? g.copyWith(hidden: true) : g,
      TagGroup(
        id: 'times',
        name: 'Times',
        exclusive: false,
        parentTagId: 'listened',
        tags: [tag('times', 'Twice')],
      ),
    ];
    final theirs = [
      ...annasGroups,
      TagGroup(
        id: 'a-times',
        name: 'Times',
        exclusive: false,
        parentTagId: 'their-Listened',
        tags: [theirTag('a-times', 'Twice')],
      ),
    ];
    final p = plan({'Listened', 'Twice'}, theirs: theirs, mine: mine);

    expect(p.preset, isEmpty);
    expect(p.missing, isEmpty);
  });

  test('groups hidden by either side are skipped', () {
    final mine = [
      for (final g in suggestedGroups)
        g.id == 'listening' ? g.copyWith(hidden: true) : g,
    ];
    final theirs = [
      for (final g in annasGroups)
        g.id == 'a-collection' ? g.copyWith(hidden: true) : g,
    ];
    final p = plan({'Have', 'vinyl', 'Listened'}, theirs: theirs, mine: mine);

    expect(p.preset, isEmpty);
    expect(p.missing, isEmpty);
  });

  test('a group of mine that allows one tag gets only the first', () {
    final mine = [
      ...suggestedGroups,
      TagGroup(
        id: 'label',
        name: 'Label',
        exclusive: true,
        tags: [tag('label', 'Warp')],
      ),
    ];
    final theirs = [
      for (final g in annasGroups)
        g.id == 'a-label'
            ? g.copyWith(tags: [...g.tags, theirTag('a-label', 'Warp')])
            : g,
    ];
    final p = plan({'Parlophone', 'Warp'}, theirs: theirs, mine: mine);

    expect(p.preset, isEmpty);
    expect(missingNames(p), ['Parlophone']);
  });

  test('a group can go into another group of mine', () {
    final p = plan(
      {'Parlophone'},
      destinations: {'a-label': const Destination.into('genre')},
    );

    expect(p.missing.single.into?.id, 'genre');
    final label = annasGroups.firstWhere((g) => g.id == 'a-label');
    expect(p.target(label).into?.id, 'genre');
  });

  test('a group that goes nowhere is neither set nor copyable', () {
    final p = plan(
      {'Parlophone', 'Have'},
      destinations: {'a-label': const Destination.nowhere()},
    );

    expect(p.missing, isEmpty);
    expect(p.copyable('their-Parlophone'), isFalse);
    expect(p.preset, {'own'}, reason: 'other groups as before');
  });

  test('every tag in the tree is marked, not only the album\'s', () {
    final p = plan({'Have'});

    expect(p.has('their-jazz'), isTrue, reason: 'my Genre has Jazz');
    expect(p.has('their-Shoegaze'), isFalse);
    expect(p.copyable('their-Shoegaze'), isTrue);
    expect(p.copyable('their-jazz'), isFalse);
  });

  group('copy', () {
    late FakeShelf shelf;
    setUp(() => shelf = FakeShelf([]));

    test('creates tags in my groups and new groups of their type', () async {
      final p = plan({'Shoegaze', 'Parlophone', 'Rainy day'});

      final after = await p.copy(shelf, {for (final m in p.missing) m.tag.id});

      expect(after.missing, isEmpty);
      expect(after.preset, {'shoegaze', 'parlophone', 'rainy day'});
      final label = shelf.groups.firstWhere((g) => g.name == 'Label');
      expect(label.exclusive, isFalse);
      expect(label.pickFromList, isTrue);
      expect(shelf.groups.firstWhere((g) => g.name == 'Mood').exclusive, true);
    });

    test('copies tags that are not on the album too', () async {
      final p = plan({'Have'});

      final after = await p.copy(shelf, {'their-Shoegaze', 'their-Rainy day'});

      expect(after.has('their-Shoegaze'), isTrue);
      expect(after.has('their-Rainy day'), isTrue);
      expect(after.preset, {'own'}, reason: 'only the album\'s tags go on it');
    });

    test('copies into the chosen group', () async {
      final p = plan(
        {'Parlophone'},
        destinations: {'a-label': const Destination.into('genre')},
      );

      final after = await p.copy(shelf, {'their-Parlophone'});

      expect(after.preset, {'parlophone'});
      expect(
        shelf.groups.firstWhere((g) => g.id == 'genre').tags.map((t) => t.name),
        contains('Parlophone'),
      );
      expect(shelf.groups.any((g) => g.name == 'Label'), isFalse);
    });

    test('copies only the picked tags', () async {
      final p = plan({'Shoegaze', 'Rainy day'});

      final after = await p.copy(shelf, {'their-Shoegaze'});

      expect(after.preset, {'shoegaze'});
      expect(missingNames(after), ['Rainy day']);
      expect(shelf.groups.any((g) => g.name == 'Mood'), isFalse);
    });

    test('copies a parent tag before its sub-group', () async {
      final theirs = [
        ...annasGroups,
        TagGroup(
          id: 'a-pressing',
          name: 'Pressing',
          exclusive: true,
          parentTagId: 'their-Parlophone',
          tags: [theirTag('a-pressing', 'First')],
        ),
      ];
      final p = plan({'Parlophone', 'First'}, theirs: theirs);

      final after = await p.copy(shelf, {'their-Parlophone', 'their-First'});

      expect(after.preset, {'parlophone', 'first'});
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Pressing').parentTagId,
        'parlophone',
      );
    });

    test('trying again after a failure copies only what is missing', () async {
      final p = plan({'Shoegaze', 'Rainy day'});
      final picked = {for (final m in p.missing) m.tag.id};
      shelf.failEdit = true; // The new group fails; Shoegaze is copied.

      await expectLater(p.copy(shelf, picked), throwsException);
      final after = await p.copy(shelf, picked);

      expect(after.preset, {'shoegaze', 'rainy day'});
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
