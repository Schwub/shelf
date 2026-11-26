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
- **Added** (TASK-41): in the last 7, 30 or 90 days or the last year, or
  between two days from the date range picker (both included, in the
  user's time zone); tapping the chosen one again clears it.

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
  tracks, Added, and a live "Matches N albums". It needs at least one condition,
  and a name unless it's a single tag. Delete filter for existing ones.

## Data
Migration `20261126150000_custom_filters.sql`: `shelf_filters` (id, name,
position, `tags_match`, `min_rating`, `unrated`, `favorite_tracks`) and
`shelf_filter_tags`. Written by the owner only. Deleting a tag removes it from filters; a
filter left with no condition is deleted by a trigger, so the app adds a
filter's new tags before removing old ones. The old one-tag filters were
converted in place. `20261126240000_filter_added.sql` adds
`added_within_days` or `added_from`/`added_to` (dates; one kind only, a
range runs forwards), which also keep a filter whose last tag went.
Friends read each other's filters (`20261126230000_friends_filters.sql`).
pgTAP: `supabase/tests/filters_test.sql`.

## Later
Year ranges and other album properties as more columns.
