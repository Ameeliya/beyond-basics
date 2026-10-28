-- Beyond Basics: secure per-student learning progress
-- Run this file in Supabase Dashboard > SQL Editor for the project used by index.html.

create table if not exists public.learner_progress (
  user_id uuid primary key references auth.users (id) on delete cascade,
  completed_lessons text[] not null default '{}'::text[],
  updated_at timestamptz not null default now()
);

alter table public.learner_progress enable row level security;

-- Recreate policies safely if this script is run again.
drop policy if exists "Students can read their own progress" on public.learner_progress;
drop policy if exists "Students can create their own progress" on public.learner_progress;
drop policy if exists "Students can update their own progress" on public.learner_progress;

create policy "Students can read their own progress"
  on public.learner_progress
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Students can create their own progress"
  on public.learner_progress
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Students can update their own progress"
  on public.learner_progress
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.learner_progress from anon, public;
grant select, insert, update on public.learner_progress to authenticated;
