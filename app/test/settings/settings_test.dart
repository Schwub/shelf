import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/settings/settings.dart';
import 'package:shelf_app/theme/shelf_colors.dart';

import 'fake_settings.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults until the user chose something', () async {
    final settings = await Settings.load(FakeSettings());
    await settings.sync();

    expect(settings.theme.value, AppTheme.tobacco);
    expect(settings.list.value, isFalse);
  });

  test('a choice shows at once, is saved and kept on the device', () async {
    final server = FakeSettings();
    final settings = await Settings.load(server);

    await settings.chooseTheme(AppTheme.evening);
    await settings.chooseList(true);

    expect(settings.theme.value, AppTheme.evening);
    expect(server.saved, (theme: 'evening', list: true));
    final restarted = await Settings.load(FakeSettings());
    expect(restarted.theme.value, AppTheme.evening);
    expect(restarted.list.value, isTrue);
  });

  test('the saved settings replace the device\'s and are cached', () async {
    SharedPreferences.setMockInitialValues({
      'theme': 'evening',
      'shelf.list': false,
    });
    final settings = await Settings.load(
      FakeSettings((theme: 'surfGreen', list: true)),
    );
    expect(settings.theme.value, AppTheme.evening, reason: 'before sync');

    await settings.sync();

    expect(settings.theme.value, AppTheme.surfGreen);
    expect(settings.list.value, isTrue);
    final offline = FakeSettings()..offline = true;
    final restarted = await Settings.load(offline);
    await restarted.sync();
    expect(restarted.theme.value, AppTheme.surfGreen);
    expect(restarted.list.value, isTrue);
  });

  test('unknown or missing saved values are the defaults', () async {
    SharedPreferences.setMockInitialValues({'theme': 'evening'});
    final settings = await Settings.load(
      FakeSettings((theme: 'gone', list: null)),
    );

    await settings.sync();

    expect(settings.theme.value, AppTheme.tobacco);
    expect(settings.list.value, isFalse);
  });

  test('offline, a choice still shows and stays on the device', () async {
    final server = FakeSettings()..offline = true;
    final settings = await Settings.load(server);

    await settings.chooseTheme(AppTheme.evening);

    expect(settings.theme.value, AppTheme.evening);
    expect(server.saved, isNull);
    expect((await Settings.load(server)).theme.value, AppTheme.evening);
  });
}
