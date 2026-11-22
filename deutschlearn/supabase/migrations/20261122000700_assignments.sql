-- Homework: a teacher assigns a lesson to one of their actively linked students.

create table public.lesson_assignments (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid not null references public.profiles (id) on delete cascade,
  student_id  uuid not null references public.profiles (id) on delete cascade,
  lesson_id   uuid not null references public.lessons (id) on delete cascade,
  note        text not null default '' check (char_length(note) <= 300),
  due_on      date,
  created_at  timestamptz not null default now(),
  unique (teacher_id, student_id, lesson_id)
);

create index lesson_assignments_student_idx on public.lesson_assignments (student_id, created_at desc);
create index lesson_assignments_lesson_idx on public.lesson_assignments (lesson_id);

alter table public.lesson_assignments enable row level security;
revoke all on table public.lesson_assignments from anon, authenticated;
grant select, insert, delete on table public.lesson_assignments to authenticated;
grant select, insert, update, delete on table public.lesson_assignments to service_role;

create policy "lesson_assignments: parties and admins read"
on public.lesson_assignments for select to authenticated
using (student_id = (select auth.uid()) or teacher_id = (select auth.uid()) or (select public.is_admin()));

create policy "lesson_assignments: teacher assigns to active student"
on public.lesson_assignments for insert to authenticated
with check (
  teacher_id = (select auth.uid())
  and (select public.current_user_role()) = 'teacher'
  and exists (
    select 1 from public.teacher_student_links l
     where l.teacher_id = lesson_assignments.teacher_id
       and l.student_id = lesson_assignments.student_id
       and l.status = 'active'
  )
  and exists (select 1 from public.lessons x where x.id = lesson_id and x.published)
);

create policy "lesson_assignments: teacher or admin removes"
on public.lesson_assignments for delete to authenticated
using (teacher_id = (select auth.uid()) or (select public.is_admin()));
