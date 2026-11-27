-- Where a friend's tag groups go when the user copies their tags
-- (TASK-48, docs/features/tags.md): into one of the user's groups, or
-- nowhere (null). Remembered so the next album from that friend goes the
-- same way. A row goes with either group.
create table public.tag_group_destinations (
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  friend_group_id uuid not null references public.tag_groups on delete cascade,
  group_id uuid,
  primary key (user_id, friend_group_id),
  -- Only into the user's own groups.
  foreign key (group_id, user_id) references public.tag_groups (id, user_id) on delete cascade
);

revoke insert, update on public.tag_group_destinations from anon, authenticated;
grant insert (friend_group_id, group_id), update (group_id)
  on public.tag_group_destinations to authenticated;

alter table public.tag_group_destinations enable row level security;
create policy "Users read their own destinations" on public.tag_group_destinations
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users add their own destinations" on public.tag_group_destinations
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users change their own destinations" on public.tag_group_destinations
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
