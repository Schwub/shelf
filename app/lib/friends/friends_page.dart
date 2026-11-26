import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/text_link.dart';
import 'friends_repository.dart';
import 'name_page.dart';

/// Your name and, from TASK-36, your friends and invites.
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key, required this.friends, required this.name});

  final FriendsRepository friends;
  final ValueNotifier<String> name;

  // Full screen, over the navigation bar.
  Future<void> _changeName(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (context) => NamePage(
            friends: friends,
            current: name.value,
            onSaved: (saved) {
              name.value = saved;
              Navigator.of(context).pop();
            },
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text('You', style: text.labelSmall!.copyWith(color: c.muted)),
          const SizedBox(height: 4),
          ValueListenableBuilder(
            valueListenable: name,
            builder: (context, value, _) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: text.titleMedium),
                      Text(
                        "Your name on friends' screens",
                        style: text.bodySmall!.copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
                TextLink(
                  label: 'Change',
                  semanticLabel: 'Change your name',
                  onPressed: () => _changeName(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'No friends yet',
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Inviting friends comes next.',
            style: text.bodyMedium!.copyWith(color: c.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
