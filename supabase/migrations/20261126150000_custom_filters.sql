-- Filters that combine conditions (TASK-18, TASK-32; docs/features/filters.md):
-- tags (any or all of them), a minimum rating or unrated, favorite tracks.
-- A filter with one tag and nothing else is the simple tag filter and shows
-- the tag's name; others carry their own name.
alter table public.shelf_filters rename to shelf_filters_v1;

create table public.shelf_filters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  name text check (name is null or btrim(name) <> ''),
  position integer not null default 0,
  tags_match text not null default 'any' check (tags_match in ('any', 'all')),
  -- Half stars, like shelf_entries.rating.
  min_rating integer check (min_rating between 1 and 10),
  unrated boolean not null default false,
  favorite_tracks boolean not null default false,
  check (not (unrated and min_rating is not null)),
  unique (id, user_id)
);
create index on public.shelf_filters (user_id);

create table public.shelf_filter_tags (
  filter_id uuid not null,
  tag_id uuid not null,
  user_id uuid not null default auth.uid(),
  primary key (filter_id, tag_id),
  foreign key (filter_id, user_id) references public.shelf_filters (id, user_id) on delete cascade,
  -- Deleting a tag takes it out of filters.
  foreign key (tag_id, user_id) references public.tags (id, user_id) on delete cascade
);
create index on public.shelf_filter_tags (tag_id);

-- The old one-tag filters, in their order.
do $$
declare
  old record;
  filter uuid;
begin
  for old in select * from public.shelf_filters_v1 loop
    insert into public.shelf_filters (user_id, position)
      values (old.user_id, old.position) returning id into filter;
    insert into public.shelf_filter_tags (filter_id, tag_id, user_id)
      values (filter, old.tag_id, old.user_id);
  end loop;
end $$;
drop table public.shelf_filters_v1;

-- A filter whose last tag went (with the tag) and that has no other
-- condition would match every album: it goes too. Clients add a filter's
-- new tags before removing old ones, so an edit never empties it.
create function public.shelf_filters_drop_empty() returns trigger
language plpgsql set search_path = '' as $$
begin
  delete from public.shelf_filters f
  where f.id = old.filter_id
    and f.min_rating is null and not f.unrated and not f.favorite_tracks
    and not exists (select from public.shelf_filter_tags t where t.filter_id = f.id);
  return old;
end $$;

create trigger shelf_filters_drop_empty
  after delete on public.shelf_filter_tags
  for each row execute function public.shelf_filters_drop_empty();

revoke insert, update on public.shelf_filters, public.shelf_filter_tags from anon, authenticated;
grant insert (name, position, tags_match, min_rating, unrated, favorite_tracks),
  update (name, position, tags_match, min_rating, unrated, favorite_tracks)
  on public.shelf_filters to authenticated;
grant insert (filter_id, tag_id) on public.shelf_filter_tags to authenticated;

alter table public.shelf_filters enable row level security;
alter table public.shelf_filter_tags enable row level security;

create policy "Users read their own filters" on public.shelf_filters for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users add their own filters" on public.shelf_filters for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users change their own filters" on public.shelf_filters for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users remove their own filters" on public.shelf_filters for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users read their own filter tags" on public.shelf_filter_tags for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users add tags to their own filters" on public.shelf_filter_tags for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users take tags out of their own filters" on public.shelf_filter_tags for delete to authenticated
  using ((select auth.uid()) = user_id);

-- New users' filters in the new shape.
create or replace function public.create_suggested_tags() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  collection uuid;
  listening uuid;
  format uuid;
  own uuid;
  t record;
  filter uuid;
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
  -- One filter per built-in tag: Own, Want, Want to listen, Listened.
  for t in
    select id, case builtin when 'own' then 0 when 'want' then 1 when 'want_to_listen' then 2 else 3 end as position
      from public.tags where user_id = new.id and builtin is not null
  loop
    insert into public.shelf_filters (user_id, position)
      values (new.id, t.position) returning id into filter;
    insert into public.shelf_filter_tags (filter_id, tag_id, user_id)
      values (filter, t.id, new.id);
  end loop;
  return new;
end $$;
