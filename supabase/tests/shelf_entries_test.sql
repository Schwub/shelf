begin;
select plan(23);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

insert into public.albums (id, title, artist) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Album A', 'Artist A');

insert into public.shelf_entries (user_id, album_id, status) values
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'own');

-- Anonymous users see nothing.
set local role anon;
select is_empty('select * from public.albums', 'anon cannot read albums');
select is_empty('select * from public.shelf_entries', 'anon cannot read shelf entries');
select throws_ok(
  $$insert into public.albums (title, artist) values ('X', 'Y')$$,
  '42501', null, 'anon cannot add albums');
select throws_ok(
  $$insert into public.shelf_entries (user_id, album_id, status)
    values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'want')$$,
  '42501', null, 'anon cannot add shelf entries');
update public.shelf_entries set status = 'want';
delete from public.shelf_entries;

-- Alice is signed in.
reset role;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select results_eq('select count(*)::int from public.albums', array[1],
  'signed-in users read albums');
select lives_ok(
  $$insert into public.albums (id, title, artist)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Album B', 'Artist B')$$,
  'signed-in users add albums');

update public.albums set title = 'Changed' where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
delete from public.albums where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
select results_eq(
  $$select title from public.albums where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  array['Album A'], 'albums cannot be changed or deleted');

select is_empty('select * from public.shelf_entries',
  'users cannot read others'' shelf entries');

select lives_ok(
  $$insert into public.shelf_entries (album_id, status, rating, comment)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'listened', 9, 'Great')$$,
  'users add their own shelf entries, user_id defaults to them');
select results_eq('select user_id from public.shelf_entries',
  array['11111111-1111-1111-1111-111111111111'::uuid],
  'users read only their own shelf entries');

select throws_ok(
  $$insert into public.shelf_entries (user_id, album_id, status)
    values ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'own')$$,
  '42501', null, 'users cannot add entries for others');

select throws_ok(
  $$insert into public.shelf_entries (album_id, status)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'want')$$,
  '23505', null, 'one entry per user and album');
select lives_ok(
  $$insert into public.shelf_entries (album_id, status, rating)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'own', 1)$$,
  'rating 1 is accepted');
select lives_ok(
  $$update public.shelf_entries set rating = null
    where album_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'$$,
  'rating is optional');
delete from public.shelf_entries where album_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
select throws_ok(
  $$insert into public.shelf_entries (album_id, status, rating)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'own', 11)$$,
  '23514', null, 'rating above 10 is rejected');
select throws_ok(
  $$insert into public.shelf_entries (album_id, status, rating)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'own', 0)$$,
  '23514', null, 'rating below 1 is rejected');
select throws_ok(
  $$insert into public.shelf_entries (album_id, status)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'borrowed')$$,
  '22P02', null, 'unknown status is rejected');

update public.shelf_entries set status = 'want'
  where user_id = '22222222-2222-2222-2222-222222222222';
delete from public.shelf_entries
  where user_id = '22222222-2222-2222-2222-222222222222';

update public.shelf_entries set rating = 10, updated_at = now() - interval '1 day';
select results_eq('select rating from public.shelf_entries', array[10::smallint],
  'users update their own shelf entries');
select ok(
  (select updated_at > now() - interval '1 minute' from public.shelf_entries),
  'updated_at is set on update');
select throws_ok(
  $$update public.shelf_entries set user_id = '22222222-2222-2222-2222-222222222222'$$,
  '42501', null, 'users cannot move their entries to others');

select lives_ok('delete from public.shelf_entries', 'users delete their own shelf entries');
select is_empty('select * from public.shelf_entries', 'own entry is gone');

reset role;
select results_eq(
  $$select status::text from public.shelf_entries
    where user_id = '22222222-2222-2222-2222-222222222222'$$,
  array['own'], 'users cannot change or delete others'' entries');

select * from finish();
rollback;
