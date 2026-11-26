-- A test friend for one account (local development and staging): "Testa",
-- with eight albums, ratings, tags and favorite tracks added over the past
-- week, so the Friends tab, a friend's shelf and the feed have something to
-- show. One album is hidden from friends. Run with
-- `mise run dev:friend -- <email>`; the account must have signed in once.
-- Safe to run again: what exists is left alone.
do $$
declare
  account uuid := (select id from auth.users where email = '__EMAIL__');
  friend uuid := (select id from auth.users where email = 'testa@shelf.invalid');
begin
  if account is null then
    raise exception 'No account for __EMAIL__: sign in once in the app first.';
  end if;

  -- The friend's account; it never signs in (.invalid can't get mail).
  if friend is null then
    friend := gen_random_uuid();
    insert into auth.users (id, instance_id, aud, role, email, email_confirmed_at)
    values (friend, '00000000-0000-0000-0000-000000000000', 'authenticated',
            'authenticated', 'testa@shelf.invalid', now());
  end if;
  insert into public.profiles (user_id, name) values (friend, 'Testa')
    on conflict (user_id) do nothing;
  insert into public.friendships (user_id, friend_id)
    values (account, friend), (friend, account)
    on conflict do nothing;

  insert into public.albums (title, artist, year, created_by)
  select a.*, friend from (values
    ('In Rainbows', 'Radiohead', 2007),
    ('Blonde', 'Frank Ocean', 2016),
    ('Homogenic', 'Björk', 1997),
    ('Kind of Blue', 'Miles Davis', 1959),
    ('Spirit of Eden', 'Talk Talk', 1988),
    ('Selected Ambient Works 85–92', 'Aphex Twin', 1992),
    ('Hounds of Love', 'Kate Bush', 1985),
    ('Guilty Pleasures', 'Testa', 2024)
  ) as a (title, artist, year)
  where not exists (
    select from public.albums b
    where b.title = a.title and b.artist = a.artist and b.created_by = friend
  );

  -- When each was added and rated (hours ago), so the feed has an order:
  -- some rated when added, some later, some not at all.
  insert into public.shelf_entries (user_id, album_id, rating, comment, hidden)
  select friend, b.id, s.rating, s.comment, s.hidden
  from (values
    ('In Rainbows', 10, 'Reckoner on repeat.', false),
    ('Blonde', 9, null, false),
    ('Homogenic', 8, null, false),
    ('Kind of Blue', null, null, false),
    ('Spirit of Eden', 9, 'Headphones, dark room.', false),
    ('Selected Ambient Works 85–92', 7, null, false),
    ('Hounds of Love', 10, null, false),
    ('Guilty Pleasures', 3, 'Nobody needs to know.', true)
  ) as s (title, rating, comment, hidden)
  join public.albums b on b.title = s.title and b.created_by = friend
  on conflict (user_id, album_id) do nothing;

  update public.shelf_entries e
  set created_at = now() - make_interval(hours => s.added),
      rated_at = case when e.rating is null then null
                      else now() - make_interval(hours => s.rated) end
  from (values
    ('In Rainbows', 150, 3),
    ('Blonde', 120, 120),
    ('Homogenic', 96, 30),
    ('Kind of Blue', 72, 0),
    ('Spirit of Eden', 50, 50),
    ('Selected Ambient Works 85–92', 26, 6),
    ('Hounds of Love', 5, 5),
    ('Guilty Pleasures', 2, 2)
  ) as s (title, added, rated)
  join public.albums b on b.title = s.title and b.created_by = friend
  where e.album_id = b.id and e.user_id = friend
    and e.created_at > now() - interval '1 minute';  -- only when just added

  insert into public.entry_tags (entry_id, tag_id, user_id)
  select e.id, t.id, friend
  from (values
    ('In Rainbows', 'own'), ('In Rainbows', 'listened'),
    ('Blonde', 'listened'), ('Homogenic', 'own'), ('Homogenic', 'listened'),
    ('Kind of Blue', 'want_to_listen'), ('Spirit of Eden', 'listened'),
    ('Selected Ambient Works 85–92', 'want'), ('Hounds of Love', 'own'),
    ('Hounds of Love', 'listened')
  ) as s (title, builtin)
  join public.albums b on b.title = s.title and b.created_by = friend
  join public.shelf_entries e on e.album_id = b.id and e.user_id = friend
  join public.tags t on t.user_id = friend and t.builtin = s.builtin
  on conflict do nothing;

  insert into public.entry_tracks (entry_id, user_id, position, title, favorite)
  select e.id, friend, s.position, s.track, s.favorite
  from (values
    ('In Rainbows', 1, '15 Step', false),
    ('In Rainbows', 2, 'Bodysnatchers', false),
    ('In Rainbows', 3, 'Nude', true),
    ('In Rainbows', 7, 'Reckoner', true)
  ) as s (title, position, track, favorite)
  join public.albums b on b.title = s.title and b.created_by = friend
  join public.shelf_entries e on e.album_id = b.id and e.user_id = friend
  on conflict do nothing;
end $$;
