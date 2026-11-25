import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shelf_colors.dart';

/// The chosen theme, remembered on the device (TASK-25 moves settings to
/// the database). Tobacco & copper until the user picks another.
class ThemeChoice extends ValueNotifier<AppTheme> {
  ThemeChoice([super.value = AppTheme.tobacco]);

  static const _key = 'theme';

  static Future<ThemeChoice> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    return ThemeChoice(
      AppTheme.values.where((t) => t.name == saved).firstOrNull ??
          AppTheme.tobacco,
    );
  }

  Future<void> choose(AppTheme theme) async {
    value = theme;
    await (await SharedPreferences.getInstance()).setString(_key, theme.name);
  }
}
