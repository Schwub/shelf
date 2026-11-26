import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An invite code from a link that opened the app, waiting until the user
/// is signed in and named. Kept on the device, in case the app is closed
/// before that (signing in by the emailed link may restart it).
class PendingInvite extends ValueNotifier<String?> {
  PendingInvite([super.value]);

  static const _key = 'invite.pending';

  /// The code kept from before, then each one from [codes].
  static Future<PendingInvite> load(Stream<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = PendingInvite(prefs.getString(_key));
    codes.listen((code) async {
      await prefs.setString(_key, code);
      pending.value = code;
    });
    return pending;
  }

  /// The code, once: it is forgotten here and on the device.
  Future<String?> take() async {
    final code = value;
    value = null;
    await (await SharedPreferences.getInstance()).remove(_key);
    return code;
  }
}
