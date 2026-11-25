# Filters (TASK-18, TASK-32)

Status: built 2026-11-25.

## Goal
Find albums on the shelf quickly: the filter bar on My shelf shows "All"
and the user's filters in their order. A filter is one tag (Own, Vinyl …)
or a custom one combining conditions.

## Conditions
- **Tags:** any of them or all of them.
- **Rating:** at least N stars (half stars, like ratings), or unrated.
- **Favorite tracks:** albums with at least one starred track.

A filter with one tag and nothing else shows the tag's name and follows its
renames; others carry their own name. A filter's tags must all be shown:
hiding a group hides its filters. Matching happens in the app on the loaded
shelf (`ShelfFilter.matches`).

## Screens
- **Filters** (⋮ → Filters, design `docs/design/visual/screens/filters.html`):
  All first ("Always first"), then the filters with a line saying what they
  match ("Collection" for a tag, "Own and Vinyl · 4 stars and up" for a
  custom one), drag to reorder, ✕ to remove, Add filter. Changes save at
  once.
- **Add filter:** the tags by group (those with a filter ticked), and
  "Custom filter…" on top.
- **Filter editor** (custom filters, and tapping any filter): name, tags with
  Add and Any/All, rating keys for the minimum or Unrated, Has favorite
  tracks, and a live "Matches N albums". It needs at least one condition,
  and a name unless it's a single tag. Delete filter for existing ones.

## Data
Migration `20261126150000_custom_filters.sql`: `shelf_filters` (id, name,
position, `tags_match`, `min_rating`, `unrated`, `favorite_tracks`) and
`shelf_filter_tags`. Owner-only. Deleting a tag removes it from filters; a
filter left with no condition is deleted by a trigger, so the app adds a
filter's new tags before removing old ones. The old one-tag filters were
converted in place. pgTAP: `supabase/tests/filters_test.sql`.

## Later
Year ranges and other album properties as more columns.
