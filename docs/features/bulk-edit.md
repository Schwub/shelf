# Edit several albums at once (TASK-40)

Status: built 2026-11-26.

UX: flow "Edit several albums" in [../design/flows.md](../design/flows.md),
wireframes [select](../design/wireframes/select.html). Agreed 2026-11-26.

## Acceptance criteria
1. Albums can be selected on My shelf (⋮ → Select albums, or press and
   hold one) and the selection cleared (✕, back, Select none).
2. Tags go on and come off all selected albums, following the one-per-group
   and sub-tag rules.
3. Selected albums can be hidden from or shown to friends and removed
   together, with Undo.
4. Wireframes and widget tests for each action.

## Design
Considered: a database function per action (all-or-nothing). None of the
actions needs that, so the app does it with a few queries.

- `app/lib/shelf/bulk_tags.dart`: `BulkTags`, plain Dart. Per tag: on all,
  some or none of the selection (with counts), `toggle` with the rules of
  one album (a tag in a one-per-album group takes the others off, a
  sub-tag puts its parent on, a tag taken off takes its sub-tags), and
  `changes`: tags to remove, then to add, parents first.
- `ShelfRepository`: `changeTags(ids, remove:, add:)` (one delete, then one
  insert per tag, so the database sees parents first), `hide(ids, hidden)`
  (one update), `remove(ids)` (replaces the one-album remove).
- `shelf_page.dart`: `_selected` (null when not selecting) swaps the header
  for "n selected", ✕ and Select all/none (the albums in the current
  filter), and the bottom row for `SelectionBar` (Tags, Hide or Show,
  Remove). Tapping an album selects it; `CoversView` and `AlbumsListView`
  take `selected` and `onHold`. Back ends selecting.
- `bulk_tags_sheet.dart`: every visible group; groups picked from a list
  show only the tags some selected album has, plus Add (the usual tag
  sheet). Apply runs `changeTags`; the selection stays.
- Hide and tags report "Couldn't change n albums" with Try again; Hide
  offers Undo for the albums it changed. Remove uses My shelf's removal
  with Undo and ends selecting.

## Tests
- Unit: `bulk_tags_test.dart` (states, one per album, sub-tags, off again).
- Widget: `shelf_page_test.dart`, group "selecting several albums".
- Integration: "several albums at once".

## Later
Rating several albums, export, selecting on a friend's shelf.
