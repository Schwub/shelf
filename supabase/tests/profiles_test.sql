begin;
select plan(12);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

insert into public.profiles (user_id, name) values
  ('22222222-2222-2222-2222-222222222222', 'Bob');

set local role anon;
select is_empty('select * from public.profiles', 'anon cannot read profiles');
select throws_ok($$insert into public.profiles (name) values ('X')$$, '42501', null,
  'anon cannot add a profile');

-- Alice is signed in.
reset role;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select is_empty('select * from public.profiles',
  'users cannot read others'' profiles (friends can, from TASK-36)');
select lives_ok($$update public.profiles set name = 'Mallory'$$,
  'changing others'' names changes nothing (checked at the end)');
select lives_ok(
  $$insert into public.profiles (name) values ('Alice')
    on conflict (user_id) do update set name = excluded.name$$,
  'users add their own name, user_id defaults to them');
select lives_ok(
  $$insert into public.profiles (name) values ('Ali')
    on conflict (user_id) do update set name = excluded.name$$,
  'and change it');
select results_eq('select user_id, name from public.profiles',
  $$values ('11111111-1111-1111-1111-111111111111'::uuid, 'Ali')$$,
  'users read their own profile');

select throws_ok($$update public.profiles set name = ''$$, '23514', null,
  'a name is not empty');
select throws_ok($$update public.profiles set name = repeat('x', 41)$$, '23514', null,
  'a name has at most 40 characters');
select throws_ok($$update public.profiles set name = ' Ali'$$, '23514', null,
  'a name is stored trimmed');
select throws_ok(
  $$update public.profiles set user_id = '22222222-2222-2222-2222-222222222222'$$,
  '42501', null, 'users cannot move their profile');

reset role;
select is((select name from public.profiles
  where user_id = '22222222-2222-2222-2222-222222222222'), 'Bob',
  'others'' names are untouched');

select * from finish();
rollback;
