-- ============================================================================
-- RESONANCE · backend schema · v1
-- ============================================================================
-- Run this in the Supabase SQL editor of a fresh project. It sets up every
-- table the app reads/writes, plus row-level security policies so each user
-- sees only their own private data while sharing what's meant to be shared
-- (Convergence counts, public Soul Notes lines, wavelength room presence).
-- ============================================================================

-- ---------- enable extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ---------- profiles · one row per auth user
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null default 'Soul',
  birth       date,
  tradition   text not null default 'universal',
  zodiac_sign text,
  zodiac_element text,
  numerology  int,
  voice_pitch numeric,
  voice_gender text,
  current_freq int default 432,
  light_index int default 24,
  closeness   int default 0,
  trust       int default 0,
  tier        text not null default 'free' check (tier in ('free','pro','proplus')),
  founding    boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
alter table public.profiles enable row level security;
create policy "profiles · self read"  on public.profiles for select using (auth.uid() = id);
create policy "profiles · self write" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "profiles · self insert" on public.profiles for insert with check (auth.uid() = id);

-- ---------- arrivals · login moments
create table if not exists public.arrivals (
  id        uuid primary key default uuid_generate_v4(),
  user_id   uuid not null references public.profiles(id) on delete cascade,
  t         timestamptz not null default now(),
  hour      int not null,
  minute    int not null,
  n         int not null,
  day       date not null default current_date
);
create index if not exists arrivals_user_day_idx on public.arrivals(user_id, day desc);
alter table public.arrivals enable row level security;
create policy "arrivals · self all" on public.arrivals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- locker_visits · every manual sync session
create table if not exists public.locker_visits (
  id      uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  hz      int not null,
  t       timestamptz not null default now()
);
create index if not exists locker_visits_user_hz_idx on public.locker_visits(user_id, hz);
alter table public.locker_visits enable row level security;
create policy "locker_visits · self all" on public.locker_visits for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- locker_notes · user notes per wavelength
create table if not exists public.locker_notes (
  id      uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  hz      int not null,
  text    text not null,
  t       timestamptz not null default now()
);
create index if not exists locker_notes_user_hz_t_idx on public.locker_notes(user_id, hz, t desc);
alter table public.locker_notes enable row level security;
create policy "locker_notes · self all" on public.locker_notes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- soul_facts · feeling-words + reason clauses extracted from chat
create table if not exists public.soul_facts (
  id      uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind    text not null check (kind in ('feeling','reason')),
  value   text not null,
  t       timestamptz not null default now()
);
create index if not exists soul_facts_user_t_idx on public.soul_facts(user_id, t desc);
alter table public.soul_facts enable row level security;
create policy "soul_facts · self all" on public.soul_facts for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- inner_chat · the continuous chat history
create table if not exists public.inner_chat (
  id      uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  who     text not null check (who in ('you','self')),
  text    text not null,
  t       timestamptz not null default now()
);
create index if not exists inner_chat_user_t_idx on public.inner_chat(user_id, t desc);
alter table public.inner_chat enable row level security;
create policy "inner_chat · self all" on public.inner_chat for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- memories · captured single moments
create table if not exists public.memories (
  id      uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  hz      int not null,
  label   text,
  t       timestamptz not null default now()
);
create index if not exists memories_user_t_idx on public.memories(user_id, t desc);
alter table public.memories enable row level security;
create policy "memories · self all" on public.memories for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- daily_affirmations · what self said to user today
create table if not exists public.daily_affirmations (
  user_id uuid not null references public.profiles(id) on delete cascade,
  day     date not null,
  line    text not null,
  created_at timestamptz not null default now(),
  primary key (user_id, day)
);
alter table public.daily_affirmations enable row level security;
create policy "affirm · self all" on public.daily_affirmations for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ============================================================================
-- shared surfaces — everyone reads, server keeps the counts honest
-- ============================================================================

-- ---------- convergence_participations · which souls held the tone today
create table if not exists public.convergence_participations (
  user_id uuid not null references public.profiles(id) on delete cascade,
  day     date not null,
  hz      int not null,
  joined_at timestamptz not null default now(),
  primary key (user_id, day)
);
create index if not exists conv_day_hz_idx on public.convergence_participations(day, hz);
alter table public.convergence_participations enable row level security;
create policy "conv · self insert" on public.convergence_participations for insert with check (auth.uid() = user_id);
create policy "conv · self read"   on public.convergence_participations for select using (auth.uid() = user_id);

-- public count view (no user_ids leaked)
create or replace view public.convergence_count as
  select day, hz, count(*) as souls
  from public.convergence_participations
  group by day, hz;
grant select on public.convergence_count to anon, authenticated;

-- ---------- gratitudes · after the Convergence
create table if not exists public.gratitudes (
  id      uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  text    text not null,
  day     date not null default current_date,
  t       timestamptz not null default now(),
  hidden  boolean not null default false
);
create index if not exists grat_day_idx on public.gratitudes(day desc, t desc);
alter table public.gratitudes enable row level security;
create policy "grat · self insert" on public.gratitudes for insert with check (auth.uid() = user_id);
create policy "grat · self update" on public.gratitudes for update using (auth.uid() = user_id);
create policy "grat · public read" on public.gratitudes for select using (hidden = false);

-- ---------- soul_notes · public-but-anonymous lines reaching close-frequency souls
create table if not exists public.soul_notes (
  id              uuid primary key default uuid_generate_v4(),
  author_user_id  uuid not null references public.profiles(id) on delete cascade,
  freq            int not null,
  text            text not null,
  t               timestamptz not null default now(),
  expires_at      timestamptz not null default now() + interval '24 hours',
  hidden          boolean not null default false
);
create index if not exists notes_freq_t_idx on public.soul_notes(freq, t desc);
alter table public.soul_notes enable row level security;
create policy "notes · self insert" on public.soul_notes for insert with check (auth.uid() = author_user_id);
create policy "notes · self update" on public.soul_notes for update using (auth.uid() = author_user_id);
create policy "notes · public read" on public.soul_notes for select using (hidden = false and expires_at > now());

-- ---------- waves · one-soul-to-one wave (the frequency-only message)
create table if not exists public.waves (
  id           uuid primary key default uuid_generate_v4(),
  from_user_id uuid not null references public.profiles(id) on delete cascade,
  to_user_id   uuid not null references public.profiles(id) on delete cascade,
  freq         int not null,
  t            timestamptz not null default now(),
  received_at  timestamptz
);
create index if not exists waves_to_idx on public.waves(to_user_id, t desc);
alter table public.waves enable row level security;
create policy "waves · self send" on public.waves for insert with check (auth.uid() = from_user_id);
create policy "waves · self read" on public.waves for select using (auth.uid() = from_user_id or auth.uid() = to_user_id);
create policy "waves · self ack"  on public.waves for update using (auth.uid() = to_user_id);

-- ---------- wavelength_presence · live "I am in this room" pings
create table if not exists public.wavelength_presence (
  user_id        uuid not null references public.profiles(id) on delete cascade,
  wavelength_id  text not null,
  joined_at      timestamptz not null default now(),
  last_ping      timestamptz not null default now(),
  primary key (user_id, wavelength_id)
);
create index if not exists wp_wl_ping_idx on public.wavelength_presence(wavelength_id, last_ping desc);
alter table public.wavelength_presence enable row level security;
create policy "wp · self all" on public.wavelength_presence for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- public count view of who's "live" in each room right now (last 2 min)
create or replace view public.wavelength_live as
  select wavelength_id, count(*) as souls
  from public.wavelength_presence
  where last_ping > now() - interval '2 minutes'
  group by wavelength_id;
grant select on public.wavelength_live to anon, authenticated;

-- ---------- chamber_messages · the per-tier chat rooms
create table if not exists public.chamber_messages (
  id      uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  tier_n  int not null check (tier_n between 1 and 9),
  hz      int not null,
  text    text not null,
  t       timestamptz not null default now(),
  hidden  boolean not null default false
);
create index if not exists chamber_tier_t_idx on public.chamber_messages(tier_n, t desc);
alter table public.chamber_messages enable row level security;
create policy "chamber · self send"   on public.chamber_messages for insert with check (auth.uid() = user_id);
create policy "chamber · self update" on public.chamber_messages for update using (auth.uid() = user_id);
create policy "chamber · public read" on public.chamber_messages for select using (hidden = false);

-- ============================================================================
-- council applications · the 50-seat circle
-- ============================================================================
create table if not exists public.council_applications (
  id       uuid primary key default uuid_generate_v4(),
  user_id  uuid references public.profiles(id) on delete set null,
  name     text not null,
  email    text not null,
  why      text not null,
  bring    text not null,
  status   text not null default 'pending' check (status in ('pending','reviewing','offered','accepted','passed')),
  t        timestamptz not null default now()
);
alter table public.council_applications enable row level security;
create policy "apply · self insert" on public.council_applications for insert with check (auth.uid() = user_id or user_id is null);
create policy "apply · self read"   on public.council_applications for select using (auth.uid() = user_id);

-- ============================================================================
-- subscriptions · Stripe-backed
-- ============================================================================
create table if not exists public.subscriptions (
  user_id          uuid primary key references public.profiles(id) on delete cascade,
  tier             text not null check (tier in ('free','pro','proplus')) default 'free',
  stripe_customer  text,
  stripe_sub_id    text,
  status           text,
  current_period_end timestamptz,
  updated_at       timestamptz not null default now()
);
alter table public.subscriptions enable row level security;
create policy "subs · self read" on public.subscriptions for select using (auth.uid() = user_id);

-- ============================================================================
-- trigger · on new auth.user → create a profile row
-- ============================================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name) values (new.id, coalesce(new.raw_user_meta_data->>'name', 'Soul'));
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- realtime · enable change-streams for the surfaces that need them
-- ============================================================================
alter publication supabase_realtime add table public.convergence_participations;
alter publication supabase_realtime add table public.wavelength_presence;
alter publication supabase_realtime add table public.chamber_messages;
alter publication supabase_realtime add table public.gratitudes;
alter publication supabase_realtime add table public.waves;
