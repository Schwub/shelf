import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import '../widgets/shelf_key.dart';
import 'shelf.dart';
import 'tag_import.dart';
import 'tag_paths.dart';

/// Check before more than one of the friend's tags is copied
/// (docs/design/wireframes/copy-tags-8.html): [tag], which goes on the
/// album, and the [others] that come along, each with where it comes from
/// and where it lands. Pops true to go ahead.
class TagsCheckPage extends StatelessWidget {
  const TagsCheckPage({
    super.key,
    required this.plan,
    required this.tag,
    required this.others,
  });

  final TagImport plan;
  final Tag tag;
  final List<Tag> others;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  ShelfKey(
                    semanticLabel: 'Back',
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Check', style: text.headlineSmall)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  TagPaths(plan: plan, tag: tag, both: true),
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 4),
                    child: Text(
                      others.length == 1
                          ? '+ 1 MORE TAG, NOT ON THIS ALBUM'
                          : '+ ${others.length} MORE TAGS, NOT ON THIS ALBUM',
                      style: text.labelSmall!.copyWith(color: c.muted),
                    ),
                  ),
                  for (final t in others)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.line)),
                      ),
                      child: TagPaths(plan: plan, tag: t, both: true),
                    ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: ShelfKey(
                  primary: true,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Copy ${others.length + 1} tags'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
