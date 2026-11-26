import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_app/settings/settings.dart';
import 'package:shelf_app/settings/settings_repository.dart';
import 'package:shelf_app/shelf/shelf.dart';
import 'package:shelf_app/theme/shelf_colors.dart';

import 'fake_settings.dart';

/// [FakeSettings] whose loads and saves wait until the test lets them go.
class SlowSettings extends FakeSettings {
  SlowSettings([super.saved]);

  final loads = <Completer<void>>[];
  final saves = <Completer<void>>[];

  @override
  Future<SavedSettings?> load() async {
    final saved = this.saved;
    final wait = Completer<void>();
    loads.add(wait);
    await wait.future;
    return saved;
  }

  @override
  Future<void> save({String? theme, bool? list, String? sort}) async {
    final wait = Completer<void>();
    saves.add(wait);
    await wait.future;
    return super.save(theme: theme, list: list, sort: sort);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults until the user chose something', () async {
    final settings = await Settings.load(FakeSettings());
    await settings.sync();

    expect(settings.theme.value, AppTheme.tobacco);
    expect(settings.list.value, isFalse);
    expect(settings.sort.value, ShelfSort.newest);
  });

  test('a choice shows at once, is saved and kept on the device', () async {
    final server = FakeSettings();
    final settings = await Settings.load(server);

    await settings.chooseTheme(AppTheme.evening);
    await settings.chooseList(true);
    await settings.chooseSort(const ShelfSort(SortBy.title, reversed: true));

    expect(settings.theme.value, AppTheme.evening);
    expect(server.saved, (
      theme: 'evening',
      list: true,
      sort: 'title_reversed',
    ));
    final restarted = await Settings.load(FakeSettings());
    expect(restarted.theme.value, AppTheme.evening);
    expect(restarted.list.value, isTrue);
    expect(restarted.sort.value, const ShelfSort(SortBy.title, reversed: true));
  });

  test('the saved settings replace the device\'s and are cached', () async {
    SharedPreferences.setMockInitialValues({
      'theme': 'evening',
      'shelf.list': false,
    });
    final settings = await Settings.load(
      FakeSettings((theme: 'surfGreen', list: true, sort: 'artist')),
    );
    expect(settings.theme.value, AppTheme.evening, reason: 'before sync');

    await settings.sync();

    expect(settings.theme.value, AppTheme.surfGreen);
    expect(settings.list.value, isTrue);
    expect(settings.sort.value, const ShelfSort(SortBy.artist));
    final offline = FakeSettings()..offline = true;
    final restarted = await Settings.load(offline);
    await restarted.sync();
    expect(restarted.theme.value, AppTheme.surfGreen);
    expect(restarted.list.value, isTrue);
    expect(restarted.sort.value, const ShelfSort(SortBy.artist));
  });

  test('unknown or missing saved values are the defaults', () async {
    SharedPreferences.setMockInitialValues({'theme': 'evening'});
    final settings = await Settings.load(
      FakeSettings((theme: 'gone', list: null, sort: 'colour')),
    );

    await settings.sync();

    expect(settings.theme.value, AppTheme.tobacco);
    expect(settings.list.value, isFalse);
    expect(settings.sort.value, ShelfSort.newest);
  });

  test('offline, a choice still shows and stays on the device', () async {
    final server = FakeSettings()..offline = true;
    final settings = await Settings.load(server);

    await settings.chooseTheme(AppTheme.evening);

    expect(settings.theme.value, AppTheme.evening);
    expect(server.saved, isNull);
    expect((await Settings.load(server)).theme.value, AppTheme.evening);
  });

  test('a choice made while the settings load is kept', () async {
    final server = SlowSettings((theme: 'evening', list: false, sort: null));
    final settings = await Settings.load(server);

    final syncing = settings.sync();
    await pumpEventQueue();
    final choosing = settings.chooseList(true);
    server.loads.single.complete();
    await syncing;
    await pumpEventQueue();
    server.saves.single.complete();
    await choosing;

    expect(settings.list.value, isTrue, reason: 'the choice');
    expect(settings.theme.value, AppTheme.evening, reason: 'from the server');
    expect(server.saved, (theme: 'evening', list: true, sort: null));
  });

  test('quick choices are saved in order', () async {
    final server = SlowSettings();
    final settings = await Settings.load(server);

    final first = settings.chooseList(true);
    final second = settings.chooseList(false);
    await pumpEventQueue();
    expect(server.saves, hasLength(1), reason: 'the second waits');
    server.saves.single.complete();
    await pumpEventQueue();
    server.saves.last.complete();
    await Future.wait([first, second]);

    expect(server.saved?.list, isFalse);
  });
}
