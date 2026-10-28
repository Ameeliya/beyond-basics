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


-- Private supervisor allowlist. Add the founder's authenticated user UUID here
-- from Supabase Dashboard > Authentication > Users, using the SQL editor.
create table if not exists public.admin_users (user_id uuid primary key references auth.users (id) on delete cascade,created_at timestamptz not null default now());
alter table public.admin_users enable row level security;
drop policy if exists "Supervisors can read their own role" on public.admin_users;
create policy "Supervisors can read their own role" on public.admin_users for select to authenticated using ((select auth.uid()) = user_id);
revoke all on public.admin_users from anon, public;
revoke insert, update, delete on public.admin_users from authenticated;
grant select on public.admin_users to authenticated;

drop function if exists public.admin_student_overview();
create function public.admin_student_overview()
returns table (user_id uuid,email text,created_at timestamptz,completed_lessons text[],updated_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.admin_users a where a.user_id = (select auth.uid())) then
    raise exception 'Supervisor access required' using errcode = '42501';
  end if;
  return query select u.id,u.email::text,u.created_at,coalesce(lp.completed_lessons, '{}'::text[]),lp.updated_at
    from auth.users u left join public.learner_progress lp on lp.user_id = u.id
    where not exists (select 1 from public.admin_users a where a.user_id = u.id)
    order by u.created_at desc;
end;
$$;
revoke all on function public.admin_student_overview() from public, anon;
grant execute on function public.admin_student_overview() to authenticated;
