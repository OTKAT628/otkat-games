-- OTKAT ID starter schema. Apply with Supabase SQL Editor or Supabase CLI.
-- Client apps use only the Supabase publishable/anon key. Never ship service_role.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Player'
    check (char_length(display_name) between 1 and 32),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create table if not exists public.game_saves (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  game_slug text not null check (game_slug ~ '^[a-z0-9-]{2,48}$'),
  slot_key text not null default 'default'
    check (char_length(slot_key) between 1 and 48),
  payload jsonb not null default '{}'::jsonb,
  revision bigint not null default 1 check (revision > 0),
  updated_at timestamptz not null default now(),
  unique (user_id, game_slug, slot_key)
);

drop trigger if exists game_saves_set_updated_at on public.game_saves;
create trigger game_saves_set_updated_at
before update on public.game_saves
for each row execute function public.set_updated_at();

create table if not exists public.leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  game_slug text not null check (game_slug ~ '^[a-z0-9-]{2,48}$'),
  user_id uuid not null references auth.users(id) on delete cascade,
  score bigint not null check (score >= 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists leaderboard_game_score_idx
  on public.leaderboard_entries (game_slug, score desc, created_at asc);
create index if not exists game_saves_user_game_idx
  on public.game_saves (user_id, game_slug);

alter table public.profiles enable row level security;
alter table public.game_saves enable row level security;
alter table public.leaderboard_entries enable row level security;

-- Public player cards; only the authenticated owner may create or edit their row.
drop policy if exists "Profiles are readable" on public.profiles;
create policy "Profiles are readable"
  on public.profiles for select
  using (true);

drop policy if exists "Users create their own profile" on public.profiles;
create policy "Users create their own profile"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "Users update their own profile" on public.profiles;
create policy "Users update their own profile"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- A player can access only their own cloud saves.
drop policy if exists "Users read their own saves" on public.game_saves;
create policy "Users read their own saves"
  on public.game_saves for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users create their own saves" on public.game_saves;
create policy "Users create their own saves"
  on public.game_saves for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users update their own saves" on public.game_saves;
create policy "Users update their own saves"
  on public.game_saves for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users delete their own saves" on public.game_saves;
create policy "Users delete their own saves"
  on public.game_saves for delete
  to authenticated
  using (auth.uid() = user_id);

-- Leaderboards are publicly readable, but clients cannot submit scores directly.
-- Add a server/Edge Function with anti-cheat validation before granting write access.
drop policy if exists "Leaderboards are readable" on public.leaderboard_entries;
create policy "Leaderboards are readable"
  on public.leaderboard_entries for select
  using (true);

-- No INSERT/UPDATE/DELETE policy is intentionally created for leaderboard_entries.
-- Supabase service_role bypasses RLS and must remain server-side only.
