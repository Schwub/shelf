import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../shelf/shelf_repository.dart';
import '../theme/shelf_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/list_row.dart';
import '../widgets/message.dart';
import '../widgets/shelf_key.dart';
import '../widgets/text_link.dart';
import 'enter_code_page.dart';
import 'friend_shelf_page.dart';
import 'friends_repository.dart';
import 'invitation_page.dart';
import 'invite_sheet.dart';
import 'name_page.dart';
import 'pending_invite.dart';

/// Your name, your friends and the invites waiting; invite, enter a code,
/// remove a friend. Opens the Invitation for a [pending] web link.
class FriendsPage extends StatefulWidget {
  const FriendsPage({
    super.key,
    required this.friends,
    required this.name,
    required this.pending,
    required this.shelf,
  });

  final FriendsRepository friends;
  final ValueNotifier<String> name;
  final PendingInvite pending;
  final ShelfRepository shelf;

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  FriendsList? _list;
  bool _failed = false;
  bool _inviting = false;

  /// Full-screen pages go over the navigation bar.
  NavigatorState get _root => Navigator.of(context, rootNavigator: true);

  @override
  void initState() {
    super.initState();
    _load();
    widget.pending.addListener(_openPending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  @override
  void dispose() {
    widget.pending.removeListener(_openPending);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final list = await widget.friends.load();
      if (mounted) setState(() => _list = list);
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _openPending() async {
    if (!mounted || widget.pending.value == null) return;
    final code = await widget.pending.take();
    if (code == null || !mounted) return;
    await _openInvitation(
      MaterialPageRoute<String>(
        builder: (_) => InvitationPage(friends: widget.friends, code: code),
      ),
    );
  }

  /// Shows the Invitation (or Enter code, which leads to it) and, once
  /// accepted, the new friend's shelf.
  Future<void> _openInvitation(Route<String> route) async {
    final id = await _root.push(route);
    if (id == null || !mounted) return;
    await _load();
    final friend = _list?.friends.where((f) => f.id == id).firstOrNull;
    if (friend == null || !mounted) return;
    _say('You and ${friend.name} are friends');
    await _openShelf(friend);
  }

  Future<void> _openShelf(Friend friend) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FriendShelfPage(friend: friend, shelf: widget.shelf),
    ),
  );

  Future<void> _enterCode() => _openInvitation(
    MaterialPageRoute<String>(
      builder: (_) => EnterCodePage(friends: widget.friends),
    ),
  );

  Future<void> _invite() async {
    setState(() => _inviting = true);
    try {
      final invite = await widget.friends.createInvite();
      if (!mounted) return;
      setState(() => _inviting = false);
      await showInviteSheet(context, invite: invite, myName: widget.name.value);
      if (mounted) await _load();
    } catch (e, stack) {
      reportError(e, stack);
      if (!mounted) return;
      setState(() => _inviting = false);
      _say("Couldn't create an invite. Try again.");
    }
  }

  Future<void> _cancel(Invite invite) async {
    try {
      await widget.friends.cancelInvite(invite.code);
      if (mounted) _say('Invite cancelled');
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) _say("Couldn't cancel the invite. Try again.");
    }
    if (mounted) await _load();
  }

  Future<void> _remove(Friend friend) async {
    final sure = await confirm(
      context,
      title: 'Remove ${friend.name}?',
      text:
          "You stop seeing each other's shelves and activity. Albums you "
          'added from ${friend.name} stay on your shelf.',
      cancel: 'Cancel',
      confirm: 'Remove',
      primary: false,
    );
    if (!sure || !mounted) return;
    try {
      await widget.friends.remove(friend.id);
      if (mounted) _say('${friend.name} removed');
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) _say("Couldn't remove ${friend.name}. Try again.");
    }
    if (mounted) await _load();
  }

  Future<void> _changeName() => _root.push(
    MaterialPageRoute<void>(
      builder: (context) => NamePage(
        friends: widget.friends,
        current: widget.name.value,
        onSaved: (saved) {
          widget.name.value = saved;
          Navigator.of(context).pop();
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final inviteKey = ShelfKey(
      primary: true,
      onPressed: _inviting ? null : _invite,
      child: Text(_inviting ? 'Creating invite…' : 'Invite a friend'),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          TextLink(label: 'Enter code', onPressed: _enterCode),
          const SizedBox(width: 12),
        ],
      ),
      body: _failed
          ? Message(
              title: "Couldn't load your friends",
              text: 'Check your connection and try again.',
              actions: [
                ShelfKey(
                  primary: true,
                  onPressed: _load,
                  child: const Text('Try again'),
                ),
              ],
            )
          : list == null
          ? Semantics(
              label: 'Loading your friends',
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: context.shelf.off,
                color: context.shelf.signal,
              ),
            )
          : _content(list, inviteKey),
    );
  }

  Widget _content(FriendsList list, Widget inviteKey) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    Widget section(String label) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(label, style: text.labelSmall!.copyWith(color: c.muted)),
    );
    final empty = list.friends.isEmpty && list.invites.isEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        section('You'),
        ValueListenableBuilder(
          valueListenable: widget.name,
          builder: (context, name, _) => _LinkRow(
            title: name,
            subtitle: "Your name on friends' screens",
            link: TextLink(
              label: 'Change',
              semanticLabel: 'Change your name',
              onPressed: _changeName,
            ),
          ),
        ),
        if (empty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                Text('No friends yet', style: text.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Invite a friend to see their shelf, and they see yours.',
                  style: text.bodyMedium!.copyWith(color: c.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                inviteKey,
                const SizedBox(height: 8),
                TextLink(label: 'Have a code? Enter it', onPressed: _enterCode),
              ],
            ),
          )
        else ...[
          if (list.friends.isNotEmpty) ...[
            section('Friends'),
            for (final friend in list.friends)
              ListRow(
                title: friend.name,
                subtitle: friend.albums == 1
                    ? '1 album'
                    : '${friend.albums} albums',
                onTap: () => _openShelf(friend),
                trailing: PopupMenuButton<void>(
                  tooltip: 'More for ${friend.name}',
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: () => _remove(friend),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ),
          ],
          if (list.invites.isNotEmpty) ...[
            section('Invites waiting'),
            for (final invite in list.invites)
              _LinkRow(
                title: formatCode(invite.code),
                subtitle: '${_expires(invite.expiresAt)} · works once',
                link: TextLink(
                  label: 'Cancel',
                  semanticLabel: 'Cancel invite ${formatCode(invite.code)}',
                  onPressed: () => _cancel(invite),
                ),
              ),
          ],
          Padding(padding: const EdgeInsets.only(top: 24), child: inviteKey),
        ],
      ],
    );
  }
}

String _expires(DateTime at) {
  // A new invite has just under 7 days left: still "7 days".
  final days = (at.difference(DateTime.now()).inMinutes / (24 * 60)).round();
  return switch (days) {
    0 => 'Expires today',
    1 => 'Expires tomorrow',
    _ => 'Expires in $days days',
  };
}

/// A row like [ListRow] with a text link instead of an icon at the end.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    required this.subtitle,
    required this.link,
  });

  final String title, subtitle;
  final Widget link;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                Text(
                  subtitle,
                  style: text.bodySmall!.copyWith(color: context.shelf.muted),
                ),
              ],
            ),
          ),
          link,
        ],
      ),
    );
  }
}
