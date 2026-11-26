begin;
select plan(16);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');

create function pg_temp.tag(t text) returns uuid language sql as $$
  select id from public.tags where name = t $$;
create function pg_temp.filter(n text) returns uuid language sql as $$
  select id from public.shelf_filters where name = n $$;

select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select results_eq(
  $$select count(*)::int from public.shelf_filters$$, array[4],
  'new users get four filters, and see only their own');

-- A custom filter: Own and rated 4 stars and up.
select lives_ok(
  $$with f as (insert into public.shelf_filters (name, tags_match, min_rating, position)
               values ('Best of mine', 'all', 8, 4) returning id)
    insert into public.shelf_filter_tags (filter_id, tag_id) select id, pg_temp.tag('Own') from f$$,
  'users make filters that combine conditions');
select lives_ok(
  $$insert into public.shelf_filters (name, favorite_tracks, unrated) values ('Starred, unrated', true, true)$$,
  'a filter can do without tags');
select throws_ok(
  $$insert into public.shelf_filters (name, unrated, min_rating) values ('Both', true, 6)$$,
  '23514', null, 'unrated and a minimum rating exclude each other');
select throws_ok(
  $$insert into public.shelf_filters (name, min_rating) values ('Eleven', 11)$$,
  '23514', null, 'ratings go up to 10 half stars');
select throws_ok(
  $$insert into public.shelf_filters (name, tags_match) values ('Some', 'some')$$,
  '23514', null, 'tags match any or all');
select lives_ok(
  $$update public.shelf_filters set name = 'Mine, rated', min_rating = 6 where name = 'Best of mine'$$,
  'users change their filters');
select lives_ok(
  $$insert into public.shelf_filters (name, added_within_days) values ('This month', 30)$$,
  'a filter on albums added in the last days');
select lives_ok(
  $$insert into public.shelf_filters (name, added_from, added_to)
    values ('Summer', '2026-06-01', '2026-08-31')$$,
  'or between two dates');
select throws_ok(
  $$insert into public.shelf_filters (name, added_within_days, added_from)
    values ('Both', 30, '2026-06-01')$$,
  '23514', null, 'not both kinds');
select throws_ok(
  $$insert into public.shelf_filters (name, added_from, added_to)
    values ('Backwards', '2026-08-31', '2026-06-01')$$,
  '23514', null, 'the range runs forwards');

-- Deleting a tag takes it out of filters; a filter left with nothing goes.
select lives_ok(
  $$insert into public.tags (group_id, name)
      select id, 'Krautrock' from public.tag_groups where name = 'Genre'$$,
  'a new genre');
select lives_ok(
  $$with f as (insert into public.shelf_filters (name, position) values ('Kraut', 6) returning id)
    insert into public.shelf_filter_tags (filter_id, tag_id) select id, pg_temp.tag('Krautrock') from f$$,
  'a filter on it');
select lives_ok(
  $$with f as (select pg_temp.filter('Mine, rated') as id)
    insert into public.shelf_filter_tags (filter_id, tag_id) select id, pg_temp.tag('Krautrock') from f$$,
  'and the tag in a custom filter');
with f as (select pg_temp.filter('This month') as id)
  insert into public.shelf_filter_tags (filter_id, tag_id) select id, pg_temp.tag('Krautrock') from f;
delete from public.tags where name = 'Krautrock';
select results_eq(
  $$select name from public.shelf_filters where name in ('Kraut', 'Mine, rated', 'This month')
    order by name$$,
  array['Mine, rated', 'This month'],
  'a filter left without conditions goes; one with others stays');

-- Bob's filters are out of reach.
reset role;
select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);
set local role authenticated;
select results_eq(
  $$select count(*)::int from public.shelf_filters where name is not null$$, array[0],
  'users don''t see others'' filters');

select * from finish();
rollback;
