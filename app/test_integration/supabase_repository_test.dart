// The Supabase repositories (shelf, settings, friends) against a local
// Supabase (`mise run test:integration` starts it and passes its URL and
// keys). Checks what the in-memory fakes can't: PostgREST queries,
// database errors mapped to app errors, triggers and row-level security as
// the app meets them.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shelf_app/friends/friends_repository.dart';
import 'package:shelf_app/friends/supabase_friends_repository.dart';
import 'package:shelf_app/search/musicbrainz.dart';
import 'package:shelf_app/settings/supabase_settings_repository.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/shelf/shelf_repository.dart';
import 'package:shelf_app/shelf/supabase_shelf_repository.dart';
import 'package:shelf_app/tracks/track_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _env = Platform.environment;
final _url = _env['API_URL']!;

/// A new signed-in user (their own shelf, tags and filters), with an admin
/// client for what users can't do (adding catalog albums) and the user's own
/// client.
typedef Session = ({
  SupabaseShelfRepository repo,
  SupabaseClient admin,
  SupabaseClient db,
});

Future<Session> signIn() async {
  final admin = SupabaseClient(_url, _env['SERVICE_ROLE_KEY']!);
  final email = 'it${DateTime.now().microsecondsSinceEpoch}@example.com';
  await admin.auth.admin.createUser(
    AdminUserAttributes(
      email: email,
      password: 'secret123',
      emailConfirm: true,
    ),
  );
  final db = SupabaseClient(_url, _env['PUBLISHABLE_KEY']!);
  await db.auth.signInWithPassword(email: email, password: 'secret123');
  final repo = SupabaseShelfRepository(
    db,
    MusicBrainzTracks(MusicBrainz(http.Client())),
  );
  return (repo: repo, admin: admin, db: db);
}

/// An album on the user's shelf; returns the entry's ID.
Future<String> shelve(Session s) async {
  final album = await s.admin
      .from('albums')
      .insert({'title': 'Kid A', 'artist': 'Radiohead'})
      .select('id')
      .single();
  final entry = await s.db
      .from('shelf_entries')
      .insert({'album_id': album['id']})
      .select('id')
      .single();
  return entry['id'];
}

Map<String, String> tagIds(Shelf shelf) => {
  for (final g in shelf.allGroups)
    for (final t in g.tags) t.name: t.id,
};

void main() {
  test('friends: invite, accept, both see each other, remove', () async {
    final alice = SupabaseFriendsRepository((await signIn()).db);
    final bob = SupabaseFriendsRepository((await signIn()).db);
    await alice.saveName('Alice');
    await bob.saveName('Bob');

    final invite = await alice.createInvite();
    expect((await alice.load()).invites.map((i) => i.code), [invite.code]);
    expect(await bob.preview(formatCode(invite.code).toLowerCase()), (
      status: InviteStatus.valid,
      inviterName: 'Alice',
    ));
    await bob.accept(invite.code);

    expect((await bob.load()).friends.map((f) => f.name), ['Alice']);
    final aliceList = await alice.load();
    expect(aliceList.friends.map((f) => f.name), ['Bob']);
    expect(aliceList.invites, isEmpty, reason: 'used');
    await expectLater(
      bob.accept(invite.code),
      throwsA(
        isA<InviteFailed>().having(
          (e) => e.status,
          'status',
          InviteStatus.friends,
        ),
      ),
    );

    await bob.remove((await bob.load()).friends.single.id);
    expect((await alice.load()).friends, isEmpty);

    final waiting = await alice.createInvite();
    await alice.cancelInvite(waiting.code);
    expect((await alice.load()).invites, isEmpty);
    expect((await bob.preview(waiting.code)).status, InviteStatus.unknown);
  });

  test('names: none at first, then saved and changed', () async {
    final s = await signIn();
    final friends = SupabaseFriendsRepository(s.db);
    expect(await friends.myName(), isNull);

    await friends.saveName('Michael');
    expect(await friends.myName(), 'Michael');
    await friends.saveName('Mike');
    expect(await friends.myName(), 'Mike');

    final other = await signIn();
    expect(await SupabaseFriendsRepository(other.db).myName(), isNull);
  });

  test('settings: none at first, then saved one at a time', () async {
    final s = await signIn();
    final settings = SupabaseSettingsRepository(s.db);
    expect(await settings.load(), isNull);

    await settings.save(theme: 'evening', list: true);
    expect(await settings.load(), (theme: 'evening', list: true));

    await settings.save(list: false);
    expect(await settings.load(), (theme: 'evening', list: false));

    await settings.save(theme: 'tobacco');
    expect(await settings.load(), (theme: 'tobacco', list: false));

    final other = await signIn();
    expect(await SupabaseSettingsRepository(other.db).load(), isNull);
  });

  test('new users start with the suggested groups and filters', () async {
    final s = await signIn();
    final repo = s.repo;
    final shelf = await repo.load();

    expect(
      [
        for (final g in shelf.allGroups)
          if (g.parentTagId == null) g.name,
      ],
      ['Collection', 'Listening', 'Genre'],
    );
    expect(
      shelf.allGroups.firstWhere((g) => g.name == 'Genre').pickFromList,
      isTrue,
    );
    expect(
      [for (final f in shelf.filters) f.label],
      ['Own', 'Want', 'Want to listen', 'Listened'],
    );
  });

  test('the tag editor: names, order, one per album, deletes', () async {
    final s = await signIn();
    final repo = s.repo;
    await repo.createGroup(
      'Mood',
      exclusive: false,
      tags: ['Calm', 'Late night'],
    );
    await expectLater(
      repo.createGroup('mood', exclusive: true),
      throwsA(isA<DuplicateName>()),
    );
    var shelf = await repo.load();
    final mood = shelf.allGroups.firstWhere((g) => g.name == 'Mood');
    final tag = await repo.createTag(mood.id, 'Sunday');
    await expectLater(
      repo.renameTag(tag.id, 'calm'),
      throwsA(isA<DuplicateName>()),
    );
    await repo.reorderTags([tag.id, ...mood.tags.map((t) => t.id)]);

    final entry = await shelve(s);
    await repo.save(entry, addTags: [mood.tags[0].id, mood.tags[1].id]);
    await expectLater(
      repo.updateGroup(mood.id, exclusive: true),
      throwsA(isA<SeveralTags>()),
    );

    await repo.createGroup(
      'Where',
      exclusive: true,
      parentTagId: mood.tags[0].id,
      tags: ['Home'],
    );
    await repo.deleteTag(mood.tags[0].id);
    shelf = await repo.load();
    final after = shelf.allGroups.firstWhere((g) => g.id == mood.id);
    expect([for (final t in after.tags) t.name], ['Sunday', 'Late night']);
    expect(shelf.allGroups.any((g) => g.name == 'Where'), isFalse);
    expect(shelf.entries.single.tagIds, {mood.tags[1].id});
  });

  test('track lists save whole, load in order, null leaves them', () async {
    final s = await signIn();
    final repo = s.repo;
    final entry = await shelve(s);
    await repo.save(
      entry,
      tracks: const [
        Track(title: 'B', disc: 2, position: 1),
        Track(title: 'A2', position: 2, lengthMs: 1000, favorite: true),
        Track(title: 'A1', position: 1),
      ],
    );
    var tracks = (await repo.load()).entries.single.tracks;
    // PostgREST ignores ordering nested rows; the app sorts them.
    expect([for (final t in tracks) t.title], ['A1', 'A2', 'B']);
    expect(tracks[1].favorite, isTrue);

    await repo.save(entry, rating: 4);
    expect((await repo.load()).entries.single.tracks, hasLength(3));
    await repo.save(entry, tracks: const []);
    tracks = (await repo.load()).entries.single.tracks;
    expect(tracks, isEmpty);
  });

  test('filters: custom conditions, tag swaps, reorder, delete', () async {
    final s = await signIn();
    final repo = s.repo;
    var shelf = await repo.load();
    final tag = tagIds(shelf);

    await repo.saveFilter(
      ShelfFilter(
        name: 'Mine',
        tagIds: [tag['Own']!, tag['Vinyl']!],
        matchAll: true,
        minRating: 8,
      ),
    );
    shelf = await repo.load();
    var mine = shelf.allFilters.last;
    expect(mine.label, 'Mine');
    expect(mine.tagIds.toSet(), {tag['Own']!, tag['Vinyl']!});

    // Swapping all tags must not leave the filter empty on the way: the
    // database deletes filters without conditions.
    await repo.saveFilter(
      mine.copyWith(tagIds: [tag['CD']!], minRating: () => null),
    );
    shelf = await repo.load();
    mine = shelf.allFilters.last;
    expect(mine.tagIds, [tag['CD']!]);
    expect(mine.minRating, isNull);

    await repo.reorderFilters(
      shelf.allFilters.reversed.map((f) => f.id).toList(),
    );
    await repo.deleteFilter(mine.id);
    shelf = await repo.load();
    expect(shelf.allFilters.first.label, 'Listened');
    expect(shelf.allFilters.any((f) => f.label == 'Mine'), isFalse);
  });

  test('a tag filter goes when its tag is deleted', () async {
    final s = await signIn();
    final repo = s.repo;
    final shelf = await repo.load();
    final genre = shelf.allGroups.firstWhere((g) => g.name == 'Genre');
    final jazz = await repo.createTag(genre.id, 'Jazz');
    await repo.saveFilter(ShelfFilter(tagIds: [jazz.id]));
    expect((await repo.load()).allFilters.last.label, 'Jazz');

    await repo.deleteTag(jazz.id);
    expect(
      (await repo.load()).allFilters.any((f) => f.label == 'Jazz'),
      isFalse,
    );
  });
}
