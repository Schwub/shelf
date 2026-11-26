begin;
select plan(34);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'carol@example.com');
insert into public.profiles (user_id, name) values
  ('11111111-1111-1111-1111-111111111111', 'Alice'),
  ('22222222-2222-2222-2222-222222222222', 'Bob'),
  ('33333333-3333-3333-3333-333333333333', 'Carol');
-- An expired invite from Alice.
insert into public.invites (code, inviter, expires_at) values
  ('EXPRDABC', '11111111-1111-1111-1111-111111111111', now() - interval '1 minute');

create function pg_temp.as_user(id text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', id, 'role', 'authenticated')::text, true);
$$;

-- Anonymous users.
set local role anon;
select throws_ok('select public.create_invite()', '42501', null,
  'anon cannot create invites');
select is_empty('select * from public.invites', 'anon cannot read invites');

-- Alice invites.
reset role;
select pg_temp.as_user('11111111-1111-1111-1111-111111111111');
set local role authenticated;
select matches(public.create_invite(), '^[A-HJKMNP-Z2-9]{8}$',
  'a code is 8 characters without look-alikes');
select results_eq('select count(*)::int from public.invites', array[2],
  'Alice reads her own invites');
select throws_ok($$insert into public.invites (code, inviter)
  values ('ABCDEFGH', '11111111-1111-1111-1111-111111111111')$$, '42501', null,
  'invites are made only by create_invite');
create temp table codes as select code from public.invites where expires_at > now();
grant select on codes to authenticated;
select results_eq($$select status from public.invite_preview((select code from codes))$$,
  array['own'], 'Alice''s own invite says so');
select throws_ok($$select public.accept_invite((select code from codes))$$,
  'P0001', 'own', 'Alice cannot accept her own invite');
select results_eq($$select status from public.invite_preview('NOPENOPE')$$,
  array['unknown'], 'an unknown code says so');

-- Bob looks at it and accepts, typed loosely.
reset role;
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select is_empty('select * from public.invites', 'Bob cannot read Alice''s invites');
delete from public.invites;
reset role;
select results_eq('select count(*)::int from public.invites', array[2],
  'Bob cannot cancel Alice''s invites');
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select is_empty('select * from public.profiles where user_id <> auth.uid()',
  'strangers cannot read each other''s names');
select results_eq(
  $$select status, inviter_id, inviter_name from public.invite_preview(
    lower(substr((select code from codes), 1, 4) || ' - ' || substr((select code from codes), 5)))$$,
  $$values ('valid', '11111111-1111-1111-1111-111111111111'::uuid, 'Alice')$$,
  'Bob sees who invited him, whatever case and dashes he types');
select results_eq($$select status from public.invite_preview('EXPR-DABC')$$,
  array['gone'], 'an expired invite is gone');
select throws_ok($$select public.accept_invite('EXPRDABC')$$, 'P0001', 'gone',
  'an expired invite cannot be accepted');
select results_eq($$select public.accept_invite((select code from codes))$$,
  array['11111111-1111-1111-1111-111111111111'::uuid], 'Bob accepts and gets the inviter');
select results_eq('select friend_id from public.friendships',
  array['11111111-1111-1111-1111-111111111111'::uuid], 'Bob has Alice as a friend');
select ok(public.is_friend('11111111-1111-1111-1111-111111111111'), 'is_friend says so');
select results_eq('select name from public.profiles order by name',
  array['Alice', 'Bob'], 'friends read each other''s names');
select throws_ok($$select public.accept_invite((select code from codes))$$, 'P0001', 'friends',
  'accepting again says they are friends already');
select throws_ok($$insert into public.friendships (user_id, friend_id)
  values ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333')$$,
  '42501', null, 'friendships are made only by accept_invite');

-- Carol tries the used code.
reset role;
select pg_temp.as_user('33333333-3333-3333-3333-333333333333');
set local role authenticated;
select results_eq($$select status from public.invite_preview((select code from codes))$$,
  array['gone'], 'a used invite is gone for others');
select throws_ok($$select public.accept_invite((select code from codes))$$, 'P0001', 'gone',
  'a used invite cannot be accepted again');
select is_empty('select * from public.friendships', 'Carol has no friends');

-- Alice sees the friendship from her side, and cancels a waiting invite.
reset role;
select pg_temp.as_user('11111111-1111-1111-1111-111111111111');
set local role authenticated;
select results_eq('select friend_id from public.friendships',
  array['22222222-2222-2222-2222-222222222222'::uuid], 'both rows exist');
select lives_ok($$delete from public.invites where code = (select code from codes)$$,
  'deleting a used invite runs');
select results_eq($$select count(*)::int from public.invites where code = (select code from codes)$$,
  array[1], 'but a used invite stays');
create temp table waiting as select public.create_invite() as code;
grant select on waiting to authenticated;
delete from public.invites where code = (select code from waiting);
select is_empty($$select * from public.invites where code = (select code from waiting)$$,
  'a waiting invite can be cancelled');
select results_eq($$select status from public.invite_preview((select code from waiting))$$,
  array['unknown'], 'a cancelled invite is unknown');

-- Bob removes Alice: both rows go.
reset role;
select pg_temp.as_user('22222222-2222-2222-2222-222222222222');
set local role authenticated;
select lives_ok($$select public.remove_friend('11111111-1111-1111-1111-111111111111')$$,
  'Bob removes Alice');
select is_empty('select * from public.friendships', 'Bob''s row is gone');
select results_eq('select name from public.profiles', array['Bob'],
  'removed friends cannot read each other''s names');
reset role;
select is_empty('select * from public.friendships', 'Alice''s row is gone too');

-- Bob deletes his account: the invite he used stays used.
delete from auth.users where id = '22222222-2222-2222-2222-222222222222';
select pg_temp.as_user('33333333-3333-3333-3333-333333333333');
set local role authenticated;
select results_eq($$select status from public.invite_preview((select code from codes))$$,
  array['gone'], 'an invite stays used after its accepter''s account is deleted');
select throws_ok($$select public.accept_invite((select code from codes))$$, 'P0001', 'gone',
  'and cannot be accepted again');

select * from finish();
rollback;
