begin;
select plan(14);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'carol@example.com');
insert into public.profiles (user_id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Alice'),
  ('22222222-2222-2222-2222-222222222222', 'Bob');
insert into public.friendships (user_id, friend_id) values
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111');
insert into public.albums (id, title, artist) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Added', 'A'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Added rated', 'A'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'Rated later', 'A'),
  ('aaaaaaaa-0000-0000-0000-000000000004', 'Hidden', 'A'),
  ('aaaaaaaa-0000-0000-0000-000000000005', 'Bob''s', 'B');

-- Alice's shelf, with the times set by hand (the database sets them to now).
insert into public.shelf_entries (id, user_id, album_id, rating, hidden) values
  ('eeeeeeee-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001', null, false),
  ('eeeeeeee-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000002', 8, false),
  ('eeeeeeee-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000003', 6, false),
  ('eeeeeeee-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000004', 10, true),
  ('eeeeeeee-0000-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000005', null, false);
update public.shelf_entries set created_at = now() - interval '3 hours'
  where id = 'eeeeeeee-0000-0000-0000-000000000001';
update public.shelf_entries set created_at = now() - interval '2 hours', rated_at = now() - interval '2 hours'
  where id = 'eeeeeeee-0000-0000-0000-000000000002';
update public.shelf_entries set created_at = now() - interval '5 hours', rated_at = now() - interval '1 hour'
  where id = 'eeeeeeee-0000-0000-0000-000000000003';

create function pg_temp.as_user(id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', id, 'role', 'authenticated')::text, true);
$$;

set local role anon;
select throws_ok('select * from public.feed', '42501', null, 'anon cannot read the feed');

-- Bob reads Alice's activity.
reset role;
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select results_eq($$select title, kind from public.feed order by at desc$$,
  $$values ('Rated later', 'rated'), ('Added rated', 'added'), ('Added', 'added'),
           ('Rated later', 'added')$$,
  'friends'' adds and later ratings, newest first; no hidden entries, not his own');
select results_eq($$select rating, name from public.feed where title = 'Added rated'$$,
  $$values (8::smallint, 'Alice')$$,
  'an album added with a rating is one item, with the rating and the friend''s name');
select results_eq($$select kind, rating from public.feed where title = 'Rated later' order by at desc$$,
  $$values ('rated', 6::smallint), ('added', null)$$,
  'a rating given later shows on the rated item only');

-- Carol, a stranger.
reset role;
select pg_temp.as_user('33333333-3333-3333-3333-333333333333');
set local role authenticated;
select is_empty('select * from public.feed', 'strangers see nothing');

-- Alice: the database keeps the times.
reset role;
select pg_temp.as_user('11111111-1111-1111-1111-111111111111');
set local role authenticated;
select results_eq('select title from public.feed', array['Bob''s'],
  'her feed has Bob''s activity, not her own');
select throws_ok($$insert into public.shelf_entries (album_id, created_at)
    values ('aaaaaaaa-0000-0000-0000-000000000005', now() + interval '1 day')$$,
  '42501', null, 'clients cannot set created_at');
select throws_ok($$update public.shelf_entries set rated_at = now() + interval '1 day'$$,
  '42501', null, 'clients cannot set rated_at');
select lives_ok($$insert into public.shelf_entries (album_id, rating)
    values ('aaaaaaaa-0000-0000-0000-000000000005', 4)$$,
  'adding with a rating still works');
select ok((select rated_at = created_at from public.shelf_entries
    where album_id = 'aaaaaaaa-0000-0000-0000-000000000005' and user_id = auth.uid()),
  'a rating given when adding is rated at the same time');

update public.shelf_entries set comment = 'only a comment'
  where id = 'eeeeeeee-0000-0000-0000-000000000003';
select ok((select rated_at < now() - interval '59 minutes' from public.shelf_entries
    where id = 'eeeeeeee-0000-0000-0000-000000000003'),
  'other changes keep rated_at');
update public.shelf_entries set rating = 7 where id = 'eeeeeeee-0000-0000-0000-000000000003';
select ok((select rated_at = now() from public.shelf_entries
    where id = 'eeeeeeee-0000-0000-0000-000000000003'),
  'a new rating moves rated_at');
update public.shelf_entries set rating = null where id = 'eeeeeeee-0000-0000-0000-000000000003';
select is((select rated_at from public.shelf_entries
    where id = 'eeeeeeee-0000-0000-0000-000000000003'), null,
  'clearing the rating clears rated_at');

update public.shelf_entries set hidden = true where id = 'eeeeeeee-0000-0000-0000-000000000001';
reset role;
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select is_empty($$select * from public.feed where title = 'Added'$$,
  'hiding an entry takes its items out of the feed');

select * from finish();
rollback;
