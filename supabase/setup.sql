-- Beyond Basics: secure learner progress, starting assessments, chapter results, and founder reporting.
-- Run the entire file in Supabase Dashboard > SQL Editor.
-- Browser code uses only the public/publishable key. Never put a service-role key in the website.

create table if not exists public.learner_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  completed_lessons jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);
-- Safely align older installations that used text[] for completed_lessons.
alter table public.learner_progress alter column completed_lessons drop default;
alter table public.learner_progress alter column completed_lessons type jsonb
  using case when completed_lessons is null then '[]'::jsonb else to_jsonb(completed_lessons) end;
alter table public.learner_progress alter column completed_lessons set default '[]'::jsonb;
alter table public.learner_progress alter column completed_lessons set not null;
alter table public.learner_progress enable row level security;

drop policy if exists "Students can read their own progress" on public.learner_progress;
drop policy if exists "Students can create their own progress" on public.learner_progress;
drop policy if exists "Students can update their own progress" on public.learner_progress;
create policy "Students can read their own progress" on public.learner_progress for select to authenticated using ((select auth.uid()) = user_id);
create policy "Students can create their own progress" on public.learner_progress for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Students can update their own progress" on public.learner_progress for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
revoke all on public.learner_progress from anon, public;
grant select, insert, update on public.learner_progress to authenticated;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
drop policy if exists "Supervisors can read their own role" on public.admin_users;
create policy "Supervisors can read their own role" on public.admin_users for select to authenticated using ((select auth.uid()) = user_id);
revoke all on public.admin_users from anon, public;
revoke insert, update, delete on public.admin_users from authenticated;
grant select on public.admin_users to authenticated;

create table if not exists public.learner_baseline_assessments (
  user_id uuid not null references auth.users(id) on delete cascade,
  assessment_type text not null check (assessment_type in ('english','digital')),
  answers jsonb not null default '[]'::jsonb,
  score integer not null default 0 check (score >= 0),
  total_questions integer not null default 0 check (total_questions >= 0),
  completed_at timestamptz not null default now(),
  primary key (user_id, assessment_type)
);
alter table public.learner_baseline_assessments enable row level security;
drop policy if exists "Learners read own baseline assessments" on public.learner_baseline_assessments;
drop policy if exists "Learners create own baseline assessments" on public.learner_baseline_assessments;
drop policy if exists "Learners update own baseline assessments" on public.learner_baseline_assessments;
create policy "Learners read own baseline assessments" on public.learner_baseline_assessments for select to authenticated using ((select auth.uid()) = user_id);
create policy "Learners create own baseline assessments" on public.learner_baseline_assessments for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Learners update own baseline assessments" on public.learner_baseline_assessments for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
revoke all on public.learner_baseline_assessments from anon, public;
grant select, insert, update on public.learner_baseline_assessments to authenticated;

create table if not exists public.learner_chapter_results (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id text not null,
  responses jsonb not null default '{}'::jsonb,
  score integer not null default 0 check (score >= 0),
  total_questions integer not null default 0 check (total_questions >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);
alter table public.learner_chapter_results enable row level security;
drop policy if exists "Learners read own chapter results" on public.learner_chapter_results;
drop policy if exists "Learners create own chapter results" on public.learner_chapter_results;
drop policy if exists "Learners update own chapter results" on public.learner_chapter_results;
create policy "Learners read own chapter results" on public.learner_chapter_results for select to authenticated using ((select auth.uid()) = user_id);
create policy "Learners create own chapter results" on public.learner_chapter_results for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Learners update own chapter results" on public.learner_chapter_results for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
revoke all on public.learner_chapter_results from anon, public;
grant select, insert, update on public.learner_chapter_results to authenticated;

-- Store a private founder-visible copy while the existing Formspree delivery remains enabled.
create table if not exists public.form_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  form_type text not null check (form_type in ('enquiry','suggestion')),
  name text not null default '',
  email text not null default '',
  topic text not null default '',
  message text not null default '',
  created_at timestamptz not null default now(),
  check (char_length(name) <= 100),
  check (char_length(email) <= 180),
  check (char_length(topic) <= 150),
  check (char_length(message) <= 1500)
);
alter table public.form_submissions enable row level security;
drop policy if exists "Public can submit contact and suggestion forms" on public.form_submissions;
create policy "Public can submit contact and suggestion forms" on public.form_submissions
  for insert to anon, authenticated
  with check (form_type in ('enquiry','suggestion') and char_length(message) <= 1500 and (user_id is null or user_id = (select auth.uid())));
revoke all on public.form_submissions from public;
revoke select, update, delete on public.form_submissions from anon, authenticated;
grant insert on public.form_submissions to anon, authenticated;

drop function if exists public.admin_student_overview();
create function public.admin_student_overview()
returns table (user_id uuid, email text, created_at timestamptz, completed_lessons jsonb, updated_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())) then
    raise exception 'Supervisor access required' using errcode = '42501';
  end if;
  return query
    select u.id, u.email::text, u.created_at, coalesce(lp.completed_lessons, '[]'::jsonb), lp.updated_at
    from auth.users u left join public.learner_progress lp on lp.user_id = u.id
    where not exists (select 1 from public.admin_users a where a.user_id = u.id)
    order by u.created_at desc;
end;
$$;
revoke all on function public.admin_student_overview() from public, anon;
grant execute on function public.admin_student_overview() to authenticated;

drop function if exists public.admin_assessment_overview();
create function public.admin_assessment_overview()
returns table (user_id uuid, email text, assessment_type text, answers jsonb, score integer, total_questions integer, completed_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())) then
    raise exception 'Supervisor access required' using errcode = '42501';
  end if;
  return query
    select b.user_id, u.email::text, b.assessment_type, b.answers, b.score, b.total_questions, b.completed_at
    from public.learner_baseline_assessments b join auth.users u on u.id = b.user_id
    where not exists (select 1 from public.admin_users a where a.user_id = b.user_id)
    order by b.completed_at desc;
end;
$$;
revoke all on function public.admin_assessment_overview() from public, anon;
grant execute on function public.admin_assessment_overview() to authenticated;

drop function if exists public.admin_chapter_results();
create function public.admin_chapter_results()
returns table (user_id uuid, email text, lesson_id text, responses jsonb, score integer, total_questions integer, updated_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())) then
    raise exception 'Supervisor access required' using errcode = '42501';
  end if;
  return query
    select c.user_id, u.email::text, c.lesson_id, c.responses, c.score, c.total_questions, c.updated_at
    from public.learner_chapter_results c join auth.users u on u.id = c.user_id
    where not exists (select 1 from public.admin_users a where a.user_id = c.user_id)
    order by c.updated_at desc;
end;
$$;
revoke all on function public.admin_chapter_results() from public, anon;
grant execute on function public.admin_chapter_results() to authenticated;

drop function if exists public.admin_form_submissions();
create function public.admin_form_submissions()
returns table (id uuid, form_type text, name text, email text, topic text, message text, created_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())) then
    raise exception 'Supervisor access required' using errcode = '42501';
  end if;
  return query
    select f.id, f.form_type, f.name, f.email, f.topic, f.message, f.created_at
    from public.form_submissions f
    order by f.created_at desc;
end;
$$;
revoke all on function public.admin_form_submissions() from public, anon;
grant execute on function public.admin_form_submissions() to authenticated;
