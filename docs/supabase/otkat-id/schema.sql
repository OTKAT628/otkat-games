-- OTKAT ID — shared identity MVP schema for Supabase
-- Project: otkat-id
-- Apply this entire file once in Supabase Dashboard -> SQL Editor -> Run.
-- Safe to re-run: tables, indexes, triggers and policies are created idempotently.
-- Never put the Supabase service_role key in a client app.

begin;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.game_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  game_id text not null check (char_length(game_id) between 1 and 120),
  slot text not null default 'default' check (char_length(slot) between 1 and 80),
  save_data jsonb not null default '{}'::jsonb,
  game_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint game_saves_user_game_slot_unique unique (user_id, game_id, slot)
);

create table if not exists public.leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  game_id text not null check (char_length(game_id) between 1 and 120),
  leaderboard_id text not null default 'global' check (char_length(leaderboard_id) between 1 and 80),
  user_id uuid not null references auth.users (id) on delete cascade,
  score numeric(20, 4) not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists game_saves_user_id_idx
  on public.game_saves (user_id);
create index if not exists game_saves_game_id_idx
  on public.game_saves (game_id);
create index if not exists leaderboard_game_score_idx
  on public.leaderboard_entries (game_id, leaderboard_id, score desc);
create index if not exists leaderboard_user_id_idx
  on public.leaderboard_entries (user_id);

-- Keep updated_at current when a profile or save is changed.
create or replace function public.otkat_set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.otkat_set_updated_at();

drop trigger if exists game_saves_set_updated_at on public.game_saves;
create trigger game_saves_set_updated_at
before update on public.game_saves
for each row execute function public.otkat_set_updated_at();

-- Create a safe public profile row whenever Supabase Auth creates a user.
-- Username is derived from supplied metadata/email and gets a short unique suffix.
create or replace function public.otkat_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  base_username text;
  generated_username text;
  generated_display_name text;
begin
  base_username := lower(
    regexp_replace(
      coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
        nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
        'user'
      ),
      '[^a-zA-Z0-9_]+',
      '_',
      'g'
    )
  );

  base_username := trim(both '_' from base_username);
  if base_username = '' then
    base_username := 'user';
  end if;

  generated_username :=
    left(base_username, 24) || '_' ||
    left(replace(new.id::text, '-', ''), 8);

  generated_display_name := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Игрок OTKAT'
  );

  insert into public.profiles (id, username, display_name)
  values (new.id, generated_username, generated_display_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_otkat on auth.users;
create trigger on_auth_user_created_otkat
after insert on auth.users
for each row execute function public.otkat_handle_new_user();

-- Enable row-level security on every user-facing table.
alter table public.profiles enable row level security;
alter table public.game_saves enable row level security;
alter table public.leaderboard_entries enable row level security;

-- Remove policies first so this script can safely be re-applied.
drop policy if exists "Profiles are readable by signed-in users" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Users can read their own game saves" on public.game_saves;
drop policy if exists "Users can create their own game saves" on public.game_saves;
drop policy if exists "Users can update their own game saves" on public.game_saves;
drop policy if exists "Users can delete their own game saves" on public.game_saves;
drop policy if exists "Signed-in users can read leaderboard entries" on public.leaderboard_entries;
drop policy if exists "Users can submit their own leaderboard entries" on public.leaderboard_entries;

-- Profiles contain only public-facing fields; email and auth credentials stay in auth.users.
create policy "Profiles are readable by signed-in users"
on public.profiles for select
to authenticated
using (true);

create policy "Users can update their own profile"
on public.profiles for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy "Users can read their own game saves"
on public.game_saves for select
to authenticated
using (user_id = (select auth.uid()));

create policy "Users can create their own game saves"
on public.game_saves for insert
to authenticated
with check (user_id = (select auth.uid()));

create policy "Users can update their own game saves"
on public.game_saves for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "Users can delete their own game saves"
on public.game_saves for delete
to authenticated
using (user_id = (select auth.uid()));

create policy "Signed-in users can read leaderboard entries"
on public.leaderboard_entries for select
to authenticated
using (true);

create policy "Users can submit their own leaderboard entries"
on public.leaderboard_entries for insert
to authenticated
with check (user_id = (select auth.uid()));

-- Explicit table grants: no anonymous access; signed-in users are still restricted by RLS.
revoke all on table public.profiles from anon;
revoke all on table public.game_saves from anon;
revoke all on table public.leaderboard_entries from anon;

grant select, update on table public.profiles to authenticated;
grant select, insert, update, delete on table public.game_saves to authenticated;
grant select, insert on table public.leaderboard_entries to authenticated;

commit;
