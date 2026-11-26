import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/message.dart';
import '../widgets/shelf_key.dart';
import 'friends_repository.dart';
import 'name_page.dart';

/// Shows Your name until the signed-in user has one, then [builder] with
/// the name, which later changes update.
class NameGate extends StatefulWidget {
  const NameGate({super.key, required this.friends, required this.builder});

  final FriendsRepository friends;
  final Widget Function(BuildContext context, ValueNotifier<String> name)
  builder;

  @override
  State<NameGate> createState() => _NameGateState();
}

class _NameGateState extends State<NameGate> {
  ValueNotifier<String>? _name;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final name = await widget.friends.myName();
      if (!mounted) return;
      setState(() {
        _loaded = true;
        if (name != null) _name = ValueNotifier(name);
      });
    } catch (e, stack) {
      reportError(e, stack);
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _name;
    if (name != null) return widget.builder(context, name);
    if (_failed) {
      return Scaffold(
        body: Message(
          title: "Couldn't load your account",
          text: 'Check your connection and try again.',
          actions: [
            ShelfKey(
              primary: true,
              onPressed: _load,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (!_loaded) {
      return Scaffold(
        body: Semantics(
          label: 'Loading',
          child: LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: context.shelf.off,
            color: context.shelf.signal,
          ),
        ),
      );
    }
    return NamePage(
      friends: widget.friends,
      onSaved: (saved) => setState(() => _name = ValueNotifier(saved)),
    );
  }
}
