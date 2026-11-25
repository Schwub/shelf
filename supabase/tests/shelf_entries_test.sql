begin;
select plan(25);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

insert into public.albums (id, title, artist) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Album A', 'Artist A'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Album B', 'Artist B');

insert into public.shelf_entries (user_id, album_id, comment) values
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Bob''s');

-- Anonymous users see nothing.
set local role anon;
select is_empty('select * from public.albums', 'anon cannot read albums');
select is_empty('select * from public.shelf_entries', 'anon cannot read shelf entries');
select throws_ok(
  $$insert into public.albums (title, artist) values ('X', 'Y')$$,
  '42501', null, 'anon cannot add albums');
select throws_ok(
  $$insert into public.shelf_entries (user_id, album_id)
    values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501', null, 'anon cannot add shelf entries');
update public.shelf_entries set comment = 'changed';
delete from public.shelf_entries;

-- Alice is signed in.
reset role;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select results_eq('select count(*)::int from public.albums', array[2],
  'signed-in users read albums');
select throws_ok(
  $$insert into public.albums (title, artist) values ('X', 'Y')$$,
  '42501', null, 'only the add-album function adds albums');

update public.albums set title = 'Changed' where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
delete from public.albums where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
select results_eq(
  $$select title from public.albums where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  array['Album A'], 'albums cannot be changed or deleted');

select is_empty('select * from public.shelf_entries',
  'users cannot read others'' shelf entries');

select lives_ok(
  $$insert into public.shelf_entries (album_id) values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')$$,
  'an entry needs no tags, rating or comment');
delete from public.shelf_entries where album_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

select lives_ok(
  $$insert into public.shelf_entries (album_id, rating, comment)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 9, 'Great')$$,
  'users add their own shelf entries, user_id defaults to them');
select results_eq('select user_id from public.shelf_entries',
  array['11111111-1111-1111-1111-111111111111'::uuid],
  'users read only their own shelf entries');

select throws_ok(
  $$insert into public.shelf_entries (user_id, album_id)
    values ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')$$,
  '42501', null, 'users cannot add entries for others');

select throws_ok(
  $$insert into public.shelf_entries (album_id) values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '23505', null, 'one entry per user and album');
select throws_ok(
  $$insert into public.shelf_entries (album_id, rating)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 11)$$,
  '23514', null, 'rating above 10 is rejected');
select throws_ok(
  $$insert into public.shelf_entries (album_id, rating)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 0)$$,
  '23514', null, 'rating below 1 is rejected');

update public.shelf_entries set comment = 'hacked'
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
  $$select comment from public.shelf_entries
    where user_id = '22222222-2222-2222-2222-222222222222'$$,
  array['Bob''s'], 'users cannot change or delete others'' entries');

-- Added from a friend's shelf: the friend's name stays when their account goes.
insert into auth.users (id, email) values ('33333333-3333-3333-3333-333333333333', 'anna@example.com');
select lives_ok(
  $$insert into public.shelf_entries (user_id, album_id, added_from_user_id, added_from_name)
    values ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            '33333333-3333-3333-3333-333333333333', 'Anna')$$,
  'an entry remembers the friend it was added from');
select throws_ok(
  $$insert into public.shelf_entries (user_id, album_id, added_from_user_id)
    values ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            '33333333-3333-3333-3333-333333333333')$$,
  '23514', null, 'the friend''s name is required with the friend');
delete from auth.users where id = '33333333-3333-3333-3333-333333333333';
select is(
  (select added_from_user_id from public.shelf_entries where added_from_name = 'Anna'), null,
  'deleting the friend''s account clears the link');
select is(
  (select added_from_name from public.shelf_entries where album_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
     and user_id = '11111111-1111-1111-1111-111111111111'), 'Anna',
  'the friend''s name stays');

select * from finish();
rollback;
