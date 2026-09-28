create table if not exists public.learning_cloud_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.learning_cloud_state enable row level security;

drop policy if exists "learning_cloud_state_select_own"
  on public.learning_cloud_state;
create policy "learning_cloud_state_select_own"
on public.learning_cloud_state
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "learning_cloud_state_insert_own"
  on public.learning_cloud_state;
create policy "learning_cloud_state_insert_own"
on public.learning_cloud_state
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "learning_cloud_state_update_own"
  on public.learning_cloud_state;
create policy "learning_cloud_state_update_own"
on public.learning_cloud_state
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
