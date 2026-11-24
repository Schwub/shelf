import 'dart:async';

import 'package:shelf_app/auth/auth.dart';

/// Accepts the code '123456'; [sendError] and [verifyError] make the
/// next call fail.
class FakeAuth implements Auth {
  FakeAuth({this.signedIn = false});

  @override
  bool signedIn;
  final _changes = StreamController<bool>.broadcast();
  final sent = <String>[];
  Object? sendError, verifyError;

  @override
  Stream<bool> get changes => _changes.stream;

  void _set(bool signedIn) {
    this.signedIn = signedIn;
    _changes.add(signedIn);
  }

  /// The email's link failed, as the server reports it.
  void failLink() => _changes.addError(LinkFailed());

  @override
  Future<void> sendCode(String email) async {
    final error = sendError;
    sendError = null;
    if (error != null) throw error;
    sent.add(email);
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    final error = verifyError;
    verifyError = null;
    if (error != null) throw error;
    if (code != '123456') throw WrongCode();
    _set(true);
  }

  @override
  Future<void> signOut() async => _set(false);
}
