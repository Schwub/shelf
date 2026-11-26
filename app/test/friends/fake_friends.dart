import 'package:shelf_app/friends/friends_repository.dart';

/// A name kept in memory; [error] makes the next call fail.
class FakeFriends implements FriendsRepository {
  FakeFriends([this.name]);

  String? name;
  Object? error;

  Future<void> _fail() async {
    final e = error;
    error = null;
    if (e != null) throw e;
  }

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
}
