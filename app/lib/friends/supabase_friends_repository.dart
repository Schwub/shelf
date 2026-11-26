import 'package:supabase_flutter/supabase_flutter.dart';

import 'friends_repository.dart';

class SupabaseFriendsRepository implements FriendsRepository {
  SupabaseFriendsRepository(this._db);

  final SupabaseClient _db;

  String get _me => _db.auth.currentUser!.id;

  // Filtered by owner: friends can read each other's profiles (TASK-36).
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
}
