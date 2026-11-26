import 'package:supabase_flutter/supabase_flutter.dart';

import 'friends_repository.dart';

class SupabaseFriendsRepository implements FriendsRepository {
  SupabaseFriendsRepository(this._db);

  final SupabaseClient _db;

  String get _me => _db.auth.currentUser!.id;

  // Filtered by owner: friends can read each other's profiles.
  @override
  Future<String?> myName() async {
    final row = await _db
        .from('profiles')
        .select('name')
        .eq('user_id', _me)
        .maybeSingle();
    return row?['name'] as String?;
  }

  @override
  Future<void> saveName(String name) =>
      _db.from('profiles').upsert({'name': name});

  @override
  Future<FriendsList> load() async {
    final (friendships, invites) = await (
      _db
          .from('friendships')
          .select('friend_id')
          .eq('user_id', _me)
          .order('created_at'),
      _db
          .from('invites')
          .select('code, expires_at')
          .eq('inviter', _me)
          .isFilter('accepted_by', null)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at'),
    ).wait;
    final ids = [for (final f in friendships) f['friend_id'] as String];
    // Friendships point at accounts, not profiles, so names come separately.
    final (names, entries) = ids.isEmpty
        ? (const <Map<String, dynamic>>[], const <Map<String, dynamic>>[])
        : await (
            _db
                .from('profiles')
                .select('user_id, name')
                .inFilter('user_id', ids),
            // Row-level security leaves out entries hidden from friends.
            _db
                .from('shelf_entries')
                .select('user_id')
                .inFilter('user_id', ids),
          ).wait;
    final nameOf = {for (final p in names) p['user_id']: p['name'] as String};
    final albums = <String, int>{};
    for (final e in entries) {
      albums.update(e['user_id'], (n) => n + 1, ifAbsent: () => 1);
    }
    return (
      friends: [
        for (final id in ids)
          if (nameOf[id] case final name?)
            (id: id, name: name, albums: albums[id] ?? 0),
      ],
      invites: [for (final i in invites) _invite(i)],
    );
  }

  static Invite _invite(Map<String, dynamic> row) => (
    code: row['code'] as String,
    expiresAt: DateTime.parse(row['expires_at'] as String),
  );

  @override
  Future<Invite> createInvite() async {
    final code = await _db.rpc<String>('create_invite');
    return _invite(
      await _db
          .from('invites')
          .select('code, expires_at')
          .eq('code', code)
          .single(),
    );
  }

  @override
  Future<void> cancelInvite(String code) =>
      _db.from('invites').delete().eq('code', code);

  @override
  Future<InvitePreview> preview(String code) async {
    final rows = await _db.rpc<List<dynamic>>(
      'invite_preview',
      params: {'input': code},
    );
    final row = rows.single as Map<String, dynamic>;
    return (
      status: InviteStatus.values.byName(row['status'] as String),
      inviterId: row['inviter_id'] as String?,
      inviterName: row['inviter_name'] as String?,
    );
  }

  @override
  Future<void> accept(String code) async {
    try {
      await _db.rpc<String>('accept_invite', params: {'input': code});
    } on PostgrestException catch (e) {
      // accept_invite raises the reason as the message.
      final status = InviteStatus.values.asNameMap()[e.message];
      if (e.code == 'P0001' && status != null) throw InviteFailed(status);
      rethrow;
    }
  }

  @override
  Future<void> remove(String friendId) =>
      _db.rpc<void>('remove_friend', params: {'friend': friendId});
}
