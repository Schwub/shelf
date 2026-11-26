-- Friends use each other's filters on a friend's shelf (asked for
-- 2026-11-26): read access like tags and groups. Writing stays owner-only.
-- A filter on a hidden group's tags is left out by the app, as on the
-- owner's own shelf.
create policy "Friends read filters" on public.shelf_filters
  for select to authenticated using (public.is_friend(user_id));
create policy "Friends read filter tags" on public.shelf_filter_tags
  for select to authenticated using (public.is_friend(user_id));
