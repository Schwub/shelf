import 'package:shelf_app/friends/friends_repository.dart';

/// Name, friends and invites kept in memory; [codes] are invites others
/// sent. [error] makes the next call fail, [loadError] the next [load].
class FakeFriends implements FriendsRepository {
  FakeFriends([this.name]);

  String? name;
  Object? error, loadError;
  final friends = <Friend>[];
  final invites = <Invite>[];
  final codes = <String, InvitePreview>{};
  var _created = 0;

  Future<void> _fail() async {
    final e = error;
    error = null;
    if (e != null) throw e;
  }

  static String _clean(String code) =>
      code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  @override
  Future<String?> myName() async {
    await _fail();
    return name;
  }

  @override
  Future<void> saveName(String name) async {
    await _fail();
    this.name = name;
  }

  @override
  Future<FriendsList> load() async {
    await _fail();
    final e = loadError;
    loadError = null;
    if (e != null) throw e;
    return (friends: [...friends], invites: [...invites]);
  }

  @override
  Future<Invite> createInvite() async {
    await _fail();
    final invite = (
      code: 'K7Q2M9X${'ABCDEFGH'[_created++]}',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    invites.add(invite);
    return invite;
  }

  @override
  Future<void> cancelInvite(String code) async {
    await _fail();
    invites.removeWhere((i) => i.code == code);
  }

  @override
  Future<InvitePreview> preview(String code) async {
    await _fail();
    return codes[_clean(code)] ??
        (status: InviteStatus.unknown, inviterId: null, inviterName: null);
  }

  @override
  Future<void> accept(String code) async {
    final preview = await this.preview(code);
    if (preview.status != InviteStatus.valid) {
      throw InviteFailed(preview.status);
    }
    friends.add((
      id: preview.inviterId!,
      name: preview.inviterName!,
      albums: 0,
    ));
    codes[_clean(code)] = (
      status: InviteStatus.friends,
      inviterId: preview.inviterId,
      inviterName: preview.inviterName,
    );
  }

  @override
  Future<void> remove(String friendId) async {
    await _fail();
    friends.removeWhere((f) => f.id == friendId);
  }
}
