import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_repository.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this._db);

  final SupabaseClient _db;

  // Row-level security limits the table to the signed-in user's row.
  @override
  Future<SavedSettings?> load() async {
    final row = await _db
        .from('user_settings')
        .select('theme, shelf_view')
        .maybeSingle();
    if (row == null) return null;
    return (
      theme: row['theme'] as String?,
      list: switch (row['shelf_view']) {
        'list' => true,
        'covers' => false,
        _ => null,
      },
    );
  }

  // An upsert updates only the columns it sends.
  @override
  Future<void> save({String? theme, bool? list}) =>
      _db.from('user_settings').upsert({
        'theme': ?theme,
        if (list != null) 'shelf_view': list ? 'list' : 'covers',
      });
}
