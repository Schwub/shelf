create extension if not exists moddatetime schema extensions;

create type public.shelf_status as enum ('own', 'want', 'listened');

create table public.albums (
  id uuid primary key default gen_random_uuid(),
  -- MusicBrainz release group, so different editions of an album match;
  -- null for shared links that didn't resolve to MusicBrainz.
  musicbrainz_id uuid unique,
  title text not null,
  artist text not null,
  year smallint,
  cover_url text,
  created_at timestamptz not null default now()
);

alter table public.albums enable row level security;

create policy "Signed-in users read albums"
  on public.albums for select to authenticated
  using (true);

create policy "Signed-in users add albums"
  on public.albums for insert to authenticated
  with check (true);

create table public.shelf_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  album_id uuid not null references public.albums,
  status public.shelf_status not null,
  -- Half stars: 1 = 0.5 stars, 10 = 5 stars.
  rating smallint check (rating between 1 and 10),
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, album_id)
);

create index on public.shelf_entries (album_id);

create trigger shelf_entries_updated_at
  before update on public.shelf_entries
  for each row execute function extensions.moddatetime(updated_at);

alter table public.shelf_entries enable row level security;

create policy "Users read their own shelf entries"
  on public.shelf_entries for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users add their own shelf entries"
  on public.shelf_entries for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users update their own shelf entries"
  on public.shelf_entries for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users delete their own shelf entries"
  on public.shelf_entries for delete to authenticated
  using ((select auth.uid()) = user_id);
