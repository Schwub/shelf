# Tags

Status: data model and schema done; wireframes and visual mockups done; album entry tags built (TASK-16); tag editor built (TASK-17); groups picked from a list (TASK-28); filters built (TASK-18, TASK-32); import built (TASK-19).

Tag editor (TASK-17): `app/lib/tags/` (Tags list, Tag group, tag actions
sheet), reached only from My shelf's ⋮ menu (the album entry's "Edit tags"
link was removed, TASK-29). The database enforces every rule; the app
turns its refusals into the designed messages (`DuplicateName`,
`SeveralTags` in `shelf_repository.dart`) and works out counts and what a delete
takes along from the loaded shelf (`Shelf.allGroups`, `allFilters`).

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
- Album entry: a group shows all its tags as keys, or, picked from a list
  (`pick_from_list`, TASK-28; Genre for new and existing users), only the
  album's tags, each removable. List groups and multiple-choice key groups
  have an "Add" action on their label line: an alphabetical list to scroll
  or search, which can create a tag. A list group stays ordinary tags in an
  ordinary group, so filters, the editor and importing work the same.
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

## A friend's tags, line by line (TASK-51, TASK-52)
Agreed 2026-11-27 after testing the chips of TASK-50 (not flexible
enough) and the copy screens before them (too much at once); wireframe
`docs/design/wireframes/copy-tags-6.html`. One decision per screen.
Background: tag synonyms (Stack Overflow, Discourse), walking up a genre
tree to the nearest known parent (beets `lastgenre`), import wizards
(auto-match, show every pairing, remember, review) and mobile "move to"
pickers (one level at a time, breadcrumb).

Step one (TASK-51, built):
- The album entry has a row "Anna's tags · N on this album · M added"
  with Choose, which opens `FriendTagsPage`
  (`app/lib/shelf/friend_tags_page.dart`).
- The page lists the friend's tags on the album, one per line with its
  full path in the friend's structure, and where it goes in the user's
  tags with the reason: "same place", "same name" (a tag of that name
  elsewhere) or "remembered" (the friend's group goes into a group chosen
  before). Nothing is added until tapped.
- **Add** (the user has it) sets the user's tag with the parent tags it
  needs. **Copy** (they don't) creates the friend's path in the user's
  tags as it is, reusing the parts they have, and sets it. **Use my X**
  (they lack the tag but have a tag above it on the friend's path) sets
  that one instead. "Add the N you have" adds all matches. An added line
  says where it went and has Undo, which takes the tag off the album and
  keeps what was created.
- `TagImport` (`tag_import.dart`): `tags`, `pathOf`, `tagPlace` (with
  `match` and `path`), `nearestAbove`, `add`.

Step two (TASK-52, built): **Map…** on every line opens `MapTagsPage`
(`app/lib/shelf/map_tags_page.dart`), three steps:
1. *What to bring:* the friend's path as a ladder; the starting point is
   one of their groups or tags on it, preselected at the first part the
   user has no place for.
2. *Where it goes:* the user's tags one level per screen (groups, their
   tags, their sub-groups), with a breadcrumb and a search; it opens at
   the user's group most like the friend's. Each level has one action: a
   friend's group joins a group of the user's (its tags go in flat), hangs
   under a tag as a sub-group, or becomes a group of its own at the top; a
   friend's tag goes into a group, or one of the user's tags is used
   instead of it.
3. *Check:* what the mapping does, what it creates, which of the friend's
   tags land on the same tag of the user's, and a switch to bring
   everything below the starting point along (created, not set on the
   album).

- Mapping covers both directions of nesting: a nested tag or sub-group of
  the friend's into a flat group of the user's, and a flat tag into a
  sub-group of theirs.
- `CopyTarget` (`shelf.dart`): `IntoGroup`, `OntoTag`, `UnderTag`,
  `AtTop`. `TagImport.targets` holds them by the friend's group or tag ID;
  a place is worked out from the tag's own target, then targets above it,
  then a tag of the same name, then the friend's structure as it is.
  `chainOf`, `below`, `preview`, `withTarget`; `add` takes several tags.
- Remembered per friend (`ShelfRepository.copyTargets`, `rememberCopy`):
  group targets in `tag_group_destinations` (`group_id` or
  `parent_tag_id`), tag targets in `tag_destinations` (`tag_id` or
  `group_id`). A group of its own is remembered as that group once it
  exists. "Use my X" is remembered as a tag target. Lines that were on and
  go elsewhere after a mapping come off.
- A new mapping replaces what was mapped below its starting point on the
  way to the tag. A tag mapped on its own has **Forget** on its line
  (`forgetCopy`). When a mapping puts a tag into a one-per-album group,
  the list names the tag that came off.
- Not built: a list of all mappings with a friend, to review and remove
  them in one place.

## Copy a friend's tags (TASK-48)
Agreed 2026-11-27; replaces TASK-19's sheet (below); replaced by TASK-51 (above). Wireframes
`docs/design/wireframes/copy-tags.html`.

Reworked the same day: only the album's tags, none ticked, each to any
group or tag of the user's (the wireframes show the first version).

- `app/lib/shelf/copy_tags_page.dart`: "Anna's tags", one row per tag of
  the friend's on the album (in their shown groups, parents first), none
  ticked. Each row shows where it goes ("Genre: Shoegaze", "Genre: new",
  "New group Style"); the picker lists all the user's shown groups,
  built-in ones too, the likely ones first, with their tags, "New “X”
  here" and a new group like the friend's. Picking another group for a
  friend's top-level group remembers it for all its tags; picking another
  tag in the same group is for this album only. "Tick the N that match"
  ticks the rows whose target the user has; nothing is ticked otherwise.
  Ticking a sub-tag ticks its parent; unticking a parent unticks its
  sub-tags. Use N tags applies the ticked rows and returns the tags to set;
  using it again replaces what it set before. Skip and Back set nothing
  but keep the groups chosen; the entry's "See Anna's tags" link opens
  the page again.
- `TagImport` (`tag_import.dart`): `rows`, `suggest(tag)` (a `TagTarget`:
  an existing tag, a new tag in a group, or a new group) from the
  remembered group, else the built-in key, else the same name (a sub-group
  under the target of its parent tag). `apply` creates what is new,
  reusing same-name groups and tags so a retry creates nothing twice, and
  returns the user's shelf and the tags to set, parents included.
- `tag_group_destinations` (migration `20261127090000`): user, friend's
  group, the user's group; owner-only; a row goes with either group. Rows
  with no group (the first version's "Don't copy") are ignored.
  `ShelfRepository.destinations` and `saveDestination`; a failed save
  still applies to this album. `createGroup` returns the new group's ID.

## Import from a friend (TASK-19)
Agreed 2026-11-26. All in the app; considered: one database function for
the copying (atomic, but the sheet needs the matching in Dart anyway, and
copies stay on cancel, so atomicity buys little).

- Rules: built-in groups and tags match by key, others by name ignoring
  case; a sub-group matches under the user's matching parent tag, and a
  missing parent tag is offered too (its sub-tags wait for it). Groups
  hidden by either side are skipped (neither set nor offered). In a group
  of the user's that allows one tag, only the friend's first tag is used.
  A copied new group takes the friend's type and how it shows
  (`exclusive`, `pick_from_list`).
- `app/lib/shelf/tag_import.dart`: `TagImport` plans from the friend's
  shelf, their entry's tags and the user's shelf: `preset` (the user's tag
  IDs to set) and `missing` (each friend's tag with the user's group it
  goes into, or none for a new group). `copy` creates the picked ones with
  `createTag` and `createGroup` in rounds (parents first), reloading the
  user's shelf after each, so a retry after a failure only copies what is
  still missing.
- The sheet (all ticked; Skip, Add N tags; the copy error with Try
  again), replaced by TASK-48's page.
- `EntryPage.add`/`.manual` take `fromFriend` (a `TagImport`): tags
  pre-set, the "set like Anna's" note, "Added from Anna's shelf", and the
  sheet once after the first frame when tags are missing.
  `ShelfRepository.add`/`addManual` take `addedFrom` and write
  `added_from_user_id` and `added_from_name`; `ShelfEntry.addedFromName`
  shows the note on the entry later.
- `Tag.builtin` and `TagGroup.builtin` hold the key (`own`, `collection`).
- Creating tags and groups notifies `ShelfRepository.changes`, so My shelf
  shows copies kept after a cancelled add (accepted: several reloads per
  copy, docs/tech-debt.md). Add plans against a freshly loaded shelf, so a
  second Add after a cancel finds the copies. The sheet can't be closed
  while copying, and a sub-tag is ticked and unticked with its parent.
- The friend's track list is copied without their favorites; without one,
  MusicBrainz's is suggested as for any new album.
- Tests: unit tests for `TagImport` (key, name, sub-groups, type rule,
  hidden groups, copying in rounds and after a failure); widget tests for
  each mockup state with the fake; integration test for `added_from`.

## Data model (option A: group, tag and join tables)
Considered: tag IDs as an array on the entry (rules only via triggers, stale
IDs after deletes) and text labels like `collection:own/vinyl` (renaming
rewrites every item, breaks the editor).

- `tag_groups`: `user_id`, `name`, `exclusive`, `parent_tag_id` (set for a
  sub-group), `builtin`, `position`, `hidden`, `pick_from_list` (how it
  shows on albums). A built-in group is
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
- `shelf_filters` and `shelf_filter_tags`: filters on one tag or combined
  conditions (since TASK-32, docs/features/filters.md). "All" is implicit.
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
