-- The name friends see (TASK-35, docs/features/friends.md). Asked once after
-- the first sign-in; not unique. Friends read it from TASK-36 on.
create table public.profiles (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  name text not null check (name = btrim(name) and char_length(name) between 1 and 40),
  created_at timestamptz not null default now()
);

-- Clients upsert their own name; user_id comes from the default.
revoke insert, update on public.profiles from anon, authenticated;
grant insert (name), update (name) on public.profiles to authenticated;

alter table public.profiles enable row level security;
create policy "Users read their own profile" on public.profiles
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users add their own profile" on public.profiles
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users change their own profile" on public.profiles
  for update to authenticated using ((select auth.uid()) = user_id);
