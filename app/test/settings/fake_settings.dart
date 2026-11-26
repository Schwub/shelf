import 'package:shelf_app/settings/settings_repository.dart';

/// Settings kept in memory; [offline] makes every call fail.
class FakeSettings implements SettingsRepository {
  FakeSettings([this.saved]);

  SavedSettings? saved;
  bool offline = false;

  @override
  Future<SavedSettings?> load() async {
    if (offline) throw Exception('offline');
    return saved;
  }

  @override
  Future<void> save({String? theme, bool? list, String? sort}) async {
    if (offline) throw Exception('offline');
    saved = (
      theme: theme ?? saved?.theme,
      list: list ?? saved?.list,
      sort: sort ?? saved?.sort,
    );
  }
}
