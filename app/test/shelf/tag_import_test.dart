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
  Map<String, CopyTarget> targets = const {},
}) => TagImport(
  from: anna,
  theirs: Shelf(entries: const [], allGroups: theirs ?? annasGroups),
  tagIds: {for (final t in tags) 'their-$t'},
  mine: Shelf(entries: const [], allGroups: mine ?? suggestedGroups),
  targets: targets,
);

Tag their(TagImport p, String name) =>
    p.theirs.allGroups.expand((g) => g.tags).firstWhere((t) => t.name == name);

/// Where the friend's tag [name] goes: my tag's ID when I have it, else
/// "+group/name" for a new tag ("+?/name" in a group that is new too).
String place(TagImport p, String name) {
  final t = p.tagPlace(their(p, name));
  return t.existing?.id ?? '+${t.group.existing?.id ?? '?'}/${t.name}';
}

final pressing = TagGroup(
  id: 'a-pressing',
  name: 'Pressing',
  exclusive: true,
  parentTagId: 'their-Parlophone',
  tags: [theirTag('a-pressing', 'First')],
);

final style = TagGroup(
  id: 'a-style',
  name: 'Style',
  exclusive: false,
  tags: [
    theirTag('a-style', 'Jazz'),
    theirTag('a-style', 'Pop'),
    theirTag('a-style', 'Dream pop'),
  ],
);

void main() {
  test("the album's tags are offered, sub-tags too, in the friend's order", () {
    final p = plan({'vinyl', 'jazz', 'Have'});

    expect([for (final t in p.tags) t.name], ['Have', 'vinyl', 'jazz']);
  });

  test("a tag's path is the friend's structure above it", () {
    final p = plan({'vinyl', 'jazz'});

    expect(p.pathOf(their(p, 'vinyl')), ['Records', 'Have', 'format']);
    expect(p.pathOf(their(p, 'jazz')), ['GENRE']);
  });

  test('a built-in group I hide is left out, with what is under it', () {
    final mine = [
      for (final g in suggestedGroups)
        g.id == 'collection' ? g.copyWith(hidden: true) : g,
    ];
    final p = plan({'Have', 'vinyl', 'jazz'}, mine: mine);

    expect([for (final t in p.tags) t.name], ['jazz']);
  });

  test('tags go onto mine of the same name in the same place', () {
    final p = plan({'Have', 'vinyl', 'Shellac', 'Shoegaze'});

    expect(place(p, 'Have'), 'own', reason: 'built-in by key');
    expect(place(p, 'vinyl'), 'vinyl');
    expect(place(p, 'Shellac'), '+format/Shellac');
    expect(place(p, 'Shoegaze'), '+genre/Shoegaze');
  });

  test('a tag of a group I lack goes onto my tag of that name elsewhere', () {
    final p = plan({'Jazz', 'Dream pop'}, theirs: [...annasGroups, style]);

    expect(place(p, 'Jazz'), 'jazz');
    expect(place(p, 'Dream pop'), '+?/Dream pop');
    expect(p.suggestion(style)?.id, 'genre', reason: 'has Jazz and Pop');
  });

  test('an answer for a group moves all its tags', () {
    final p = plan({'Jazz', 'Dream pop'}, theirs: [...annasGroups, style]);
    final q = p.withTarget('a-style', const IntoGroup('listening'));

    expect(place(q, 'Dream pop'), '+listening/Dream pop');
    expect(place(q, 'Jazz'), '+listening/Jazz', reason: 'follows');
  });

  test('a remembered answer is used, unless the group is gone', () {
    final theirs = [...annasGroups, style];

    expect(
      place(
        plan(
          {},
          theirs: theirs,
          targets: {'a-style': const IntoGroup('genre')},
        ),
        'Dream pop',
      ),
      '+genre/Dream pop',
    );
    expect(
      place(
        plan({}, theirs: theirs, targets: {'a-style': const IntoGroup('gone')}),
        'Dream pop',
      ),
      '+?/Dream pop',
    );
  });

  test('my path to a place, and my nearest tag above a tag I lack', () {
    final p = plan({'Shellac', 'First'}, theirs: [...annasGroups, pressing]);

    expect(p.tagPlace(their(p, 'vinyl')).path, [
      'Collection',
      'Own',
      'Format',
      'Vinyl',
    ]);
    expect(p.tagPlace(their(p, 'First')).path, [
      'Label',
      'Parlophone',
      'Pressing',
      'First',
    ]);
    expect(p.nearestAbove(their(p, 'Shellac'))?.existing?.id, 'own');
    expect(p.nearestAbove(their(p, 'First')), isNull, reason: 'no Parlophone');
    expect(p.nearestAbove(their(p, 'jazz')), isNull, reason: 'top-level');
    expect(p.suggestion(pressing), isNull);
  });

  test('tags I made since count as mine', () {
    final p = plan({'Shoegaze'});
    final now = [
      for (final g in p.mine.groups)
        g.id == 'genre' ? g.withTag(tag('genre', 'Shoegaze')) : g,
    ];

    expect(place(p, 'Shoegaze'), '+genre/Shoegaze');
    expect(place(p.withMyGroups(now), 'Shoegaze'), 'shoegaze');
  });

  group('mapping', () {
    /// Anna nests: Genre › Metal › Subgenre › Black metal, Doom.
    final nested = [
      TagGroup(
        id: 'a-genre',
        name: 'Genre',
        exclusive: false,
        tags: [theirTag('a-genre', 'Metal'), theirTag('a-genre', 'Jazz')],
      ),
      TagGroup(
        id: 'a-sub',
        name: 'Subgenre',
        exclusive: false,
        parentTagId: 'their-Metal',
        tags: [theirTag('a-sub', 'Black metal'), theirTag('a-sub', 'Doom')],
      ),
    ];

    test('the chain of a tag, and what is below a starting point', () {
      final p = plan({'Black metal'}, theirs: nested);
      final chain = p.chainOf(their(p, 'Black metal'));

      expect(
        [for (final s in chain) s.group?.name ?? s.tag?.name],
        ['Genre', 'Metal', 'Subgenre', 'Black metal'],
      );
      expect(
        [for (final t in p.below(chain[0])) t.name],
        ['Metal', 'Black metal', 'Doom', 'Jazz'],
      );
      expect(
        [for (final t in p.below(chain[1])) t.name],
        ['Black metal', 'Doom'],
      );
      expect(p.below(chain[3]), isEmpty);
    });

    test('nested to flat: her sub-group joins my group', () {
      final p = plan({
        'Black metal',
      }, theirs: nested).withTarget('a-sub', const IntoGroup('genre'));

      expect(place(p, 'Black metal'), '+genre/Black metal');
      expect(place(p, 'Doom'), '+genre/Doom');
    });

    test('nested to flat: her sub-tag becomes my tag', () {
      final p = plan({
        'Black metal',
      }, theirs: nested).withTarget('their-Black metal', const OntoTag('jazz'));

      expect(place(p, 'Black metal'), 'jazz');
    });

    test('flat to nested: her tag goes into my sub-group', () {
      final p = plan({'Shoegaze'})
          .withTarget('their-Shoegaze', const IntoGroup('format'));

      expect(p.tagPlace(their(p, 'Shoegaze')).path, [
        'Collection',
        'Own',
        'Format',
        'Shoegaze',
      ]);
    });

    test('her group hangs under one of my tags, or at the top', () {
      final under = plan({
        'Black metal',
      }, theirs: nested).withTarget('a-sub', const UnderTag('jazz'));
      final top = plan({
        'Black metal',
      }, theirs: nested).withTarget('a-sub', const AtTop());

      expect(under.tagPlace(their(under, 'Black metal')).path, [
        'Genre',
        'Jazz',
        'Subgenre',
        'Black metal',
      ]);
      expect(top.tagPlace(their(top, 'Black metal')).path, [
        'Subgenre',
        'Black metal',
      ]);
    });

    test('a mapped parent tag takes what is below it along', () {
      final p = plan({
        'Black metal',
      }, theirs: nested).withTarget('their-Metal', const OntoTag('pop'));

      expect(p.tagPlace(their(p, 'Black metal')).path, [
        'Genre',
        'Pop',
        'Subgenre',
        'Black metal',
      ]);
    });

    test('the parts of where a tag lands, and what each stands for', () {
      final p = plan({'Black metal'}, theirs: nested);
      String part(({String name, bool isNew, Start start}) x) =>
          '${x.isNew ? '+' : ''}${x.name}'
          '=${x.start.group?.name ?? x.start.tag?.name}';

      expect(p.toPath(their(p, 'Black metal')).map(part), [
        'Genre=Genre',
        '+Metal=Metal',
        '+Subgenre=Subgenre',
        '+Black metal=Black metal',
      ]);
      final q = p.withTarget('their-Black metal', const IntoGroup('format'));
      expect(q.toPath(their(q, 'Black metal')).map(part), [
        'Collection=Black metal',
        'Own=Black metal',
        'Format=Black metal',
        '+Black metal=Black metal',
      ], reason: 'my own parts on the way stand for the tag');
    });

    test('several tags are created in one go, sharing new parents', () async {
      final shelf = FakeShelf([]);
      final p = plan({'Black metal'}, theirs: nested);

      final after = await p.add(shelf, [
        their(p, 'Doom'),
        their(p, 'Black metal'),
      ]);

      expect(after.tagIds, ['metal', 'black metal']);
      expect(shelf.groups.where((g) => g.name == 'Subgenre'), hasLength(1));
      expect(
        shelf.groups
            .firstWhere((g) => g.name == 'Subgenre')
            .tags
            .map((t) => t.name),
        ['Doom', 'Black metal'],
      );
    });
  });

  group('add', () {
    late FakeShelf shelf;
    setUp(() => shelf = FakeShelf([]));

    test('sets my tag with its parents, creating nothing', () async {
      final p = plan({'vinyl'});

      final after = await p.add(shelf, [their(p, 'vinyl')]);

      expect(after.tagIds, ['own', 'vinyl']);
      expect(shelf.groups, hasLength(suggestedGroups.length));
    });

    test('creates a tag in the answered group', () async {
      final p = plan(
        {'Rainy day'},
        targets: {'a-mood': const IntoGroup('genre')},
      );

      final after = await p.add(shelf, [their(p, 'Rainy day')]);

      expect(after.tagIds, ['rainy day']);
      expect(
        after.mine.allGroups.firstWhere((g) => g.id == 'genre').tags.last.name,
        'Rainy day',
      );
      expect(shelf.groups.any((g) => g.name == 'Mood'), isFalse);
    });

    test("creates the friend's structure down to a sub-tag", () async {
      final p = plan({'First'}, theirs: [...annasGroups, pressing]);

      final after = await p.add(shelf, [their(p, 'First')]);

      expect(after.tagIds, ['parlophone', 'first']);
      final label = shelf.groups.firstWhere((g) => g.name == 'Label');
      expect(label.pickFromList, isTrue);
      expect(
        shelf.groups.firstWhere((g) => g.name == 'Pressing').parentTagId,
        'parlophone',
      );
    });

    test('trying again after a failure creates nothing twice', () async {
      final p = plan({'First'}, theirs: [...annasGroups, pressing]);
      await shelf.createGroup('Label', exclusive: false);
      shelf.failEdit = true;

      await expectLater(p.add(shelf, [their(p, 'First')]), throwsException);
      final after = await p.add(shelf, [their(p, 'First')]);

      expect(after.tagIds, ['parlophone', 'first']);
      expect(shelf.groups.where((g) => g.name == 'Label'), hasLength(1));
    });
  });
}
