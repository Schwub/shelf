import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import 'settings_repository.dart';

/// The user's theme and covers-or-list choice. Saved in the database so
/// they follow the user to every device; the device keeps a copy, used
/// before sign-in and while offline.
class Settings {
  Settings(
    this._repository, {
    AppTheme theme = AppTheme.tobacco,
    bool list = false,
  }) : theme = ValueNotifier(theme),
       list = ValueNotifier(list);

  final SettingsRepository _repository;
  final ValueNotifier<AppTheme> theme;

  /// The shelf as a list instead of covers.
  final ValueNotifier<bool> list;

  static const _themeKey = 'theme';
  static const _listKey = 'shelf.list';

  /// The settings last known on this device.
  static Future<Settings> load(SettingsRepository repository) async {
    final prefs = await SharedPreferences.getInstance();
    return Settings(
      repository,
      theme: _theme(prefs.getString(_themeKey)),
      list: prefs.getBool(_listKey) ?? false,
    );
  }

  /// Takes the user's saved settings, if they saved any; offline, the
  /// device's stay.
  Future<void> sync() async {
    final SavedSettings? saved;
    try {
      saved = await _repository.load();
    } catch (e, stack) {
      await reportError(e, stack);
      return;
    }
    if (saved == null) return;
    theme.value = _theme(saved.theme);
    list.value = saved.list ?? false;
    await _cache();
  }

  Future<void> chooseTheme(AppTheme chosen) =>
      _choose(() => theme.value = chosen);

  Future<void> chooseList(bool chosen) => _choose(() => list.value = chosen);

  /// Shown at once and kept on the device; if saving fails, the next sync
  /// brings back what the database has.
  Future<void> _choose(void Function() change) async {
    change();
    await _cache();
    try {
      await _repository.save(theme: theme.value.name, list: list.value);
    } catch (e, stack) {
      await reportError(e, stack);
    }
  }

  Future<void> _cache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.value.name);
    await prefs.setBool(_listKey, list.value);
  }

  static AppTheme _theme(String? name) =>
      AppTheme.values.where((t) => t.name == name).firstOrNull ??
      AppTheme.tobacco;
}
