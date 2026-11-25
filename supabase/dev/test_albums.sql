-- Test albums for one account's shelf (local development and staging),
-- until albums can be added in the app (TASK-8). Run with
-- `mise run dev:albums -- <email>`; the account must have signed in once.
-- Safe to run again: albums and entries that exist are left alone.
do $$
declare
  account uuid := (select id from auth.users where email = '__EMAIL__');
begin
  if account is null then
    raise exception 'No account for __EMAIL__: sign in once in the app first.';
  end if;

  insert into public.albums (title, artist, year)
  select * from (values
    ('OK Computer', 'Radiohead', 1997),
    ('Discovery', 'Daft Punk', 2001),
    ('To Pimp a Butterfly', 'Kendrick Lamar', 2015),
    ('Blue', 'Joni Mitchell', 1971),
    ('Lift Your Skinny Fists Like Antennas to Heaven', 'Godspeed You! Black Emperor', 2000),
    ('Promises', 'Floating Points, Pharoah Sanders & LSO', 2021),
    ('Hounds of Love', 'Kate Bush', 1985),
    ('Ágætis byrjun', 'Sigur Rós', 1999),
    ('Remain in Light', 'Talking Heads', 1980)
  ) as a (title, artist, year)
  where not exists (
    select from public.albums b where b.title = a.title and b.artist = a.artist
  );

  -- Rating in half stars, and the built-in tags to mark it with.
  insert into public.shelf_entries (user_id, album_id, rating)
  select account, b.id, s.rating
  from (values
    ('OK Computer', 9), ('Discovery', 8), ('To Pimp a Butterfly', null),
    ('Blue', 10), ('Lift Your Skinny Fists Like Antennas to Heaven', 7),
    ('Promises', null), ('Hounds of Love', 10), ('Ágætis byrjun', 8),
    ('Remain in Light', 9)
  ) as s (title, rating)
  join public.albums b on b.title = s.title
  on conflict (user_id, album_id) do nothing;

  insert into public.entry_tags (entry_id, tag_id, user_id)
  select e.id, t.id, account
  from (values
    ('OK Computer', 'own'), ('OK Computer', 'listened'),
    ('Discovery', 'own'), ('Discovery', 'listened'),
    ('To Pimp a Butterfly', 'want'), ('To Pimp a Butterfly', 'want_to_listen'),
    ('Blue', 'own'), ('Blue', 'listened'),
    ('Promises', 'want_to_listen'),
    ('Hounds of Love', 'own'), ('Hounds of Love', 'listened'),
    ('Ágætis byrjun', 'listened'), ('Remain in Light', 'own')
  ) as s (title, builtin)
  join public.albums b on b.title = s.title
  join public.shelf_entries e on e.album_id = b.id and e.user_id = account
  join public.tags t on t.user_id = account and t.builtin = s.builtin
  on conflict do nothing;
end $$;
