import 'package:material_ui/material_ui.dart';

import '../errors.dart';
import '../theme/shelf_colors.dart';
import '../widgets/help_line.dart';
import '../widgets/shelf_field.dart';
import '../widgets/shelf_key.dart';
import 'friends_repository.dart';

const maxNameLength = 40;

/// Set the name friends see: once after the first sign-in ([current] null,
/// no way back), or changed later from Friends.
class NamePage extends StatefulWidget {
  const NamePage({
    super.key,
    required this.friends,
    required this.onSaved,
    this.current,
  });

  final FriendsRepository friends;
  final ValueChanged<String> onSaved;
  final String? current;

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  late final _controller = TextEditingController(text: widget.current);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || name.characters.length > maxNameLength) {
      setState(
        () => _error = name.isEmpty
            ? 'Enter a name friends will recognise.'
            : 'Use at most $maxNameLength characters.',
      );
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.friends.saveName(name);
      if (mounted) widget.onSaved(name);
    } catch (e, stack) {
      reportError(e, stack);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            "Couldn't save your name. Check your connection and try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final first = widget.current == null;
    return Scaffold(
      appBar: first ? null : AppBar(title: const Text('Your name')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, first ? 64 : 24, 20, 20),
          children: [
            if (first) ...[
              Text('What should friends call you?', style: text.headlineSmall),
              const SizedBox(height: 8),
            ],
            Text(
              'Friends see this name on your shelf and in their feed.'
              '${first ? ' You can change it later under Friends.' : ''}',
              style: text.bodyMedium!.copyWith(color: c.muted),
            ),
            const SizedBox(height: 28),
            Text('Your name', style: text.labelSmall!.copyWith(color: c.muted)),
            const SizedBox(height: 8),
            ShelfField(
              controller: _controller,
              hintText: 'First name or nickname',
              autofillHints: const [AutofillHints.givenName],
              autofocus: first,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            HelpLine(
              _error ?? 'Up to $maxNameLength characters',
              error: _error != null,
            ),
            const SizedBox(height: 16),
            ShelfKey(
              primary: true,
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : (first ? 'Continue' : 'Save')),
            ),
          ],
        ),
      ),
    );
  }
}
