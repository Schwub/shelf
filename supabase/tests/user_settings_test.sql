begin;
select plan(12);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

insert into public.user_settings (user_id, theme, shelf_view) values
  ('22222222-2222-2222-2222-222222222222', 'evening', 'list');

-- Anonymous users see nothing.
set local role anon;
select is_empty('select * from public.user_settings', 'anon cannot read settings');
select throws_ok(
  $$insert into public.user_settings (theme) values ('evening')$$,
  '42501', null, 'anon cannot add settings');

-- Alice is signed in.
reset role;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select is_empty('select * from public.user_settings',
  'users cannot read others'' settings');
select lives_ok($$update public.user_settings set theme = 'daylight'$$,
  'changing others'' settings changes nothing (see the end)');

select lives_ok(
  $$insert into public.user_settings (theme, shelf_view) values ('evening', 'covers')
    on conflict (user_id) do update set theme = excluded.theme, shelf_view = excluded.shelf_view$$,
  'users add their own settings, user_id defaults to them');
select lives_ok(
  $$insert into public.user_settings (theme, shelf_view) values ('surfGreen', 'list')
    on conflict (user_id) do update set theme = excluded.theme, shelf_view = excluded.shelf_view$$,
  'and upsert them again');
select results_eq('select user_id, theme, shelf_view from public.user_settings',
  $$values ('11111111-1111-1111-1111-111111111111'::uuid, 'surfGreen', 'list')$$,
  'users read only their own settings, one row each');

select throws_ok(
  $$update public.user_settings set user_id = '22222222-2222-2222-2222-222222222222'$$,
  '42501', null, 'users cannot move their settings to another user');
select throws_ok(
  $$update public.user_settings set shelf_view = 'spines'$$,
  '23514', null, 'the shelf view is covers or list');
select lives_ok($$update public.user_settings set shelf_sort = 'artist_reversed'$$,
  'users save how the shelf is sorted');
select throws_ok(
  $$update public.user_settings set shelf_sort = 'colour'$$,
  '23514', null, 'the sort is one of the known orders');

reset role;
select is(
  (select theme from public.user_settings where user_id = '22222222-2222-2222-2222-222222222222'),
  'evening', 'others'' settings are untouched');

select * from finish();
rollback;
