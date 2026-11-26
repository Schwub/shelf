begin;
select plan(16);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'carol@example.com');
insert into public.friendships (user_id, friend_id) values
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111');

insert into public.albums (id, title, artist) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Shown', 'A'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Hidden', 'B');
insert into public.albums (id, title, artist, created_by) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'By hand', 'C', '11111111-1111-1111-1111-111111111111');
insert into public.shelf_entries (id, user_id, album_id, hidden) values
  ('eeeeeeee-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', false),
  ('eeeeeeee-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', true),
  ('eeeeeeee-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccccc', false);
insert into public.entry_tags (entry_id, tag_id, user_id)
  select e, (select id from public.tags where user_id = '11111111-1111-1111-1111-111111111111'
             and builtin = 'listened'), '11111111-1111-1111-1111-111111111111'
  from unnest(array['eeeeeeee-0000-0000-0000-000000000001',
                    'eeeeeeee-0000-0000-0000-000000000002']::uuid[]) e;
insert into public.entry_tracks (entry_id, user_id, position, title) values
  ('eeeeeeee-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 1, 'Shown track'),
  ('eeeeeeee-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 1, 'Hidden track');

create function pg_temp.as_user(id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', id, 'role', 'authenticated')::text, true);
$$;

-- Bob, Alice's friend.
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select results_eq($$select album_id from public.shelf_entries
    where user_id = '11111111-1111-1111-1111-111111111111' order by album_id$$,
  array['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, 'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid],
  'a friend reads the visible entries, not the hidden one');
select results_eq($$select entry_id from public.entry_tags
    where user_id = '11111111-1111-1111-1111-111111111111'$$,
  array['eeeeeeee-0000-0000-0000-000000000001'::uuid],
  'and the tags of visible entries only');
select results_eq($$select title from public.entry_tracks
    where user_id = '11111111-1111-1111-1111-111111111111'$$,
  array['Shown track'], 'and their tracks only');
select ok((select count(*) from public.tags
    where user_id = '11111111-1111-1111-1111-111111111111') > 0, 'and the friend''s tags');
select ok((select count(*) from public.tag_groups
    where user_id = '11111111-1111-1111-1111-111111111111') > 0, 'and tag groups');
select is_empty($$select * from public.shelf_filters
    where user_id = '11111111-1111-1111-1111-111111111111'$$, 'but not their filters');
select results_eq($$select title from public.albums
    where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'$$,
  array['By hand'], 'a friend reads albums the other added by hand');
update public.shelf_entries set comment = 'Bob was here'
  where user_id = '11111111-1111-1111-1111-111111111111';
delete from public.shelf_entries where user_id = '11111111-1111-1111-1111-111111111111';
reset role;
select results_eq($$select count(*)::int from public.shelf_entries
    where user_id = '11111111-1111-1111-1111-111111111111' and comment is null$$,
  array[3], 'a friend cannot change or delete entries');

-- Carol, a stranger.
select pg_temp.as_user('33333333-3333-3333-3333-333333333333');
set local role authenticated;
select is_empty($$select * from public.shelf_entries
    where user_id = '11111111-1111-1111-1111-111111111111'$$, 'strangers read no entries');
select is_empty($$select * from public.tags
    where user_id = '11111111-1111-1111-1111-111111111111'$$, 'nor tags');
select is_empty($$select * from public.entry_tracks
    where user_id = '11111111-1111-1111-1111-111111111111'$$, 'nor tracks');
select is_empty($$select * from public.albums
    where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'$$, 'nor albums added by hand');

-- Alice still reads everything of hers, hidden or not.
reset role;
select pg_temp.as_user('11111111-1111-1111-1111-111111111111');
set local role authenticated;
select results_eq($$select count(*)::int from public.shelf_entries where user_id = auth.uid()$$,
  array[3], 'the owner reads hidden entries too');
select lives_ok($$update public.shelf_entries set hidden = false
    where id = 'eeeeeeee-0000-0000-0000-000000000002'$$, 'the owner can show an entry again');

-- Once removed, Bob sees nothing.
select lives_ok($$select public.remove_friend('22222222-2222-2222-2222-222222222222')$$,
  'Alice removes Bob');
reset role;
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select is_empty($$select * from public.shelf_entries
    where user_id = '11111111-1111-1111-1111-111111111111'$$,
  'a removed friend reads no entries');

select * from finish();
rollback;
