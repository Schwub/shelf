import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'friends_repository.dart';
import 'invitation_page.dart';

/// Type or paste an invite code; a known one opens the Invitation, whose
/// result (the new friend's ID) this page pops with.
class EnterCodePage extends StatefulWidget {
  const EnterCodePage({super.key, required this.friends});

  final FriendsRepository friends;

  @override
  State<EnterCodePage> createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  final _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the code from the invite.');
      return;
    }
    setState(() {
      _error = null;
      _checking = true;
    });
    try {
      final preview = await widget.friends.preview(code);
      if (!mounted) return;
      if (preview.status == InviteStatus.unknown) {
        setState(() {
          _checking = false;
          _error = "That code isn't right. Check it and try again.";
        });
        return;
      }
      setState(() => _checking = false);
      final friend = await Navigator.of(context).push(
        MaterialPageRoute<String>(
          builder: (_) => InvitationPage(
            friends: widget.friends,
            code: code,
            preview: preview,
          ),
        ),
      );
      if (friend != null && mounted) Navigator.of(context).pop(friend);
    } catch (e, stack) {
      reportError(e, stack);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error =
            "Couldn't check the code. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Enter code')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          children: [
            Text(
              'Invite code',
              style: text.labelSmall!.copyWith(color: c.muted),
            ),
            const SizedBox(height: 8),
            ShelfField(
              controller: _controller,
              hintText: 'K7Q2-M9XD',
              autofocus: true,
              onSubmitted: (_) => _check(),
            ),
            const SizedBox(height: 8),
            HelpLine(
              _error ?? 'The code is in the invite your friend sent.',
              error: _error != null,
            ),
            const SizedBox(height: 16),
            ShelfKey(
              primary: true,
              onPressed: _checking ? null : _check,
              child: Text(_checking ? 'Checking…' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
