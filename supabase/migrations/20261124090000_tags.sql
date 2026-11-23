-- Generic tags replace the fixed statuses; design in docs/features/tags.md.

alter table public.shelf_entries
  drop column listening,
  drop column owning,
  drop column formats;
drop type public.listening_status;
drop type public.owning_status;
drop type public.album_format;

-- Target for composite foreign keys that tie a row to the same user.
alter table public.shelf_entries add unique (id, user_id);

create table public.tag_groups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  name text not null check (btrim(name) <> ''),
  exclusive boolean not null default false,
  -- Set for a sub-group, e.g. Format under the tag Own.
  parent_tag_id uuid,
  -- Shared meaning across users, so friends' shelves stay comparable.
  builtin text check (builtin in ('collection', 'listening')),
  position integer not null default 0,
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, builtin),
  unique (id, user_id),
  unique (id, exclusive),
  check (builtin is null or (exclusive and parent_tag_id is null))
);

create table public.tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  group_id uuid not null,
  name text not null check (btrim(name) <> ''),
  builtin text check (builtin in ('want', 'own', 'want_to_listen', 'listened')),
  position integer not null default 0,
  created_at timestamptz not null default now(),
  foreign key (group_id, user_id) references public.tag_groups (id, user_id) on delete cascade,
  unique (id, user_id),
  unique (id, group_id)
);

create unique index on public.tags (group_id, lower(name));
create unique index on public.tags (user_id, builtin);

alter table public.tag_groups
  add foreign key (parent_tag_id, user_id) references public.tags (id, user_id) on delete cascade;
create index on public.tag_groups (parent_tag_id);

create table public.entry_tags (
  entry_id uuid not null,
  tag_id uuid not null,
  user_id uuid not null default auth.uid(),
  -- Copied from the tag and its group by entry_tags_fill, so the partial
  -- unique index below can enforce one tag per exclusive group.
  group_id uuid not null,
  exclusive boolean not null,
  primary key (entry_id, tag_id),
  foreign key (entry_id, user_id) references public.shelf_entries (id, user_id) on delete cascade,
  foreign key (tag_id, user_id) references public.tags (id, user_id) on delete cascade,
  foreign key (tag_id, group_id) references public.tags (id, group_id),
  foreign key (group_id, exclusive) references public.tag_groups (id, exclusive) on update cascade on delete cascade
);

create unique index entry_tags_one_per_exclusive_group
  on public.entry_tags (entry_id, group_id) where exclusive;
create index on public.entry_tags (tag_id);
create index on public.entry_tags (group_id);

create table public.shelf_filters (
  user_id uuid not null default auth.uid(),
  tag_id uuid not null,
  position integer not null default 0,
  primary key (user_id, tag_id),
  foreign key (tag_id, user_id) references public.tags (id, user_id) on delete cascade
);
create index on public.shelf_filters (tag_id);

-- Fill group_id and exclusive from the tag, and require the parent tag of a
-- sub-group on the same entry.
create function public.entry_tags_fill() returns trigger
language plpgsql set search_path = '' as $$
declare
  parent uuid;
begin
  select t.group_id, g.exclusive, g.parent_tag_id
    into new.group_id, new.exclusive, parent
    from public.tags t join public.tag_groups g on g.id = t.group_id
    where t.id = new.tag_id;
  if parent is not null and not exists (
    select 1 from public.entry_tags where entry_id = new.entry_id and tag_id = parent
  ) then
    raise exception 'tag % needs its parent tag % on the entry', new.tag_id, parent
      using errcode = 'check_violation';
  end if;
  return new;
end $$;

create trigger entry_tags_fill
  before insert on public.entry_tags
  for each row execute function public.entry_tags_fill();

-- Removing a tag from an entry also removes the tags of its sub-groups.
create function public.entry_tags_remove_subtags() returns trigger
language plpgsql set search_path = '' as $$
begin
  delete from public.entry_tags e
    using public.tag_groups g
    where e.entry_id = old.entry_id and e.group_id = g.id and g.parent_tag_id = old.tag_id;
  return old;
end $$;

create trigger entry_tags_remove_subtags
  after delete on public.entry_tags
  for each row execute function public.entry_tags_remove_subtags();

-- Suggested groups and filters for every new user.
create function public.create_suggested_tags() returns trigger
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
  insert into public.tag_groups (user_id, name, exclusive, position)
    values (new.id, 'Genre', false, 2);
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

create trigger create_suggested_tags
  after insert on auth.users
  for each row execute function public.create_suggested_tags();

-- Clients may only change the editable columns; builtin, user_id and a tag's
-- group are set by the database.
revoke insert, update on public.tag_groups, public.tags, public.entry_tags, public.shelf_filters
  from anon, authenticated;
grant insert (name, exclusive, parent_tag_id, position, hidden) on public.tag_groups to authenticated;
grant update (name, exclusive, position, hidden) on public.tag_groups to authenticated;
grant insert (group_id, name, position) on public.tags to authenticated;
grant update (name, position) on public.tags to authenticated;
grant insert (entry_id, tag_id) on public.entry_tags to authenticated;
grant insert (tag_id, position) on public.shelf_filters to authenticated;
grant update (position) on public.shelf_filters to authenticated;

alter table public.tag_groups enable row level security;
alter table public.tags enable row level security;
alter table public.entry_tags enable row level security;
alter table public.shelf_filters enable row level security;

create policy "Users read their own tag groups" on public.tag_groups for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users add their own tag groups" on public.tag_groups for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users update their own tag groups" on public.tag_groups for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users delete their own tag groups, except built-in ones" on public.tag_groups for delete to authenticated
  using ((select auth.uid()) = user_id and builtin is null);

create policy "Users read their own tags" on public.tags for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users add their own tags" on public.tags for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users update their own tags" on public.tags for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users delete their own tags, except built-in ones" on public.tags for delete to authenticated
  using ((select auth.uid()) = user_id and builtin is null);

create policy "Users read their own entry tags" on public.entry_tags for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users tag their own entries" on public.entry_tags for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users untag their own entries" on public.entry_tags for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users read their own filters" on public.shelf_filters for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users add their own filters" on public.shelf_filters for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users reorder their own filters" on public.shelf_filters for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users remove their own filters" on public.shelf_filters for delete to authenticated
  using ((select auth.uid()) = user_id);
