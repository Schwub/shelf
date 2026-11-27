begin;
select plan(9);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');
-- Friends, so Alice reads Bob's groups.
insert into public.friendships (user_id, friend_id) values
  ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222'),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111');

create function pg_temp.as_user(id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', id, 'role', 'authenticated')::text, true);
$$;
create function pg_temp.group_of(owner text, n text) returns uuid language sql as $$
  select id from public.tag_groups where user_id = owner::uuid and name = n $$;

-- Alice sends Bob's Genre into her Genre, and his Listening nowhere.
select pg_temp.as_user('11111111-1111-1111-1111-111111111111');
set local role authenticated;
select lives_ok(
  $$insert into public.tag_group_destinations (friend_group_id, group_id)
    values (pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Genre'),
            pg_temp.group_of('11111111-1111-1111-1111-111111111111', 'Genre'))$$,
  'a user remembers where a friend''s group goes');
select lives_ok(
  $$insert into public.tag_group_destinations (friend_group_id, group_id)
    values (pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Listening'), null)$$,
  'or that it goes nowhere');
select throws_ok(
  $$insert into public.tag_group_destinations (friend_group_id, group_id)
    values (pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Collection'),
            pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Genre'))$$,
  '23503', null, 'only into the user''s own groups');
select lives_ok(
  $$update public.tag_group_destinations set group_id = null
    where friend_group_id = pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Listening')$$,
  'and changes it');

select lives_ok(
  $$delete from public.tag_group_destinations
    where friend_group_id = pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Listening')$$,
  'and forgets it');
select results_eq(
  $$select count(*)::int from public.tag_group_destinations$$, array[1],
  'only the Genre row is left');
insert into public.tag_group_destinations (friend_group_id, group_id)
  values (pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Listening'), null);

-- Bob sees none of it.
reset role;
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select is_empty('select * from public.tag_group_destinations',
  'others read no destinations');

-- Removing either group takes the row along.
reset role;
delete from public.tag_groups
  where id = pg_temp.group_of('22222222-2222-2222-2222-222222222222', 'Genre');
select results_eq(
  $$select count(*)::int from public.tag_group_destinations$$, array[1],
  'the friend''s group gone, its row goes');
select results_eq(
  $$select count(*)::int from public.tag_group_destinations where group_id is null$$, array[1],
  'the other stays');

select * from finish();
rollback;
