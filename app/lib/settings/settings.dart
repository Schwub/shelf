import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors.dart';
import '../shelf/shelf.dart';
import '../theme/shelf_colors.dart';
import 'settings_repository.dart';

/// The user's theme, covers-or-list choice and shelf order. Saved in the database so
/// they follow the user to every device; the device keeps a copy, used
/// before sign-in and while offline.
class Settings {
  Settings(
    this._repository, {
    AppTheme theme = AppTheme.tobacco,
    bool list = false,
    ShelfSort sort = ShelfSort.newest,
  }) : theme = ValueNotifier(theme),
       list = ValueNotifier(list),
       sort = ValueNotifier(sort);

  final SettingsRepository _repository;
  final ValueNotifier<AppTheme> theme;

  /// The shelf as a list instead of covers.
  final ValueNotifier<bool> list;

  /// How My shelf and friends' shelves are sorted.
  final ValueNotifier<ShelfSort> sort;

  static const _themeKey = 'theme';
  static const _listKey = 'shelf.list';
  static const _sortKey = 'shelf.sort';

  /// The settings last known on this device.
  static Future<Settings> load(SettingsRepository repository) async {
    final prefs = await SharedPreferences.getInstance();
    return Settings(
      repository,
      theme: _theme(prefs.getString(_themeKey)),
      list: prefs.getBool(_listKey) ?? false,
      sort: ShelfSort.parse(prefs.getString(_sortKey)),
    );
  }

  /// Takes the user's saved settings, if they saved any, except what the
  /// user changed while they loaded. Offline the device's stay; not
  /// reported, as My shelf's own load reports a failing server.
  Future<void> sync() async {
    final (themeBefore, listBefore, sortBefore) = (
      theme.value,
      list.value,
      sort.value,
    );
    final SavedSettings? saved;
    try {
      saved = await _repository.load();
    } catch (_) {
      return;
    }
    if (saved == null) return;
    if (theme.value == themeBefore) theme.value = _theme(saved.theme);
    if (list.value == listBefore) list.value = saved.list ?? false;
    if (sort.value == sortBefore) sort.value = ShelfSort.parse(saved.sort);
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

  Future<void> chooseSort(ShelfSort chosen) {
    sort.value = chosen;
    return _save(sort: chosen.key);
  }

  /// One save at a time, so the last choice is the one saved. Kept on the
  /// device first; if saving fails, the next sync brings back what the
  /// database has.
  Future<void> _saving = Future.value();

  Future<void> _save({String? theme, bool? list, String? sort}) async {
    await _cache();
    _saving = _saving.then((_) async {
      try {
        await _repository.save(theme: theme, list: list, sort: sort);
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
    await prefs.setString(_sortKey, sort.value.key);
  }

  static AppTheme _theme(String? name) =>
      AppTheme.values.where((t) => t.name == name).firstOrNull ??
      AppTheme.tobacco;
}
