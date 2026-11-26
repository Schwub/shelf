/// The settings saved for the signed-in user: a theme name and whether the
/// shelf shows a list; null fields are the app's defaults.
typedef SavedSettings = ({String? theme, bool? list});

/// Where the user's settings are kept. An interface so the app can be
/// tested without a server.
abstract class SettingsRepository {
  /// Null if the user never saved any.
  Future<SavedSettings?> load();

  Future<void> save({required String theme, required bool list});
}
