import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'auth.dart';
import 'sign_in_page.dart';

/// Shows [signedIn] or the sign-in screen, and returns to it after signing
/// in or out (closing the code screen, menus and dialogs on top).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth, required this.signedIn});

  final Auth auth;
  final Widget signedIn;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _signedIn = widget.auth.signedIn;
  late final StreamSubscription<bool> _changes;

  @override
  void initState() {
    super.initState();
    _changes = widget.auth.changes.listen((signedIn) {
      if (!mounted || signedIn == _signedIn) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() => _signedIn = signedIn);
    });
  }

  @override
  void dispose() {
    _changes.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _signedIn ? widget.signedIn : SignInPage(auth: widget.auth);
}
