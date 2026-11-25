-- Each user's own track list of an album on their shelf (TASK-27): typed in,
-- or a MusicBrainz list they approved, with their favorites marked on it
-- (docs/features/tracks.md). Not part of the shared catalog.
create table public.entry_tracks (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid not null,
  user_id uuid not null default auth.uid(),
  disc integer not null default 1 check (disc >= 1),
  position integer not null check (position >= 1),
  title text not null check (btrim(title) <> ''),
  length_ms integer check (length_ms > 0),
  favorite boolean not null default false,
  -- The entry must be the user's own.
  foreign key (entry_id, user_id) references public.shelf_entries (id, user_id) on delete cascade,
  unique (entry_id, disc, position)
);

-- Clients replace a whole list with set_entry_tracks; user_id comes from the
-- default.
revoke insert, update on public.entry_tracks from anon, authenticated;
grant insert (entry_id, disc, position, title, length_ms, favorite)
  on public.entry_tracks to authenticated;

alter table public.entry_tracks enable row level security;
create policy "Users read their own tracks" on public.entry_tracks
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users add their own tracks" on public.entry_tracks
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users delete their own tracks" on public.entry_tracks
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Replaces the entry's track list in one transaction, so a failed save
-- leaves the old list. [tracks]: [{disc, position, title, length_ms,
-- favorite}]. Runs as the caller, so row-level security applies.
create function public.set_entry_tracks(entry uuid, tracks jsonb) returns void
  language sql security invoker set search_path = ''
as $$
  delete from public.entry_tracks where entry_id = entry;
  insert into public.entry_tracks (entry_id, disc, position, title, length_ms, favorite)
  select entry, t.disc, t.position, t.title, t.length_ms, coalesce(t.favorite, false)
  from jsonb_to_recordset(tracks)
    as t(disc integer, position integer, title text, length_ms integer, favorite boolean);
$$;
revoke execute on function public.set_entry_tracks(uuid, jsonb) from public, anon;
grant execute on function public.set_entry_tracks(uuid, jsonb) to authenticated;
