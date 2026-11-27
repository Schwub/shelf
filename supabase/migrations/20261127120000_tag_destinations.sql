-- Copy or map a friend's tags (TASK-49, docs/features/tags.md): what the
-- user chose for the friend's groups and tags, remembered for the next
-- album from that friend.

-- A friend's group can also go under one of the user's tags, as a new or
-- existing sub-group there. A row holds one target at most.
alter table public.tag_group_destinations
  add column parent_tag_id uuid,
  add foreign key (parent_tag_id, user_id) references public.tags (id, user_id) on delete cascade,
  add check (group_id is null or parent_tag_id is null);
create index on public.tag_group_destinations (parent_tag_id);
grant insert (parent_tag_id), update (parent_tag_id)
  on public.tag_group_destinations to authenticated;

-- Per friend's tag: onto one of the user's tags, or into one of their
-- groups (or neither: Copy), and whether the user took it before. A row
-- goes with the friend's tag or the user's target.
create table public.tag_destinations (
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  friend_tag_id uuid not null references public.tags on delete cascade,
  tag_id uuid,
  group_id uuid,
  taken boolean not null default false,
  primary key (user_id, friend_tag_id),
  foreign key (tag_id, user_id) references public.tags (id, user_id) on delete cascade,
  foreign key (group_id, user_id) references public.tag_groups (id, user_id) on delete cascade,
  check (tag_id is null or group_id is null)
);

create index on public.tag_destinations (friend_tag_id);
create index on public.tag_destinations (tag_id);
create index on public.tag_destinations (group_id);

revoke insert, update on public.tag_destinations from anon, authenticated;
-- An upsert updates every column it sends, the key included.
grant insert (friend_tag_id, tag_id, group_id, taken),
  update (friend_tag_id, tag_id, group_id, taken)
  on public.tag_destinations to authenticated;

alter table public.tag_destinations enable row level security;
create policy "Users read their own tag destinations" on public.tag_destinations
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users add their own tag destinations" on public.tag_destinations
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users change their own tag destinations" on public.tag_destinations
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users forget their own tag destinations" on public.tag_destinations
  for delete to authenticated using ((select auth.uid()) = user_id);
