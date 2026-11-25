-- How a tag group shows on an album (TASK-28): all its tags as keys, or only
-- the chosen ones, picked from an alphabetical list (Genre). Still ordinary
-- tags in an ordinary group (docs/features/tags.md).
alter table public.tag_groups add column pick_from_list boolean not null default false;
grant insert (pick_from_list), update (pick_from_list) on public.tag_groups to authenticated;

-- Existing users' suggested Genre group.
update public.tag_groups set pick_from_list = true
  where builtin is null and parent_tag_id is null and lower(name) = 'genre';

-- New users get Genre as a list from the start.
create or replace function public.create_suggested_tags() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  collection uuid;
  listening uuid;
  format uuid;
  own uuid;
begin
  insert into public.tag_groups (user_id, name, exclusive, builtin, position)
    values (new.id, 'Collection', true, 'collection', 0) returning id into collection;
  insert into public.tag_groups (user_id, name, exclusive, builtin, position)
    values (new.id, 'Listening', true, 'listening', 1) returning id into listening;
  insert into public.tag_groups (user_id, name, exclusive, pick_from_list, position)
    values (new.id, 'Genre', false, true, 2);
  insert into public.tags (user_id, group_id, name, builtin, position) values
    (new.id, collection, 'Want', 'want', 0),
    (new.id, listening, 'Want to listen', 'want_to_listen', 0),
    (new.id, listening, 'Listened', 'listened', 1);
  insert into public.tags (user_id, group_id, name, builtin, position)
    values (new.id, collection, 'Own', 'own', 1) returning id into own;
  insert into public.tag_groups (user_id, name, exclusive, parent_tag_id, position)
    values (new.id, 'Format', false, own, 0) returning id into format;
  insert into public.tags (user_id, group_id, name, position) values
    (new.id, format, 'Vinyl', 0), (new.id, format, 'CD', 1),
    (new.id, format, 'Tape', 2), (new.id, format, 'File', 3);
  insert into public.shelf_filters (user_id, tag_id, position)
    select new.id, id, case builtin when 'own' then 0 when 'want' then 1 when 'want_to_listen' then 2 else 3 end
      from public.tags where user_id = new.id and builtin is not null;
  return new;
end $$;
