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

  /// Takes the user's saved settings, if they saved any, except what the
  /// user changed while they loaded. Offline the device's stay; not
  /// reported, as My shelf's own load reports a failing server.
  Future<void> sync() async {
    final (themeBefore, listBefore) = (theme.value, list.value);
    final SavedSettings? saved;
    try {
      saved = await _repository.load();
    } catch (_) {
      return;
    }
    if (saved == null) return;
    if (theme.value == themeBefore) theme.value = _theme(saved.theme);
    if (list.value == listBefore) list.value = saved.list ?? false;
    await _cache();
  }

  Future<void> chooseTheme(AppTheme chosen) {
    theme.value = chosen;
    return _save(theme: chosen.name);
  }

  Future<void> chooseList(bool chosen) {
    list.value = chosen;
    return _save(list: chosen);
  }

  /// One save at a time, so the last choice is the one saved. Kept on the
  /// device first; if saving fails, the next sync brings back what the
  /// database has.
  Future<void> _saving = Future.value();

  Future<void> _save({String? theme, bool? list}) async {
    await _cache();
    _saving = _saving.then((_) async {
      try {
        await _repository.save(theme: theme, list: list);
      } catch (e, stack) {
        await reportError(e, stack);
      }
    });
    return _saving;
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
