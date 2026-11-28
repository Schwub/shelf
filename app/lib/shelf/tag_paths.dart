import 'package:material_ui/material_ui.dart';

import '../theme/shelf_colors.dart';
import 'shelf.dart';
import 'path_bar.dart';
import 'tag_import.dart';

/// Where one of the friend's tags comes from and where it lands
/// (docs/design/wireframes/copy-tags-8.html): the friend's path (FROM) and
/// the path in the user's tags (TO), or one bar when they are the same and
/// nothing is new.
class TagPaths extends StatelessWidget {
  const TagPaths({
    super.key,
    required this.plan,
    required this.tag,
    this.marked,
    this.both = false,
  });

  final TagImport plan;

  /// The friend's tag.
  final Tag tag;

  /// The friend's group or tag being changed: filled in on both bars.
  final Start? marked;

  /// Always two bars, even when the paths are the same.
  final bool both;

  @override
  Widget build(BuildContext context) {
    final c = context.shelf;
    final text = Theme.of(context).textTheme;
    final from = plan.chainOf(tag);
    final at = marked == null ? -1 : from.indexOf(marked!);
    final to = [
      for (final part in plan.toPath(tag))
        PathPart(part.name, isNew: part.isNew, on: part.start == marked),
    ];
    final names = [for (final s in from) (s.group?.name ?? s.tag?.name)!];
    final same =
        !both &&
        names.length == to.length &&
        !to.any((p) => p.isNew) &&
        [
          for (final (i, p) in to.indexed)
            p.name.toLowerCase() == names[i].toLowerCase(),
        ].every((x) => x);
    if (same) {
      return PathBar(
        parts: to,
        trailing: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            '= mine',
            style: text.bodySmall!.copyWith(color: c.muted),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PathBar(
          label: 'FROM',
          parts: [
            for (final (i, name) in names.indexed)
              PathPart(name, on: i == at, dim: i < at),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 58),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.arrow_downward, size: 14, color: c.muted),
          ),
        ),
        PathBar(label: 'TO', parts: to),
      ],
    );
  }
}
