# Tags

Status: data model and schema done (56 pgTAP checks); wireframes and visual mockups done; screens not built (TASK-16 to TASK-19).

## Goal
One tag system for every media type. Tags live in groups; a group is
exclusive (one tag per item) or multiple choice, and a tag can open a
sub-group (Own → Format). New users start with suggested groups and can
change everything. Two built-in groups, Collection and Listening, exist for
everyone so friends' shelves stay comparable; they can be renamed and hidden
but not deleted. The shelf's filter bar shows tags the user picks in the
menu.

## Acceptance criteria
1. Schema: `tag_groups`, `tags` and `entry_tags` replace the `listening`,
   `owning` and `formats` columns of `shelf_entries`. The database enforces:
   each user's tags are private; one tag per exclusive group on an item; a
   sub-tag needs its parent tag on the same item; built-in groups and their
   tags can't be deleted, and built-in groups stay exclusive. Items need no
   tags.
2. Suggested groups: new users get Collection (Want / Own, with Format:
   Vinyl, CD, Tape, File under Own), Listening (Want to listen / Listened)
   and Genre (empty, multiple choice); the filter bar starts with Own, Want,
   Want to listen and Listened.
3. pgTAP tests cover 1 and 2.
4. Wireframes and visual mockups: the album entry built from the user's
   groups; the full tag editor (create, rename, delete groups; exclusive or
   multiple; sub-groups under a tag; add, rename, reorder, delete tags; hide
   built-in groups); choosing filters in the shelf menu (the filter bar
   scrolls after five); the prompt to import missing tags when adding an
   album from a friend (M2).
5. `docs/architecture.md` decision, this note, and backlog tasks for the
   app work.

## Decisions
- No tag is required on an item.
- Full tag editor in M1.
- Filter bar: any number of filters; it scrolls sideways after five.
- Built-in groups are shared in meaning, not in data: every user has their
  own rows, marked with a `builtin` key (`collection`, `listening`) and
  built-in tags (`want`, `own`, `want_to_listen`, `listened`). Friends'
  shelves compare on these keys, so renaming "Own" to "Have" changes nothing
  for others.
- Importing from a friend (M2): built-in tags match by key and are never
  asked about. Other tags match by group and tag name; for missing ones the
  app asks (all, pick, or skip) and creates copies in the user's own groups.
  Copies have no link back and are freely editable. The album itself
  remembers whose shelf it came from (`added_from_user_id`, and
  `added_from_name` kept as it was, so "Added from Anna's shelf" stays
  after Anna's account is deleted).
- Album entry: groups with up to six tags show them all as keys;
  multiple-choice groups have an "Add" action on their label line, which
  searches and can create a tag. "Edit tags" opens the Tags list and keeps the album draft.
- Editor: changes save immediately; deletes ask first (with the albums,
  sub-groups and filters affected) and take effect at once. Sub-groups go
  one level deep in the editor (the model allows deeper). Only built-in
  groups can be hidden (enforced by a check constraint); hidden groups'
  tags leave the album entry, the filter bar and the filter picker.
- Import: a copied new group takes the friend's type; copies stay if the
  album add is cancelled.
- Rating and comment stay columns on `shelf_entries`; rating is not a tag.
- Tags attach to the shelf entry, so the model works for any media type.
  Different suggested sets per media type (books: Read / To read) come with
  the second media type.

## Data model (option A: group, tag and join tables)
Considered: tag IDs as an array on the entry (rules only via triggers, stale
IDs after deletes) and text labels like `collection:own/vinyl` (renaming
rewrites every item, breaks the editor).

- `tag_groups`: `user_id`, `name`, `exclusive`, `parent_tag_id` (set for a
  sub-group), `builtin`, `position`, `hidden`. A built-in group is
  top-level and exclusive.
- `tags`: `user_id`, `group_id`, `name` (unique per group, case-insensitive),
  `builtin`, `position`.
- `entry_tags`: `entry_id`, `tag_id`, `user_id`, plus `group_id` and
  `exclusive`, filled by a trigger from the tag and kept in step with the
  group by a cascading foreign key. A partial unique index on
  (`entry_id`, `group_id`) where `exclusive` allows one tag per exclusive
  group; making a group exclusive fails while an item has two of its tags.
- Composite foreign keys on (`id`, `user_id`) make sure a tag, its group,
  the entry and the filter all belong to the same user.
- Sub-tags: a trigger rejects a tag whose group hangs under a parent tag the
  entry doesn't have, and removing a tag from an entry also removes its
  sub-tags.
- `shelf_filters`: `user_id`, `tag_id`, `position`. "All" is implicit.
- Clients can't set `builtin`, `user_id` or move a tag to another group:
  column privileges allow only the editable columns.
- A trigger on new users (security definer) creates the suggested groups and
  filters.
- Row-level security on every table: owner only, as today. Friends' read
  access comes in M2.

## Plan
1. Migration and pgTAP tests. Done.
2. Wireframes (`docs/design/wireframes/`: album-entry, tags, filters,
   import-tags) and visual mockups (`docs/design/visual/screens/`: entry,
   tags, filters, import). Done.
3. Screens: TASK-16 (album entry tags), TASK-17 (tag editor), TASK-18
   (filters), TASK-19 (import, M2). They need TASK-14 (theme) and TASK-6
   (sign-in).
