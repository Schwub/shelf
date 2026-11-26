-- Friends and invites (TASK-36, docs/features/friends.md). Friendships are
-- mutual and start from an invite: a code, used once, valid 7 days.

-- Two rows per friendship, (me, Anna) and (Anna, me), so every lookup is
-- by user_id. Written only by accept_invite and remove_friend, which keep
-- both rows together.
create table public.friendships (
  user_id uuid not null references auth.users on delete cascade,
  friend_id uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);
revoke insert, update, delete on public.friendships from anon, authenticated;
alter table public.friendships enable row level security;
create policy "Users read their own friendships" on public.friendships
  for select to authenticated using ((select auth.uid()) = user_id);

-- Codes are stored without the dash, in capitals; the alphabet leaves out
-- 0, O, 1, I and L, which are easy to mix up.
create table public.invites (
  code text primary key check (code ~ '^[A-HJKMNP-Z2-9]{8}$'),
  inviter uuid not null references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days',
  accepted_by uuid references auth.users on delete set null,
  accepted_at timestamptz
);
create index on public.invites (inviter);
revoke insert, update on public.invites from anon, authenticated;
alter table public.invites enable row level security;
create policy "Users read their own invites" on public.invites
  for select to authenticated using ((select auth.uid()) = inviter);
-- Cancelling an invite that waits; used ones stay as a record.
create policy "Users cancel their own waiting invites" on public.invites
  for delete to authenticated
  using ((select auth.uid()) = inviter and accepted_by is null);

create function public.is_friend(other uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.friendships
    where user_id = (select auth.uid()) and friend_id = other
  );
$$;

-- K7Q2-M9XD, k7q2m9xd and " K7Q2 M9XD " are the same code.
create function public.invite_code(input text) returns text
language sql immutable set search_path = '' as $$
  select upper(regexp_replace(input, '[^A-Za-z0-9]', '', 'g'));
$$;

create function public.create_invite() returns text
language plpgsql volatile security definer set search_path = '' as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  new_code text;
begin
  loop
    select string_agg(substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1), '')
      into new_code from generate_series(1, 8);
    begin
      insert into public.invites (code, inviter) values (new_code, auth.uid());
      return new_code;
    exception when unique_violation then
      -- Taken already: try another.
    end;
  end loop;
end;
$$;

-- What the Invitation screen shows before Accept: valid, gone (expired,
-- used or cancelled), own, friends (already) or unknown, and who invited.
create function public.invite_preview(input text)
returns table (status text, inviter_id uuid, inviter_name text)
language sql stable security definer set search_path = '' as $$
  select
    case
      when i.code is null then 'unknown'
      when i.inviter = (select auth.uid()) then 'own'
      when exists (select 1 from public.friendships f
                   where f.user_id = (select auth.uid()) and f.friend_id = i.inviter)
        then 'friends'
      when i.accepted_by is not null or i.expires_at <= now() then 'gone'
      else 'valid'
    end,
    case when i.inviter <> (select auth.uid()) then i.inviter end,
    p.name
  from (select public.invite_code(input) as code) c
  left join public.invites i on i.code = c.code
  left join public.profiles p on p.user_id = i.inviter;
$$;

-- Makes the caller and the inviter friends and uses up the invite, or
-- raises the preview's status ('unknown', 'own', 'friends', 'gone') as the
-- error message (SQLSTATE P0001). Returns the inviter.
create function public.accept_invite(input text) returns uuid
language plpgsql volatile security definer set search_path = '' as $$
declare
  me constant uuid := auth.uid();
  invite public.invites;
begin
  select * into invite from public.invites
    where code = public.invite_code(input) for update;
  if invite.code is null then raise exception 'unknown'; end if;
  if invite.inviter = me then raise exception 'own'; end if;
  if exists (select 1 from public.friendships where user_id = me and friend_id = invite.inviter) then
    raise exception 'friends';
  end if;
  if invite.accepted_by is not null or invite.expires_at <= now() then
    raise exception 'gone';
  end if;
  update public.invites set accepted_by = me, accepted_at = now() where code = invite.code;
  insert into public.friendships (user_id, friend_id)
    values (me, invite.inviter), (invite.inviter, me);
  return invite.inviter;
end;
$$;

create function public.remove_friend(friend uuid) returns void
language sql volatile security definer set search_path = '' as $$
  delete from public.friendships
  where (user_id = (select auth.uid()) and friend_id = friend)
     or (user_id = friend and friend_id = (select auth.uid()));
$$;

revoke execute on function public.is_friend(uuid), public.create_invite(),
  public.invite_preview(text), public.accept_invite(text),
  public.remove_friend(uuid) from public, anon;
grant execute on function public.is_friend(uuid), public.create_invite(),
  public.invite_preview(text), public.accept_invite(text),
  public.remove_friend(uuid) to authenticated;

create policy "Friends read each other's profiles" on public.profiles
  for select to authenticated using (public.is_friend(user_id));
