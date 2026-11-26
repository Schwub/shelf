-- The user's settings (TASK-25), so they follow the user to every device;
-- the app keeps a copy on the device only as a cache. Null is the app's
-- default. theme is a name from the app's list, unchecked here so a new
-- theme needs no migration.
create table public.user_settings (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  theme text,
  shelf_view text check (shelf_view in ('covers', 'list'))
);

-- Clients upsert their own row; user_id comes from the default.
revoke insert, update on public.user_settings from anon, authenticated;
grant insert (theme, shelf_view), update (theme, shelf_view)
  on public.user_settings to authenticated;

alter table public.user_settings enable row level security;
create policy "Users read their own settings" on public.user_settings
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users add their own settings" on public.user_settings
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users change their own settings" on public.user_settings
  for update to authenticated using ((select auth.uid()) = user_id);
