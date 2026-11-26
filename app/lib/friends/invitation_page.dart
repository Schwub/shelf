import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/message.dart';
import '../widgets/shelf_key.dart';
import 'friends_repository.dart';

/// "Anna invited you": accept an invite or not now. Pops with the
/// inviter's ID once accepted, else null.
class InvitationPage extends StatefulWidget {
  const InvitationPage({
    super.key,
    required this.friends,
    required this.code,
    this.preview,
  });

  final FriendsRepository friends;
  final String code;

  /// Already looked up (Enter code); else it loads here.
  final InvitePreview? preview;

  @override
  State<InvitationPage> createState() => _InvitationPageState();
}

class _InvitationPageState extends State<InvitationPage> {
  late InvitePreview? _preview = widget.preview;
  bool _failed = false;
  bool _accepting = false;
  String? _acceptError;

  @override
  void initState() {
    super.initState();
    if (_preview == null) _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final preview = await widget.friends.preview(widget.code);
      if (mounted) setState(() => _preview = preview);
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _accept(InvitePreview preview) async {
    setState(() {
      _accepting = true;
      _acceptError = null;
    });
    try {
      await widget.friends.accept(widget.code);
      if (mounted) Navigator.of(context).pop(preview.inviterId);
    } on InviteFailed catch (e) {
      // Used or cancelled meanwhile: show why.
      if (mounted) {
        setState(() {
          _accepting = false;
          _preview = (
            status: e.status,
            inviterId: preview.inviterId,
            inviterName: preview.inviterName,
          );
        });
      }
    } catch (e, stack) {
      reportError(e, stack);
      if (!mounted) return;
      setState(() {
        _accepting = false;
        _acceptError = "Couldn't accept the invite. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final close = ShelfKey(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Close'),
    );
    final Widget body;
    if (_failed) {
      body = Message(
        title: "Couldn't look up the invite",
        text: 'Check your connection and try again.',
        actions: [
          ShelfKey(
            primary: true,
            onPressed: _load,
            child: const Text('Try again'),
          ),
          close,
        ],
      );
    } else if (preview == null) {
      body = Semantics(
        label: 'Looking up the invite',
        child: LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: context.shelf.off,
          color: context.shelf.signal,
        ),
      );
    } else {
      final name = preview.inviterName ?? 'Your friend';
      body = switch (preview.status) {
        InviteStatus.valid => Message(
          title: '$name invited you',
          text:
              "You'll see each other's shelves and what you add and rate. "
              'Either of you can end it under Friends.',
          actions: [
            if (_acceptError case final error?) HelpLine(error, error: true),
            ShelfKey(
              primary: true,
              onPressed: _accepting ? null : () => _accept(preview),
              child: Text(_accepting ? 'Accepting…' : 'Accept'),
            ),
            ShelfKey(
              onPressed: _accepting ? null : () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
          ],
        ),
        InviteStatus.gone => Message(
          title: 'This invite has expired',
          text: 'Invites work once and for 7 days. Ask $name for a new one.',
          actions: [close],
        ),
        InviteStatus.own => Message(
          title: "That's your own invite",
          text: 'Send it to a friend instead.',
          actions: [close],
        ),
        InviteStatus.friends => Message(
          title: 'You and $name are already friends',
          actions: [close],
        ),
        InviteStatus.unknown => Message(
          title: "That invite doesn't exist",
          text: 'Check the link or code, or ask for a new one.',
          actions: [close],
        ),
      };
    }
    return Scaffold(body: SafeArea(child: body));
  }
}
