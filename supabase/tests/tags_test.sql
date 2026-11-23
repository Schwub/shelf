begin;
select plan(37);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'bob@example.com');
insert into public.albums (id, title, artist) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Album A', 'Artist A'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Album B', 'Artist B');
insert into public.shelf_entries (id, user_id, album_id) values
  ('e1111111-0000-0000-0000-000000000000', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('e2222222-0000-0000-0000-000000000000', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

-- Lookups by name for the signed-in user (row-level security does the scoping).
create function pg_temp.tag(g text, t text) returns uuid language sql as $$
  select tags.id from public.tags join public.tag_groups on tag_groups.id = tags.group_id
  where tag_groups.name = g and tags.name = t $$;
create function pg_temp.grp(g text) returns uuid language sql as $$
  select id from public.tag_groups where name = g $$;

-- Suggested groups for a new user (checked as superuser, for Alice).
select results_eq(
  $$select name, exclusive, builtin from public.tag_groups
    where user_id = '11111111-1111-1111-1111-111111111111' and parent_tag_id is null order by position$$,
  $$values ('Collection', true, 'collection'), ('Listening', true, 'listening'), ('Genre', false, null::text)$$,
  'new users get Collection, Listening and Genre');
select results_eq(
  $$select t.name, t.builtin from public.tags t join public.tag_groups g on g.id = t.group_id
    where g.user_id = '11111111-1111-1111-1111-111111111111' and g.builtin is not null order by g.position, t.position$$,
  $$values ('Want', 'want'), ('Own', 'own'), ('Want to listen', 'want_to_listen'), ('Listened', 'listened')$$,
  'built-in groups get their built-in tags');
select results_eq(
  $$select g.name, g.exclusive, p.name from public.tag_groups g join public.tags p on p.id = g.parent_tag_id
    where g.user_id = '11111111-1111-1111-1111-111111111111'$$,
  $$values ('Format', false, 'Own')$$,
  'Format is a multiple-choice sub-group under Own');
select results_eq(
  $$select t.name from public.tags t join public.tag_groups g on g.id = t.group_id
    where g.user_id = '11111111-1111-1111-1111-111111111111' and g.name = 'Format' order by t.position$$,
  array['Vinyl', 'CD', 'Tape', 'File'], 'Format offers Vinyl, CD, Tape, File');
select results_eq(
  $$select t.name from public.shelf_filters f join public.tags t on t.id = f.tag_id
    where f.user_id = '11111111-1111-1111-1111-111111111111' order by f.position$$,
  array['Own', 'Want', 'Want to listen', 'Listened'], 'the filter bar starts with the built-in tags');

-- Anonymous users see nothing.
set local role anon;
select is_empty('select * from public.tag_groups', 'anon cannot read tag groups');
select is_empty('select * from public.tags', 'anon cannot read tags');

-- Alice is signed in.
reset role;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);
set local role authenticated;

select results_eq('select count(*)::int from public.tag_groups', array[4],
  'users see only their own tag groups');
select results_eq(
  $$select count(*)::int from public.shelf_filters$$, array[4], 'users see only their own filters');

-- Exclusive and multiple-choice groups.
select lives_ok(
  $$insert into public.entry_tags (entry_id, tag_id) values ('e1111111-0000-0000-0000-000000000000', pg_temp.tag('Collection', 'Own'))$$,
  'tag an entry; group and exclusivity are filled in');
select throws_ok(
  $$insert into public.entry_tags (entry_id, tag_id) values ('e1111111-0000-0000-0000-000000000000', pg_temp.tag('Collection', 'Want'))$$,
  '23505', null, 'only one tag per exclusive group');
select lives_ok(
  $$insert into public.entry_tags (entry_id, tag_id) values ('e1111111-0000-0000-0000-000000000000', pg_temp.tag('Format', 'Vinyl')),
    ('e1111111-0000-0000-0000-000000000000', pg_temp.tag('Format', 'File'))$$,
  'several tags from a multiple-choice sub-group under a tag the entry has');

insert into public.tags (group_id, name) values (pg_temp.grp('Genre'), 'Rock'), (pg_temp.grp('Genre'), 'Jazz');
insert into public.entry_tags (entry_id, tag_id) values
  ('e1111111-0000-0000-0000-000000000000', pg_temp.tag('Genre', 'Rock')),
  ('e1111111-0000-0000-0000-000000000000', pg_temp.tag('Genre', 'Jazz'));
select throws_ok(
  $$update public.tag_groups set exclusive = true where name = 'Genre'$$,
  '23505', null, 'a group cannot become exclusive while an entry has two of its tags');
select throws_ok(
  $$insert into public.tags (group_id, name) values (pg_temp.grp('Genre'), 'rock')$$,
  '23505', null, 'tag names are unique within a group, ignoring case');

-- Sub-tags need their parent tag.
insert into public.shelf_entries (id, album_id) values ('e1111111-1111-0000-0000-000000000000', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
select throws_ok(
  $$insert into public.entry_tags (entry_id, tag_id) values ('e1111111-1111-0000-0000-000000000000', pg_temp.tag('Format', 'CD'))$$,
  '23514', null, 'a sub-tag needs its parent tag on the entry');
delete from public.entry_tags where tag_id = pg_temp.tag('Collection', 'Own');
select results_eq(
  $$select count(*)::int from public.entry_tags e join public.tags t on t.id = e.tag_id join public.tag_groups g on g.id = t.group_id
    where g.name = 'Format'$$,
  array[0], 'removing a tag from an entry removes its sub-tags');

-- The tag editor: own groups, sub-groups, rename, reorder, delete.
select lives_ok(
  $$insert into public.tag_groups (name, exclusive) values ('Mood', false)$$, 'users create groups');
select lives_ok(
  $$insert into public.tag_groups (name, exclusive, parent_tag_id) values ('Pressing', true, pg_temp.tag('Format', 'Vinyl'))$$,
  'users create sub-groups under any tag');
select throws_ok(
  $$insert into public.tag_groups (name) values ('mood')$$,
  '23505', null, 'group names are unique, ignoring case');
select lives_ok(
  $$insert into public.tag_groups (name, parent_tag_id) values ('Mood', pg_temp.tag('Format', 'Vinyl'))$$,
  'the same name can be used at another level');
select lives_ok(
  $$update public.tag_groups set name = 'In my collection', hidden = true where builtin = 'collection'$$,
  'built-in groups can be renamed and hidden');
select lives_ok(
  $$update public.tags set name = 'Have', position = 5 where builtin = 'own'$$,
  'built-in tags can be renamed and reordered');
delete from public.tag_groups where builtin = 'listening';
delete from public.tags where builtin = 'want';
select results_eq(
  $$select count(*)::int from public.tag_groups where builtin = 'listening'$$, array[1],
  'built-in groups cannot be deleted');
select results_eq(
  $$select count(*)::int from public.tags where builtin = 'want'$$, array[1],
  'built-in tags cannot be deleted');
select throws_ok(
  $$update public.tag_groups set exclusive = false where builtin = 'listening'$$,
  '23514', null, 'built-in groups stay exclusive');
select throws_ok(
  $$update public.tag_groups set hidden = true where name = 'Mood'$$,
  '23514', null, 'only built-in groups can be hidden');
select throws_ok(
  $$insert into public.tag_groups (name, builtin) values ('Fake', 'collection')$$,
  '42501', null, 'users cannot create built-in groups');
select throws_ok(
  $$update public.tags set builtin = 'own' where name = 'Rock'$$,
  '42501', null, 'users cannot mark tags as built-in');
select throws_ok(
  $$update public.tags set group_id = pg_temp.grp('Mood') where name = 'Rock'$$,
  '42501', null, 'tags cannot move to another group');
select lives_ok(
  $$delete from public.tags where name = 'Jazz'$$, 'users delete their own tags');
select results_eq(
  $$select count(*)::int from public.entry_tags where tag_id not in (select id from public.tags)$$, array[0],
  'deleting a tag removes it from entries');
select lives_ok(
  $$delete from public.tag_groups where name = 'Genre'$$, 'users delete their own groups');
select results_eq(
  $$select count(*)::int from public.tags where name = 'Rock'$$, array[0], 'deleting a group deletes its tags');

-- Filters.
select lives_ok(
  $$insert into public.shelf_filters (tag_id, position) values (pg_temp.tag('Format', 'Vinyl'), 5)$$,
  'users add filters for their own tags');

-- Nothing of Bob's can be read or used.
select is_empty(
  $$select * from public.tags where user_id = '22222222-2222-2222-2222-222222222222'$$,
  'users cannot read others'' tags');
select throws_ok(
  $$insert into public.entry_tags (entry_id, tag_id) values ('e2222222-0000-0000-0000-000000000000', pg_temp.tag('Format', 'CD'))$$,
  null, null, 'users cannot tag others'' entries');
reset role;
select throws_ok(
  $$insert into public.entry_tags (entry_id, tag_id)
    select 'e1111111-0000-0000-0000-000000000000', t.id from public.tags t
    where t.user_id = '22222222-2222-2222-2222-222222222222' and t.builtin = 'listened'$$,
  '23503', null, 'an entry cannot carry another user''s tag');

select * from finish();
rollback;
