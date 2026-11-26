import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An invite code from a web link (`/invite/K7Q2-M9XD`), waiting until the
/// user is signed in and named. Kept on the device, because signing in by
/// the emailed link reloads the app at its start page.
class PendingInvite extends ValueNotifier<String?> {
  PendingInvite([super.value]);

  static const _key = 'invite.pending';
  static final _path = RegExp(r'^/invite/([A-Za-z0-9-]+)/?$');

  /// The code in [url], else the one kept from before.
  static Future<PendingInvite> load(Uri url) async {
    final prefs = await SharedPreferences.getInstance();
    final code = _path.firstMatch(url.path)?.group(1);
    if (code != null) await prefs.setString(_key, code);
    return PendingInvite(code ?? prefs.getString(_key));
  }

  /// The code, once: it is forgotten here and on the device.
  Future<String?> take() async {
    final code = value;
    value = null;
    await (await SharedPreferences.getInstance()).remove(_key);
    return code;
  }
}
