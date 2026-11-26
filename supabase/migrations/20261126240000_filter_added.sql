-- Filters on when an album was added (TASK-41): in the last N days, or
-- between two dates (each end optional, both inclusive, in the user's
-- days). One kind or the other.
alter table public.shelf_filters
  add column added_within_days integer check (added_within_days between 1 and 3660),
  add column added_from date,
  add column added_to date,
  add check (added_within_days is null or (added_from is null and added_to is null)),
  add check (added_from is null or added_to is null or added_from <= added_to);

grant insert (added_within_days, added_from, added_to),
  update (added_within_days, added_from, added_to)
  on public.shelf_filters to authenticated;

-- A date condition keeps a filter whose last tag went.
create or replace function public.shelf_filters_drop_empty() returns trigger
language plpgsql set search_path = '' as $$
begin
  delete from public.shelf_filters f
  where f.id = old.filter_id
    and f.min_rating is null and not f.unrated and not f.favorite_tracks
    and f.added_within_days is null and f.added_from is null and f.added_to is null
    and not exists (select from public.shelf_filter_tags t where t.filter_id = f.id);
  return old;
end $$;
