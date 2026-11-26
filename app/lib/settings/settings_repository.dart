/// The settings saved for the signed-in user: a theme name, whether the
/// shelf shows a list and how it is sorted ([ShelfSort.key]); null fields
/// are the app's defaults.
typedef SavedSettings = ({String? theme, bool? list, String? sort});

/// Where the user's settings are kept. An interface so the app can be
/// tested without a server.
abstract class SettingsRepository {
  /// Null if the user never saved any.
  Future<SavedSettings?> load();

  /// Saves the given settings and leaves the others.
  Future<void> save({String? theme, bool? list, String? sort});
}
