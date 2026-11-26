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

  -- Added as the account's own albums (no MusicBrainz ID).
  insert into public.albums (title, artist, year, created_by)
  select a.*, account from (values
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
    select from public.albums b
    where b.title = a.title and b.artist = a.artist and b.created_by = account
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
  join public.albums b on b.title = s.title and b.created_by = account
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
  join public.albums b on b.title = s.title and b.created_by = account
  join public.shelf_entries e on e.album_id = b.id and e.user_id = account
  join public.tags t on t.user_id = account and t.builtin = s.builtin
  on conflict do nothing;

  -- A group of the account's own, next to the suggested ones.
  insert into public.tag_groups (user_id, name, exclusive, position)
  select account, 'Mood', false, 10
  where not exists (
    select from public.tag_groups where user_id = account and name = 'Mood'
  );

  -- Genres, moods and formats: tags in the account's groups (Format is
  -- the sub-group under Own).
  insert into public.tags (user_id, group_id, name, position)
  select account, g.id, s.tag, s.position
  from (values
    ('Genre', 'Art rock', 0), ('Genre', 'Electronic', 1),
    ('Genre', 'Hip hop', 2), ('Genre', 'Folk', 3), ('Genre', 'Post-rock', 4),
    ('Genre', 'Jazz', 5), ('Genre', 'Ambient', 6), ('Genre', 'New wave', 7),
    ('Mood', 'Late night', 0), ('Mood', 'Rainy day', 1),
    ('Mood', 'Road trip', 2)
  ) as s (grp, tag, position)
  join public.tag_groups g on g.user_id = account and g.name = s.grp
  where not exists (
    select from public.tags t where t.group_id = g.id and t.name = s.tag
  );

  -- Parent tags (Own) are on already, so the formats can follow.
  insert into public.entry_tags (entry_id, tag_id, user_id)
  select e.id, t.id, account
  from (values
    ('OK Computer', 'Genre', 'Art rock'), ('OK Computer', 'Format', 'Vinyl'),
    ('OK Computer', 'Mood', 'Rainy day'),
    ('Discovery', 'Genre', 'Electronic'), ('Discovery', 'Format', 'CD'),
    ('Discovery', 'Mood', 'Road trip'),
    ('To Pimp a Butterfly', 'Genre', 'Hip hop'),
    ('To Pimp a Butterfly', 'Genre', 'Jazz'),
    ('Blue', 'Genre', 'Folk'), ('Blue', 'Format', 'Vinyl'),
    ('Blue', 'Mood', 'Rainy day'),
    ('Lift Your Skinny Fists Like Antennas to Heaven', 'Genre', 'Post-rock'),
    ('Lift Your Skinny Fists Like Antennas to Heaven', 'Mood', 'Late night'),
    ('Promises', 'Genre', 'Jazz'), ('Promises', 'Genre', 'Ambient'),
    ('Hounds of Love', 'Genre', 'Art rock'), ('Hounds of Love', 'Format', 'Vinyl'),
    ('Ágætis byrjun', 'Genre', 'Post-rock'), ('Ágætis byrjun', 'Genre', 'Ambient'),
    ('Ágætis byrjun', 'Mood', 'Late night'),
    ('Remain in Light', 'Genre', 'New wave'), ('Remain in Light', 'Format', 'CD')
  ) as s (title, grp, tag)
  join public.albums b on b.title = s.title and b.created_by = account
  join public.shelf_entries e on e.album_id = b.id and e.user_id = account
  join public.tag_groups g on g.user_id = account and g.name = s.grp
  join public.tags t on t.group_id = g.id and t.name = s.tag
  on conflict do nothing;

  update public.shelf_entries e set comment = s.comment
  from (values
    ('OK Computer', 'Paranoid Android still sounds like the future.'),
    ('Blue', 'A Case of You, every winter.'),
    ('Hounds of Love', 'Side two is a film without pictures.'),
    ('Ágætis byrjun', 'For the train home in the dark.')
  ) as s (title, comment)
  join public.albums b on b.title = s.title and b.created_by = account
  where e.album_id = b.id and e.user_id = account and e.comment is null;
end $$;
