begin;
select plan(8);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');
insert into public.albums (id, title, artist) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'OK Computer', 'Radiohead');
insert into public.shelf_entries (id, user_id, album_id) values
  ('a1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('b2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222',
   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select lives_ok(
  $$select public.set_entry_tracks('a1111111-1111-1111-1111-111111111111',
    '[{"disc": 1, "position": 1, "title": "Airbag", "length_ms": 284000},
      {"disc": 1, "position": 2, "title": "Paranoid Android", "favorite": true}]')$$,
  'users set the track list of their own entry');
select results_eq(
  $$select title, favorite from public.entry_tracks order by position$$,
  $$values ('Airbag', false), ('Paranoid Android', true)$$,
  'with titles and favorites in order');
select lives_ok(
  $$select public.set_entry_tracks('a1111111-1111-1111-1111-111111111111',
    '[{"disc": 1, "position": 1, "title": "Airbag", "favorite": true}]')$$,
  'setting it again replaces the list');
select results_eq(
  $$select count(*)::int from public.entry_tracks$$, array[1],
  'only the new list is left');
select throws_ok(
  $$select public.set_entry_tracks('a1111111-1111-1111-1111-111111111111',
    '[{"disc": 1, "position": 1, "title": "A"}, {"disc": 1, "position": 2, "title": " "}]')$$,
  '23514', null, 'track titles cannot be empty');
select results_eq(
  $$select title from public.entry_tracks$$, array['Airbag'],
  'a failed save keeps the old list');
select throws_ok(
  $$select public.set_entry_tracks('b2222222-2222-2222-2222-222222222222',
    '[{"disc": 1, "position": 1, "title": "Mine now"}]')$$,
  '23503', null, 'users cannot add tracks to someone else''s entry');

reset role;
delete from public.shelf_entries where id = 'a1111111-1111-1111-1111-111111111111';
select results_eq(
  $$select count(*)::int from public.entry_tracks$$, array[0],
  'tracks go when the album leaves the shelf');

select * from finish();
rollback;
