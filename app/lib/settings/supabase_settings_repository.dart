import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings_repository.dart';

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this._db);

  final SupabaseClient _db;

  // Filtered by owner like every own-data query, although friends can't
  // read settings.
  @override
  Future<SavedSettings?> load() async {
    final row = await _db
        .from('user_settings')
        .select('theme, shelf_view, shelf_sort')
        .eq('user_id', _db.auth.currentUser!.id)
        .maybeSingle();
    if (row == null) return null;
    return (
      theme: row['theme'] as String?,
      list: switch (row['shelf_view']) {
        'list' => true,
        'covers' => false,
        _ => null,
      },
      sort: row['shelf_sort'] as String?,
    );
  }

  // An upsert updates only the columns it sends.
  @override
  Future<void> save({String? theme, bool? list, String? sort}) =>
      _db.from('user_settings').upsert({
        'theme': ?theme,
        if (list != null) 'shelf_view': list ? 'list' : 'covers',
        'shelf_sort': ?sort,
      });
}
