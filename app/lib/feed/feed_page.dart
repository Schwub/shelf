import 'package:material_ui/material_ui.dart';

import '../widgets/message.dart';

/// Friends' activity (TASK-38); until then the empty state.
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Feed')),
    body: const Message(
      title: 'See what friends add and rate',
      text: 'Once you have friends, their albums show up here.',
    ),
  );
}
