begin;
select plan(5);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

-- What the add-album function inserts (service role).
insert into public.albums (id, title, artist, musicbrainz_id) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Catalog', 'Someone',
   'b1392450-e666-3926-a536-22c65f834433');
insert into public.albums (id, title, artist, created_by) values
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Alice''s tape', 'Alice',
   '11111111-1111-1111-1111-111111111111'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Bob''s tape', 'Bob',
   '22222222-2222-2222-2222-222222222222');

select throws_ok(
  $$insert into public.albums (title, artist, musicbrainz_id, created_by)
    values ('X', 'Y', '0b6b4ba0-d36f-47bd-b4ea-6a5b91842d29',
            '11111111-1111-1111-1111-111111111111')$$,
  '23514', null, 'an album is from MusicBrainz or by hand, not both');

select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select results_eq(
  'select title from public.albums order by title',
  array['Alice''s tape', 'Catalog'],
  'users see catalog albums and their own, not others'' hand-added ones');
select throws_ok(
  $$insert into public.albums (title, artist, created_by)
    values ('X', 'Y', '11111111-1111-1111-1111-111111111111')$$,
  '42501', null, 'users cannot add albums by hand themselves');
select lives_ok(
  $$insert into public.shelf_entries (album_id)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')$$,
  'users put their hand-added album on their shelf');

reset role;
delete from auth.users where id = '22222222-2222-2222-2222-222222222222';
select is_empty(
  $$select from public.albums where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'$$,
  'a deleted account takes its hand-added albums along');

select * from finish();
rollback;
