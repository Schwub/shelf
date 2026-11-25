-- Albums added by hand (TASK-26): no MusicBrainz ID, created_by the user,
-- visible only to them (friends' shelves come in M2). The add-album
-- function inserts them, as all albums (docs/features/search.md).
alter table public.albums
  add column created_by uuid references auth.users on delete cascade,
  -- Not both; older test albums have neither.
  add check (musicbrainz_id is null or created_by is null);
create index on public.albums (created_by);

drop policy "Signed-in users read albums" on public.albums;
create policy "Signed-in users read catalog albums and their own"
  on public.albums for select to authenticated
  using (created_by is null or created_by = auth.uid());
