-- OTKAT ID MVP schema
-- Apply to a Supabase project via SQL Editor or Supabase CLI.
-- Client apps must use the anon/publishable key only. Never ship service_role.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null default 'Player',
  avatar_key text not null default 'default',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_format check (username ~ '^[A-Za-z0-9_]{3,20}$')
);

create table if not exists public.game_saves (
  user_id uuid not null references auth.users(id) on delete cascade,
  game_id text not null,
  save_slot text not null default 'main',
  save_data jsonb not null default '{}'::jsonb,
  revision bigint not null default 1,
  updated_at timestamptz not null default now(),
  primary key (user_id, game_id, save_slot),
  constraint game_saves_game_id_format check (game_id ~ '^[a-z0-9-]{2,48}$'),
  constraint game_saves_save_size check (pg_column_size(save_data) <= 262144)
);

-- Public read model. Writes are deliberately denied to client roles.
-- A trusted game backend must validate a run before inserting/updating a score.
create table if not exists public.leaderboard_entries (
  id bigint generated always as identity primary key,
  game_id text not null,
  season_id text not null default 'all-time',
  user_id uuid not null references auth.users(id) on delete cascade,
  score bigint not null,
  metadata jsonb not null default '{}'::jsonb,
  achieved_at timestamptz not null default now(),
  constraint leaderboard_game_id_format check (game_id ~ '^[a-z0-9-]{2,48}$'),
  constraint leaderboard_score_nonnegative check (score >= 0),
  constraint leaderboard_metadata_size check (pg_column_size(metadata) <= 4096)
);

create index if not exists leaderboard_lookup_idx
  on public.leaderboard_entries (game_id, season_id, score desc, achieved_at asc);

create index if not exists leaderboard_user_idx
  on public.leaderboard_entries (user_id, game_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  candidate text;
begin
  candidate := coalesce(
    nullif(new.raw_user_meta_data ->> 'username', ''),
    'player_' || substr(replace(new.id::text, '-', ''), 1, 10)
  );
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    candidate,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), 'Player')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.game_saves enable row level security;
alter table public.leaderboard_entries enable row level security;

-- Profiles are public for display in rankings; users may only edit their own row.
drop policy if exists "profiles are readable" on public.profiles;
create policy "profiles are readable"
  on public.profiles for select to anon, authenticated using (true);

drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile"
  on public.profiles for insert to authenticated with check (auth.uid() = id);

drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile"
  on public.profiles for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "users read own saves" on public.game_saves;
create policy "users read own saves"
  on public.game_saves for select to authenticated using (auth.uid() = user_id);

drop policy if exists "users create own saves" on public.game_saves;
create policy "users create own saves"
  on public.game_saves for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "users update own saves" on public.game_saves;
create policy "users update own saves"
  on public.game_saves for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "users delete own saves" on public.game_saves;
create policy "users delete own saves"
  on public.game_saves for delete to authenticated using (auth.uid() = user_id);

drop policy if exists "leaderboards are public" on public.leaderboard_entries;
create policy "leaderboards are public"
  on public.leaderboard_entries for select to anon, authenticated using (true);

revoke insert, update, delete on public.leaderboard_entries from anon, authenticated;
grant select on public.leaderboard_entries to anon, authenticated;
grant select, insert, update, delete on public.game_saves to authenticated;
grant select on public.profiles to anon, authenticated;
grant insert, update on public.profiles to authenticated;
