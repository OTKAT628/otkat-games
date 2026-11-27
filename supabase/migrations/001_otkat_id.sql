-- OTKAT ID initial schema for Supabase.
-- Safe to run more than once. Apply in Supabase SQL Editor to the otkat-id project.
-- Client apps must use only the publishable/anon key. Never ship service_role.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null default 'Игрок',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (username ~ '^[a-zA-Z0-9_]{3,24}$')
);

create table if not exists public.leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  game_slug text not null check (game_slug in (
    'hide-and-seek','survival','driftline','arena','forgotten',
    'skyrun','racing','space','magic','prehistoric',
    'arcade-mix','puzzle-lab','party-duo','action-rush','cozy-worlds'
  )),
  user_id uuid not null references auth.users(id) on delete cascade,
  score bigint not null check (score >= 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.cloud_saves (
  user_id uuid not null references auth.users(id) on delete cascade,
  game_slug text not null check (game_slug in (
    'hide-and-seek','survival','driftline','arena','forgotten',
    'skyrun','racing','space','magic','prehistoric',
    'arcade-mix','puzzle-lab','party-duo','action-rush','cozy-worlds'
  )),
  save_data jsonb not null default '{}'::jsonb,
  revision bigint not null default 1 check (revision > 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, game_slug)
);

create index if not exists leaderboard_game_score_idx
  on public.leaderboard_entries (game_slug, score desc, created_at asc);
create index if not exists leaderboard_user_idx
  on public.leaderboard_entries (user_id, game_slug);
create index if not exists cloud_saves_updated_idx
  on public.cloud_saves (updated_at desc);

create or replace function public.otkat_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.otkat_touch_updated_at();

drop trigger if exists cloud_saves_touch_updated_at on public.cloud_saves;
create trigger cloud_saves_touch_updated_at
before update on public.cloud_saves
for each row execute function public.otkat_touch_updated_at();

create or replace function public.otkat_create_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Generate a unique default username so duplicate signup metadata cannot
  -- cause the auth.users insert itself to fail. The player can edit it later.
  insert into public.profiles (user_id, username, display_name)
  values (
    new.id,
    'player_' || substr(replace(new.id::text, '-', ''), 1, 12),
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), 'Игрок')
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_otkat on auth.users;
create trigger on_auth_user_created_otkat
after insert on auth.users
for each row execute function public.otkat_create_profile();

alter table public.profiles enable row level security;
alter table public.leaderboard_entries enable row level security;
alter table public.cloud_saves enable row level security;

drop policy if exists "Profiles are publicly readable" on public.profiles;
create policy "Profiles are publicly readable"
on public.profiles for select
to anon, authenticated
using (true);

drop policy if exists "Users update their own profile" on public.profiles;
create policy "Users update their own profile"
on public.profiles for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Leaderboard is publicly readable" on public.leaderboard_entries;
create policy "Leaderboard is publicly readable"
on public.leaderboard_entries for select
to anon, authenticated
using (true);

drop policy if exists "Users submit their own scores" on public.leaderboard_entries;
create policy "Users submit their own scores"
on public.leaderboard_entries for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users update their own scores" on public.leaderboard_entries;
create policy "Users update their own scores"
on public.leaderboard_entries for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users read their own saves" on public.cloud_saves;
create policy "Users read their own saves"
on public.cloud_saves for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users create their own saves" on public.cloud_saves;
create policy "Users create their own saves"
on public.cloud_saves for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users update their own saves" on public.cloud_saves;
create policy "Users update their own saves"
on public.cloud_saves for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users delete their own saves" on public.cloud_saves;
create policy "Users delete their own saves"
on public.cloud_saves for delete
to authenticated
using (auth.uid() = user_id);

grant select on public.profiles to anon, authenticated;
grant update on public.profiles to authenticated;
grant select on public.leaderboard_entries to anon, authenticated;
grant insert, update on public.leaderboard_entries to authenticated;
grant select, insert, update, delete on public.cloud_saves to authenticated;

-- IMPORTANT MVP LIMITATION:
-- RLS ensures users can only write rows under their own user_id.
-- It does NOT prove that a submitted score is honest. Before competitive/global
-- ranked play, route score submissions through a server-authoritative validator
-- or Edge Function and restrict direct client writes.
