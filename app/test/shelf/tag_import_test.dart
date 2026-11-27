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
  Map<String, CopyTarget> remembered = const {},
  Set<String> taken = const {},
}) => TagImport(
  from: anna,
  theirs: Shelf(entries: const [], allGroups: theirs ?? annasGroups),
  tagIds: {for (final t in tags) 'their-$t'},
  mine: Shelf(entries: const [], allGroups: mine ?? suggestedGroups),
  memory: (targets: remembered, taken: taken),
);

/// Where the friend's tag [name] goes: "tag-id" when the user has it,
/// "+path" when it is new.
String place(
  TagImport p,
  String name, [
  Map<String, CopyTarget> picked = const {},
]) {
  final t = p.tagPlace(p.theirTag('their-$name'), picked);
  return t.existing?.id ?? '+${t.path}';
}

final pressing = TagGroup(
  id: 'a-pressing',
  name: 'Pressing',
  exclusive: true,
  parentTagId: 'their-Parlophone',
  tags: [theirTag('a-pressing', 'First')],
);

void main() {
  test("rows are the friend's tree down to the album's tags", () {
    final p = plan({'vinyl', 'jazz'});

    expect(
      [
        for (final r in p.rows)
          '${'  ' * r.depth}${r.group?.name ?? r.tag!.name}',
      ],
      ['Records', '  Have', '    format', '      vinyl', 'GENRE', '  jazz'],
    );
  });

  test('a built-in group I hide is left out, with what is under it', () {
    final mine = [
      for (final g in suggestedGroups)
        g.id == 'collection' ? g.copyWith(hidden: true) : g,
    ];
    expect(
      plan({'Have', 'vinyl', 'jazz'}, mine: mine).tags.map((t) => t.name),
      ['jazz'],
    );
  });

  test('Copy reuses what I have along the same path', () {
    final p = plan({'Have', 'vinyl', 'Shellac', 'Shoegaze'});

    expect(place(p, 'Have'), 'own', reason: 'built-in by key');
    expect(place(p, 'vinyl'), 'vinyl');
    expect(place(p, 'Shellac'), '+Own › Format › Shellac');
    expect(place(p, 'Shoegaze'), '+Genre › Shoegaze');
  });

  test("a group I don't have becomes a new group, sub-groups under it", () {
    final p = plan({'First'}, theirs: [...annasGroups, pressing]);

    expect(place(p, 'First'), '+Parlophone › Pressing › First');
    expect(p.creates({'their-First'}, {}), [
      'group Label',
      'tag Parlophone in Label',
      'sub-group Pressing under Parlophone',
      'tag First in Pressing',
    ]);
    expect(p.along({'their-First'}, {}), {'their-Parlophone'});
  });

  test(
    'a new tag goes onto my tag of the same name elsewhere, unless Copy',
    () {
      final theirs = [
        ...annasGroups,
        TagGroup(
          id: 'a-style',
          name: 'Style',
          exclusive: false,
          tags: [theirTag('a-style', 'Jazz')],
        ),
      ];
      final p = plan({'Jazz'}, theirs: theirs);

      expect(place(p, 'Jazz'), 'jazz');
      expect(
        place(p, 'Jazz', {'their-Jazz': const CopyAsIs()}),
        '+Style › Jazz',
      );
    },
  );

  test('a group goes where it was remembered or picked', () {
    final p = plan(
      {'Parlophone'},
      remembered: {'a-label': const IntoGroup('genre')},
    );

    expect(place(p, 'Parlophone'), '+Genre › Parlophone');
    expect(
      place(p, 'Parlophone', {'a-label': const UnderTag('vinyl')}),
      '+Own › Vinyl › Label › Parlophone',
    );
  });

  test('a tag can go onto any of my tags, and then goes alone', () {
    final p = plan({'Have', 'vinyl'});
    final picked = {'their-vinyl': const OntoTag('cd')};

    expect(place(p, 'vinyl', picked), 'cd');
    expect(p.along({'their-vinyl'}, {}), {'their-Have'});
    expect(p.along({'their-vinyl'}, picked), isEmpty);
  });

  test('a remembered target that is gone is ignored', () {
    expect(
      place(
        plan({'jazz'}, remembered: {'a-genre': const IntoGroup('gone')}),
        'jazz',
      ),
      'jazz',
    );
  });

  test("a group named like one of my built-in groups goes into it", () {
    final theirs = [
      TagGroup(
        id: 'a-coll',
        name: 'collection',
        exclusive: false,
        tags: [theirTag('a-coll', 'Boxed')],
      ),
    ];
    expect(
      place(plan({'Boxed'}, theirs: theirs), 'Boxed'),
      '+Collection › Boxed',
    );
  });

  test('a tag follows a target picked above it, not a same-name tag', () {
    final p = plan({'Have', 'vinyl'});

    expect(
      place(p, 'vinyl', {'their-Have': const OntoTag('want')}),
      '+Want › format › vinyl',
    );
  });

  group('apply', () {
    late FakeShelf shelf;
    setUp(() => shelf = FakeShelf([]));

    test('creates what is new and sets the tags with their parents', () async {
      final p = plan(
        {'Shellac', 'First', 'jazz'},
        theirs: [...annasGroups, pressing],
      );

      final after = await p.apply(shelf, {'their-Shellac', 'their-First'}, {});

      expect(after.tagIds, {'shellac', 'own', 'first', 'parlophone'});
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Pressing').parentTagId,
        'parlophone',
      );
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Label').pickFromList,
        isTrue,
      );
      expect(after.mine.allGroups.any((g) => g.name == 'Label'), isTrue);
    });

    test('puts a tag where it was picked', () async {
      final p = plan({'Rainy day', 'Parlophone'});

      final after = await p.apply(
        shelf,
        {'their-Rainy day', 'their-Parlophone'},
        {
          'their-Rainy day': const OntoTag('jazz'),
          'a-label': const UnderTag('vinyl'),
        },
      );

      expect(after.tagIds, {'jazz', 'parlophone', 'vinyl', 'own'});
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Label').parentTagId,
        'vinyl',
      );
      expect(shelf.groups.any((g) => g.name == 'Mood'), isFalse);
    });

    test('trying again after a failure creates nothing twice', () async {
      final p = plan({'Shoegaze', 'Rainy day'});
      final ticked = {'their-Shoegaze', 'their-Rainy day'};
      shelf.failEdit = true; // The new group fails; Shoegaze is created.

      await expectLater(p.apply(shelf, ticked, {}), throwsException);
      final after = await p.apply(shelf, ticked, {});

      expect(after.tagIds, {'shoegaze', 'rainy day'});
      expect(
        shelf.groups
            .firstWhere((g) => g.id == 'genre')
            .tags
            .where((t) => t.name == 'Shoegaze'),
        hasLength(1),
      );
    });

    test('remembers picked groups and the ticked tags', () async {
      final p = plan({'jazz', 'Parlophone'});

      await p.remember(
        shelf,
        {'their-jazz'},
        {
          'a-label': const IntoGroup('genre'),
          'their-jazz': const OntoTag('pop'),
        },
      );

      expect(shelf.copyTargets, {
        'a-label': const IntoGroup('genre'),
        'their-jazz': const OntoTag('pop'),
      });
      expect(shelf.taken, {'their-jazz'});
    });

    test(
      'remembers the tags that came along, and Copy forgets a group',
      () async {
        final p = plan({'vinyl'});
        shelf.copyTargets['a-format'] = const IntoGroup('genre');

        await p.remember(
          shelf,
          {'their-vinyl'},
          {'a-format': const CopyAsIs()},
        );

        expect(shelf.taken, {'their-vinyl', 'their-Have'});
        expect(shelf.copyTargets, isEmpty);
      },
    );
  });
}
