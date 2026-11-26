-- The feed (TASK-38, docs/features/friends.md): friends' albums added and
-- ratings set or changed, newest first. A view over shelf_entries, so
-- row-level security decides what each reader sees and hiding an entry
-- hides its items.

alter table public.shelf_entries add column rated_at timestamptz;

-- When the rating last changed; null without a rating.
create function public.shelf_entries_rated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' or new.rating is distinct from old.rating then
    new.rated_at := case when new.rating is null then null else now() end;
  end if;
  return new;
end;
$$;
create trigger shelf_entries_rated_at
  before insert or update on public.shelf_entries
  for each row execute function public.shelf_entries_rated_at();

-- The feed orders by created_at and rated_at, so only the database sets
-- them (and updated_at); user_id comes from its default.
revoke insert, update on public.shelf_entries from anon, authenticated;
grant insert (id, album_id, rating, comment, hidden, added_from_user_id, added_from_name),
  update (rating, comment, hidden)
  on public.shelf_entries to authenticated;

create index on public.shelf_entries (user_id, created_at);
create index on public.shelf_entries (user_id, rated_at);

-- An album added with a rating is one item ("added", with the rating); a
-- rating set later is its own item, and a newer rating replaces it.
create view public.feed with (security_invoker = true) as
  select e.id as entry_id, e.user_id, 'added' as kind, e.created_at as at,
         e.rating, e.album_id, a.musicbrainz_id, a.title, a.artist, a.year,
         a.cover_url, p.name
    from public.shelf_entries e
    join public.albums a on a.id = e.album_id
    join public.profiles p on p.user_id = e.user_id
    where e.user_id <> (select auth.uid())
  union all
  select e.id, e.user_id, 'rated', e.rated_at,
         e.rating, e.album_id, a.musicbrainz_id, a.title, a.artist, a.year,
         a.cover_url, p.name
    from public.shelf_entries e
    join public.albums a on a.id = e.album_id
    join public.profiles p on p.user_id = e.user_id
    where e.user_id <> (select auth.uid()) and e.rated_at > e.created_at;

revoke all on public.feed from anon;
grant select on public.feed to authenticated;
