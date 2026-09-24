-- 植物標本帖 (hyohoncho) - Supabase schema
-- 既存プロジェクトに相乗りする前提で、テーブル名はすべて plant_ 接頭辞にしています。
-- Supabaseダッシュボード > SQL Editor に貼り付けて実行してください。

-- ---------- plants ----------
create table if not exists plant_plants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  species text,
  acquired_date date,
  group_name text,
  status text not null default 'growing',
  source text,
  location text,
  notes text,
  photo_path text,
  sample boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- growth logs (per plant) ----------
create table if not exists plant_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  plant_id uuid not null references plant_plants(id) on delete cascade,
  date date not null,
  type text not null,
  method text,
  note text,
  photo_path text,
  created_at timestamptz not null default now()
);

-- ---------- shop visits ----------
create table if not exists plant_shops (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  area text,
  visit_date date,
  rating int,
  notes text,
  photo_path text,
  sample boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- wishlist ----------
create table if not exists plant_wishlist (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  species text,
  price text,
  candidate_shop text,
  notes text,
  photo_path text,
  sample boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- schedule ----------
create table if not exists plant_schedule (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  plant_id uuid references plant_plants(id) on delete set null,
  plant_name text,
  title text not null,
  due_date date,
  done boolean not null default false,
  sample boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- environment logs ----------
create table if not exists plant_env_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date date not null,
  temp numeric,
  humidity numeric,
  soil_temp numeric,
  note text,
  sample boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- row level security: everyone only ever sees/writes their own rows ----------
alter table plant_plants enable row level security;
alter table plant_logs enable row level security;
alter table plant_shops enable row level security;
alter table plant_wishlist enable row level security;
alter table plant_schedule enable row level security;
alter table plant_env_logs enable row level security;

create policy "own rows only" on plant_plants for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only" on plant_logs for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only" on plant_shops for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only" on plant_wishlist for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only" on plant_schedule for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only" on plant_env_logs for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- storage bucket for photos (private; accessed via signed URLs) ----------
insert into storage.buckets (id, name, public)
values ('plant-photos', 'plant-photos', false)
on conflict (id) do nothing;

create policy "upload own plant photos" on storage.objects for insert
  with check (bucket_id = 'plant-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "view own plant photos" on storage.objects for select
  using (bucket_id = 'plant-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "delete own plant photos" on storage.objects for delete
  using (bucket_id = 'plant-photos' and (storage.foldername(name))[1] = auth.uid()::text);
