begin;
select plan(8);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');
-- Friends, so Alice reads Bob's tags.
insert into public.friendships (user_id, friend_id) values
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111');

create function pg_temp.as_user(id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', id, 'role', 'authenticated')::text, true);
$$;
create function pg_temp.tag_of(owner text, n text) returns uuid language sql as $$
  select id from public.tags where user_id = owner::uuid and name = n $$;
create function pg_temp.group_of(owner text, n text) returns uuid language sql as $$
  select id from public.tag_groups where user_id = owner::uuid and name = n $$;

select pg_temp.as_user('11111111-1111-1111-1111-111111111111');
set local role authenticated;
select lives_ok(
  $$insert into public.tag_destinations (friend_tag_id, tag_id, taken)
    values (pg_temp.tag_of('22222222-2222-2222-2222-222222222222', 'Vinyl'),
            pg_temp.tag_of('11111111-1111-1111-1111-111111111111', 'CD'), true)$$,
  'a user remembers which of their tags a friend''s tag goes onto');
select lives_ok(
  $$insert into public.tag_destinations (friend_tag_id, group_id)
    values (pg_temp.tag_of('22222222-2222-2222-2222-222222222222', 'CD'),
            pg_temp.group_of('11111111-1111-1111-1111-111111111111', 'Genre'))$$,
  'or which group it goes into');
select throws_ok(
  $$insert into public.tag_destinations (friend_tag_id, tag_id)
    values (pg_temp.tag_of('22222222-2222-2222-2222-222222222222', 'Tape'),
            pg_temp.tag_of('22222222-2222-2222-2222-222222222222', 'Tape'))$$,
  '23503', null, 'only onto the user''s own tags');
select throws_ok(
  $$insert into public.tag_destinations (friend_tag_id, tag_id, group_id)
    values (pg_temp.tag_of('22222222-2222-2222-2222-222222222222', 'File'),
            pg_temp.tag_of('11111111-1111-1111-1111-111111111111', 'CD'),
            pg_temp.group_of('11111111-1111-1111-1111-111111111111', 'Genre'))$$,
  '23514', null, 'one target at most');
select lives_ok(
  $$insert into public.tag_group_destinations (friend_group_id, parent_tag_id)
    values (pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Format'),
            pg_temp.tag_of('11111111-1111-1111-1111-111111111111', 'Want'))$$,
  'a friend''s group can go under one of the user''s tags');

reset role;
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select is_empty('select * from public.tag_destinations',
  'others read no tag destinations');

-- Removing the user's target takes the row along.
reset role;
delete from public.tags
  where id = pg_temp.tag_of('11111111-1111-1111-1111-111111111111', 'CD');
select results_eq(
  $$select count(*)::int from public.tag_destinations$$, array[1],
  'the target gone, its row goes');
delete from public.tags
  where id = pg_temp.tag_of('11111111-1111-1111-1111-111111111111', 'Want');
select is_empty(
  $$select * from public.tag_group_destinations where parent_tag_id is not null$$,
  'and a group''s row with its parent tag');

select * from finish();
rollback;
