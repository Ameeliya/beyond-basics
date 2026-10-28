-- Beyond Basics: account-based learner progress
-- Run this in Supabase Dashboard > SQL Editor > New query.
-- This stores each learner's completed lesson IDs against their authenticated account.

create table if not exists public.learner_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  completed_lessons jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.learner_progress enable row level security;

grant select, insert, update on public.learner_progress to authenticated;

drop policy if exists "Learners can read their own progress" on public.learner_progress;
create policy "Learners can read their own progress"
  on public.learner_progress for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Learners can insert their own progress" on public.learner_progress;
create policy "Learners can insert their own progress"
  on public.learner_progress for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Learners can update their own progress" on public.learner_progress;
create policy "Learners can update their own progress"
  on public.learner_progress for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
