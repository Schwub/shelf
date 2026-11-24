-- Albums added from a friend's shelf remember whose shelf it was (M2).
-- The name is kept as it was, so the note survives a deleted account.
alter table public.shelf_entries
  add column added_from_user_id uuid references auth.users on delete set null,
  add column added_from_name text check (btrim(added_from_name) <> ''),
  add check (added_from_user_id is null or added_from_name is not null);
