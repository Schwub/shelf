import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../theme/shelf_theme.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'auth.dart';
import 'check_email_page.dart';

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Enter an email to get a sign-in code and link.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.auth, this.linkFailed = false});

  final Auth auth;

  /// The email's link didn't work: shows a note to send a new one.
  final bool linkFailed;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _controller = TextEditingController();
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _controller.text.trim();
    if (!_email.hasMatch(email)) {
      setState(
        () => _error = 'Enter a valid email address, like name@example.com.',
      );
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    try {
      await widget.auth.sendCode(email);
      if (!mounted) return;
      setState(() => _sending = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CheckEmailPage(auth: widget.auth, email: email),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = sendError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 3,
              child: _sending
                  ? LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: c.off,
                      color: c.signal,
                    )
                  : null,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.linkFailed ? 24 : 64,
                  20,
                  20,
                ),
                children: [
                  if (widget.linkFailed) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: c.line),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: HelpLine(
                          'This link has expired or was already used. '
                          'Send a new one below.',
                          error: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'shelf',
                    style: archivo(
                      34,
                      width: 125,
                      weight: 800,
                    ).copyWith(color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your albums, and what your friends are listening to.',
                    style: text.bodyMedium!.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Email',
                    style: text.labelSmall!.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: 8),
                  ShelfField(
                    controller: _controller,
                    hintText: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) => _send(),
                  ),
                  const SizedBox(height: 8),
                  HelpLine(
                    _error ?? "We'll email you a code to sign in. No password needed.",
                    error: _error != null,
                  ),
                  const SizedBox(height: 16),
                  ShelfKey(
                    primary: true,
                    onPressed: _sending ? null : _send,
                    child: Text(_sending ? 'Sending…' : 'Send sign-in code'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The message for a failed sign-in email.
String sendError(Object error) => error is TooManyEmails
    ? 'Too many sign-in emails. Wait a few minutes and try again.'
    : "Couldn't send the email. Check your connection and try again.";
