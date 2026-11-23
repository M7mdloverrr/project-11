-- Classes, full homework lifecycle (assign → save → submit → grade/feedback) and live lessons.

create or replace function public.is_active_link(p_teacher uuid, p_student uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.teacher_student_links l
                  where l.teacher_id = p_teacher and l.student_id = p_student and l.status = 'active');
$$;

-- Classes -------------------------------------------------------------------
create table public.classes (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid not null references public.profiles (id) on delete cascade,
  name        text not null check (char_length(btrim(name)) between 1 and 80),
  created_at  timestamptz not null default now()
);
create table public.class_members (
  class_id    uuid not null references public.classes (id) on delete cascade,
  student_id  uuid not null references public.profiles (id) on delete cascade,
  added_at    timestamptz not null default now(),
  primary key (class_id, student_id)
);

alter table public.class_members enable row level security;
grant select, insert, update, delete on public.classes, public.class_members to authenticated, service_role;

-- Homework ------------------------------------------------------------------
create table public.homework (
  id              uuid primary key default gen_random_uuid(),
  teacher_id      uuid not null references public.profiles (id) on delete cascade,
  kind            text not null default 'lesson' check (kind in ('lesson', 'exercises', 'custom', 'study')),
  title           text not null default '' check (char_length(title) <= 120),
  instructions    text not null default '' check (char_length(instructions) <= 2000),
  lesson_id       uuid references public.lessons (id) on delete set null,
  item_ids        uuid[] not null default '{}',
  custom_items    jsonb not null default '[]'::jsonb check (jsonb_typeof(custom_items) = 'array'),
  class_id        uuid references public.classes (id) on delete set null,
  due_at          timestamptz,
  created_at      timestamptz not null default now()
);
create index homework_teacher_idx on public.homework (teacher_id, created_at desc);

create table public.homework_targets (
  homework_id uuid not null references public.homework (id) on delete cascade,
  student_id  uuid not null references public.profiles (id) on delete cascade,
  primary key (homework_id, student_id)
);
create index homework_targets_student_idx on public.homework_targets (student_id);

create table public.homework_submissions (
  id            uuid primary key default gen_random_uuid(),
  homework_id   uuid not null references public.homework (id) on delete cascade,
  student_id    uuid not null references public.profiles (id) on delete cascade,
  status        text not null default 'in_progress' check (status in ('in_progress', 'submitted', 'graded', 'returned')),
  answers       jsonb not null default '{}'::jsonb,
  auto_score    integer not null default 0,
  max_score     integer not null default 0,
  grade         integer check (grade between 0 and 100),
  feedback      text not null default '' check (char_length(feedback) <= 4000),
  corrections   jsonb not null default '{}'::jsonb,
  started_at    timestamptz not null default now(),
  submitted_at  timestamptz,
  graded_at     timestamptz,
  updated_at    timestamptz not null default now(),
  unique (homework_id, student_id)
);


create or replace function public.is_class_teacher(p_class uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.classes c where c.id = p_class and c.teacher_id = auth.uid());
$$;
create or replace function public.is_class_member(p_class uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.class_members m where m.class_id = p_class and m.student_id = auth.uid());
$$;
create or replace function public.is_homework_teacher(p_homework uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.homework h where h.id = p_homework and h.teacher_id = auth.uid());
$$;
create or replace function public.is_homework_target(p_homework uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.homework_targets t where t.homework_id = p_homework and t.student_id = auth.uid());
$$;

alter table public.classes enable row level security;
create policy "classes: teacher manages own" on public.classes for all to authenticated
  using (teacher_id = (select auth.uid()) or (select public.is_admin()))
  with check (teacher_id = (select auth.uid()) and (select public.current_user_role()) = 'teacher');
create policy "classes: members read" on public.classes for select to authenticated
  using (public.is_class_member(id));
create policy "class_members: teacher manages" on public.class_members for all to authenticated
  using (public.is_class_teacher(class_id) or (select public.is_admin()))
  with check (public.is_class_teacher(class_id) and public.is_active_link((select auth.uid()), student_id));
create policy "class_members: student reads own" on public.class_members for select to authenticated
  using (student_id = (select auth.uid()));


alter table public.homework enable row level security;
alter table public.homework_targets enable row level security;
alter table public.homework_submissions enable row level security;
grant select, insert, update, delete on public.homework, public.homework_targets to authenticated;
grant select on public.homework_submissions to authenticated;
grant all on public.homework, public.homework_targets, public.homework_submissions to service_role;

create policy "homework: teacher manages own" on public.homework for all to authenticated
  using (teacher_id = (select auth.uid()) or (select public.is_admin()))
  with check (teacher_id = (select auth.uid()) and (select public.current_user_role()) = 'teacher');
create policy "homework: targeted students read" on public.homework for select to authenticated
  using (public.is_homework_target(id));
create policy "homework_targets: teacher manages" on public.homework_targets for all to authenticated
  using (public.is_homework_teacher(homework_id) or (select public.is_admin()))
  with check (public.is_homework_teacher(homework_id) and public.is_active_link((select auth.uid()), student_id));
create policy "homework_targets: student reads own" on public.homework_targets for select to authenticated
  using (student_id = (select auth.uid()));
create policy "homework_submissions: parties read" on public.homework_submissions for select to authenticated
  using (student_id = (select auth.uid()) or (select public.is_admin())
         or public.is_homework_teacher(homework_id));

-- Student saves a draft or submits. Graded work is locked; returned work can be resubmitted.
create or replace function public.save_homework(
  p_homework_id uuid, p_answers jsonb, p_submit boolean, p_auto_score integer, p_max_score integer)
returns public.homework_submissions language plpgsql security definer set search_path = public as $$
declare
  v_row public.homework_submissions;
begin
  if not exists (select 1 from public.homework_targets t where t.homework_id = p_homework_id and t.student_id = auth.uid()) then
    raise exception 'not assigned' using errcode = '42501';
  end if;
  select * into v_row from public.homework_submissions where homework_id = p_homework_id and student_id = auth.uid();
  if found and v_row.status = 'graded' then
    raise exception 'already graded' using errcode = 'P0001';
  end if;
  insert into public.homework_submissions as s (homework_id, student_id, status, answers, auto_score, max_score, submitted_at)
  values (p_homework_id, auth.uid(), case when p_submit then 'submitted' else 'in_progress' end,
          coalesce(p_answers, '{}'::jsonb), greatest(p_auto_score, 0), greatest(p_max_score, 0),
          case when p_submit then now() end)
  on conflict (homework_id, student_id) do update
     set answers = excluded.answers, auto_score = excluded.auto_score, max_score = excluded.max_score,
         status = case when p_submit then 'submitted' else s.status end,
         submitted_at = case when p_submit then now() else s.submitted_at end,
         updated_at = now()
  returning * into v_row;
  return v_row;
end $$;

-- Teacher grades (locks) or returns for revision, with feedback and per-question corrections.
create or replace function public.grade_homework(
  p_submission_id uuid, p_grade integer, p_feedback text, p_corrections jsonb, p_return boolean)
returns public.homework_submissions language plpgsql security definer set search_path = public as $$
declare
  v_row public.homework_submissions;
begin
  if not exists (select 1 from public.homework_submissions s join public.homework h on h.id = s.homework_id
                  where s.id = p_submission_id and (h.teacher_id = auth.uid() or public.is_admin())) then
    raise exception 'not your homework' using errcode = '42501';
  end if;
  update public.homework_submissions
     set grade = p_grade, feedback = coalesce(p_feedback, ''), corrections = coalesce(p_corrections, '{}'::jsonb),
         status = case when p_return then 'returned' else 'graded' end, graded_at = now(), updated_at = now()
   where id = p_submission_id
  returning * into v_row;
  return v_row;
end $$;

grant execute on function public.save_homework(uuid, jsonb, boolean, integer, integer) to authenticated;
grant execute on function public.grade_homework(uuid, integer, text, jsonb, boolean) to authenticated;

-- Carry existing lesson assignments over (the old table stays untouched).
insert into public.homework (id, teacher_id, kind, title, instructions, lesson_id, due_at, created_at)
select a.id, a.teacher_id, 'lesson', coalesce(l.title_de, ''), a.note, a.lesson_id, a.due_on::timestamptz, a.created_at
  from public.lesson_assignments a left join public.lessons l on l.id = a.lesson_id
on conflict (id) do nothing;
insert into public.homework_targets (homework_id, student_id)
select a.id, a.student_id from public.lesson_assignments a on conflict do nothing;

-- Live lessons --------------------------------------------------------------
create table public.live_sessions (
  id           uuid primary key default gen_random_uuid(),
  teacher_id   uuid not null references public.profiles (id) on delete cascade,
  class_id     uuid references public.classes (id) on delete set null,
  title        text not null default '' check (char_length(title) <= 120),
  lesson_id    uuid references public.lessons (id) on delete set null,
  item_index   integer not null default 0,
  show_answer  boolean not null default false,
  answerer_id  uuid references public.profiles (id) on delete set null,
  status       text not null default 'live' check (status in ('live', 'ended')),
  started_at   timestamptz not null default now(),
  ended_at     timestamptz
);
create index live_sessions_teacher_idx on public.live_sessions (teacher_id, started_at desc);

create table public.live_responses (
  session_id   uuid not null references public.live_sessions (id) on delete cascade,
  student_id   uuid not null references public.profiles (id) on delete cascade,
  item_index   integer not null,
  answer       text not null default '' check (char_length(answer) <= 500),
  correct      boolean,
  teacher_mark text check (teacher_mark in ('correct', 'wrong', 'retry')),
  created_at   timestamptz not null default now(),
  primary key (session_id, student_id, item_index)
);

create table public.live_participants (
  session_id  uuid not null references public.live_sessions (id) on delete cascade,
  student_id  uuid not null references public.profiles (id) on delete cascade,
  joined_at   timestamptz not null default now(),
  last_seen   timestamptz not null default now(),
  primary key (session_id, student_id)
);

alter table public.live_sessions enable row level security;
alter table public.live_responses enable row level security;
alter table public.live_participants enable row level security;
grant select, insert, update, delete on public.live_sessions to authenticated;
grant select, update on public.live_responses to authenticated;
grant select on public.live_participants to authenticated;
grant all on public.live_sessions, public.live_responses, public.live_participants to service_role;

create or replace function public.can_see_live(p_session uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.live_sessions s
     where s.id = p_session
       and public.is_active_link(s.teacher_id, auth.uid())
       and (s.class_id is null or exists (select 1 from public.class_members m where m.class_id = s.class_id and m.student_id = auth.uid())));
$$;

create policy "live_sessions: teacher manages own" on public.live_sessions for all to authenticated
  using (teacher_id = (select auth.uid()) or (select public.is_admin()))
  with check (teacher_id = (select auth.uid()) and (select public.current_user_role()) = 'teacher');
create policy "live_sessions: linked students read" on public.live_sessions for select to authenticated
  using (public.can_see_live(id));
create policy "live_responses: parties read" on public.live_responses for select to authenticated
  using (student_id = (select auth.uid())
         or exists (select 1 from public.live_sessions s where s.id = session_id and s.teacher_id = (select auth.uid())));
create policy "live_responses: teacher marks" on public.live_responses for update to authenticated
  using (exists (select 1 from public.live_sessions s where s.id = session_id and s.teacher_id = (select auth.uid())));
create policy "live_participants: parties read" on public.live_participants for select to authenticated
  using (student_id = (select auth.uid())
         or exists (select 1 from public.live_sessions s where s.id = session_id and s.teacher_id = (select auth.uid())));

create or replace function public.live_join(p_session_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.can_see_live(p_session_id) then raise exception 'not allowed' using errcode = '42501'; end if;
  insert into public.live_participants (session_id, student_id) values (p_session_id, auth.uid())
  on conflict (session_id, student_id) do update set last_seen = now();
end $$;

create or replace function public.live_answer(p_session_id uuid, p_item_index integer, p_answer text, p_correct boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.can_see_live(p_session_id) then raise exception 'not allowed' using errcode = '42501'; end if;
  if not exists (select 1 from public.live_sessions where id = p_session_id and status = 'live') then
    raise exception 'session ended' using errcode = 'P0001';
  end if;
  insert into public.live_responses (session_id, student_id, item_index, answer, correct)
  values (p_session_id, auth.uid(), p_item_index, left(coalesce(p_answer, ''), 500), p_correct)
  on conflict (session_id, student_id, item_index) do update
     set answer = excluded.answer, correct = excluded.correct, teacher_mark = null, created_at = now();
end $$;
grant execute on function public.live_join(uuid) to authenticated;
grant execute on function public.live_answer(uuid, integer, text, boolean) to authenticated;

do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.homework, public.homework_targets, public.homework_submissions,
      public.live_sessions, public.live_responses, public.live_participants;
  end if;
end $$;
