-- How My shelf (and friends' shelves) are sorted (TASK-39): an order, and
-- `_reversed` for the other direction. Null is the app's default (date
-- added, newest first).
alter table public.user_settings
  add column shelf_sort text check (shelf_sort in (
    'added', 'added_reversed', 'title', 'title_reversed',
    'artist', 'artist_reversed', 'year', 'year_reversed',
    'rating', 'rating_reversed'
  ));

grant insert (shelf_sort), update (shelf_sort)
  on public.user_settings to authenticated;
