import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'auth.dart';
import 'sign_in_page.dart';

/// Enter the code from the sign-in email; resend it or change the email.
class CheckEmailPage extends StatefulWidget {
  const CheckEmailPage({super.key, required this.auth, required this.email});

  final Auth auth;
  final String email;

  static const resendAfter = 60;

  @override
  State<CheckEmailPage> createState() => _CheckEmailPageState();
}

class _CheckEmailPageState extends State<CheckEmailPage> {
  final _code = TextEditingController();
  String? _error;
  String? _note;
  bool _busy = false;
  int _wait = CheckEmailPage.resendAfter;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _wait = CheckEmailPage.resendAfter;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _wait--);
      if (_wait == 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code from the email.');
      return;
    }
    setState(() {
      _error = _note = null;
      _busy = true;
    });
    try {
      // Signing in replaces this screen (see AuthGate).
      await widget.auth.verifyCode(widget.email, code);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is WrongCode
            ? "That code isn't right or has expired. Check it, or send a new one."
            : "Couldn't sign in. Check your connection and try again.";
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _error = _note = null;
      _busy = true;
    });
    try {
      await widget.auth.sendCode(widget.email);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _note = 'We sent a new code.';
        _startCountdown();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = sendError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium!.copyWith(color: c.muted);
    final minutes = _wait ~/ 60, seconds = '${_wait % 60}'.padLeft(2, '0');
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ShelfKey(
                semanticLabel: 'Back',
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(Icons.chevron_left),
              ),
            ),
            const SizedBox(height: 40),
            Icon(Icons.mail_outline, size: 32, color: c.muted),
            const SizedBox(height: 12),
            Text(
              'Check your email',
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: 'We sent a code to\n',
                children: [
                  TextSpan(
                    text: widget.email,
                    style: TextStyle(
                      color: c.text,
                      fontVariations: const [FontVariation.weight(600)],
                    ),
                  ),
                ],
              ),
              style: muted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ShelfField(
              controller: _code,
              hintText: '6-digit code',
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 8),
            HelpLine(
              _error ??
                  _note ??
                  'Or open the link in the email on this device. '
                      'The code works once and for one hour.',
              error: _error != null,
            ),
            const SizedBox(height: 16),
            ShelfKey(
              primary: true,
              onPressed: _busy ? null : _verify,
              child: const Text('Sign in'),
            ),
            const SizedBox(height: 24),
            Center(
              child: ShelfKey(
                onPressed: _wait > 0 || _busy ? null : _resend,
                child: Text(
                  _wait > 0
                      ? 'Resend code in $minutes:$seconds'
                      : 'Resend code',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ShelfKey(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Use a different email'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
