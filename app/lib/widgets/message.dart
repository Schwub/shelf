import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';

/// A centred title, an optional line of text and keys below: what a screen
/// shows when it has nothing else to show (empty, failed, waiting).
class Message extends StatelessWidget {
  const Message({
    super.key,
    required this.title,
    this.text,
    this.actions = const [],
  });

  final String title;
  final String? text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final style = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 96, 28, 24),
      children: [
        Text(title, style: style.titleLarge, textAlign: TextAlign.center),
        if (text != null) ...[
          const SizedBox(height: 8),
          Text(
            text!,
            style: style.bodyMedium!.copyWith(color: c.muted),
            textAlign: TextAlign.center,
          ),
        ],
        for (final (i, action) in actions.indexed) ...[
          SizedBox(height: i == 0 ? 20 : 12),
          Center(child: action),
        ],
      ],
    );
  }
}
