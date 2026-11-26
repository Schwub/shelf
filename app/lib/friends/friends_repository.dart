/// A friend: mutual, from an accepted invite. [albums] counts the albums
/// they don't hide from friends.
typedef Friend = ({String id, String name, int albums});

/// An invite waiting to be used. [code] is stored as 8 characters.
typedef Invite = ({String code, DateTime expiresAt});

/// The user's friends and waiting invites, oldest first.
typedef FriendsList = ({List<Friend> friends, List<Invite> invites});

/// What an invite code is for the signed-in user.
enum InviteStatus {
  valid,

  /// Expired or used.
  gone,
  own,

  /// Already friends with the inviter.
  friends,

  /// No such code, or cancelled.
  unknown,
}

typedef InvitePreview = ({
  InviteStatus status,
  String? inviterId,
  String? inviterName,
});

/// [accept] was refused; [status] says why (never [InviteStatus.valid]).
class InviteFailed implements Exception {
  InviteFailed(this.status);

  final InviteStatus status;
}

/// K7Q2-M9XD: how a code is shown and shared.
String formatCode(String code) =>
    '${code.substring(0, 4)}-${code.substring(4)}';

/// The signed-in user's name, friends and invites
/// (docs/features/friends.md). An interface so the screens can be tested
/// without a server.
abstract class FriendsRepository {
  /// The name friends see; null until the user set one.
  Future<String?> myName();

  /// [name] is trimmed, 1–40 characters.
  Future<void> saveName(String name);

  Future<FriendsList> load();

  Future<Invite> createInvite();

  Future<void> cancelInvite(String code);

  /// [code] as typed: case, spaces and dashes don't matter.
  Future<InvitePreview> preview(String code);

  /// Makes the inviter a friend; throws [InviteFailed] when the code is
  /// gone, unknown, own or already a friend's.
  Future<void> accept(String code);

  /// Ends the friendship for both.
  Future<void> remove(String friendId);
}
