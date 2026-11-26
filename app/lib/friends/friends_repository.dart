/// The signed-in user's name and, from TASK-36, their friends and invites
/// (docs/features/friends.md). An interface so the screens can be tested
/// without a server.
abstract class FriendsRepository {
  /// The name friends see; null until the user set one.
  Future<String?> myName();

  /// [name] is trimmed, 1–40 characters.
  Future<void> saveName(String name);
}
