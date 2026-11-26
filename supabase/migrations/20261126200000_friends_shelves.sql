-- Friends read each other's shelves (TASK-37, docs/features/friends.md),
-- except entries hidden from friends. Added to the owner policies; the app
-- filters its own data by user_id from now on.

alter table public.shelf_entries
  add column hidden boolean not null default false;

create policy "Friends read visible shelf entries" on public.shelf_entries
  for select to authenticated using (public.is_friend(user_id) and not hidden);

create policy "Friends read tags of visible entries" on public.entry_tags
  for select to authenticated using (
    public.is_friend(user_id) and exists (
      select 1 from public.shelf_entries e where e.id = entry_id and not e.hidden));

create policy "Friends read tracks of visible entries" on public.entry_tracks
  for select to authenticated using (
    public.is_friend(user_id) and exists (
      select 1 from public.shelf_entries e where e.id = entry_id and not e.hidden));

-- Names of their tags and groups, to show on their albums; filters stay
-- private.
create policy "Friends read tag groups" on public.tag_groups
  for select to authenticated using (public.is_friend(user_id));
create policy "Friends read tags" on public.tags
  for select to authenticated using (public.is_friend(user_id));

-- Albums friends added by hand, while on an entry the reader may see: the
-- subquery applies shelf_entries' policies, so hidden entries don't count.
drop policy "Signed-in users read catalog albums and their own" on public.albums;
create policy "Signed-in users read catalog albums, their own and friends' visible ones"
  on public.albums for select to authenticated
  using (created_by is null or created_by = (select auth.uid())
         or exists (select 1 from public.shelf_entries e where e.album_id = albums.id));
