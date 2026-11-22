-- Lessons (vocabulary, phrases, quizzes) and per-student progress.
-- Admins author lessons; every signed-in user reads published ones.

create table public.lessons (
  id              uuid primary key default gen_random_uuid(),
  cefr_level      text not null default 'A1' check (cefr_level in ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
  position        integer not null default 0,
  title_de        text not null check (char_length(title_de) between 1 and 120),
  title_ar        text not null default '' check (char_length(title_ar) <= 120),
  description_ar  text not null default '' check (char_length(description_ar) <= 500),
  published       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index lessons_level_position_idx on public.lessons (cefr_level, position);

create trigger lessons_touch_updated_at
before update on public.lessons
for each row execute function public.touch_updated_at();

create table public.lesson_items (
  id          uuid primary key default gen_random_uuid(),
  lesson_id   uuid not null references public.lessons (id) on delete cascade,
  position    integer not null default 0,
  kind        text not null check (kind in ('vocab', 'phrase', 'quiz')),
  -- vocab/phrase: the German text; quiz: optional German prompt
  german      text not null default '' check (char_length(german) <= 300),
  -- vocab/phrase: Arabic meaning; quiz: the question (Arabic)
  arabic      text not null default '' check (char_length(arabic) <= 300),
  example_de  text check (example_de is null or char_length(example_de) <= 300),
  example_ar  text check (example_ar is null or char_length(example_ar) <= 300),
  options     jsonb check (options is null or (jsonb_typeof(options) = 'array' and jsonb_array_length(options) between 2 and 6)),
  answer      integer,
  constraint lesson_items_quiz_shape check (
    (kind = 'quiz' and options is not null and answer is not null and answer >= 0 and answer < jsonb_array_length(options))
    or (kind <> 'quiz' and german <> '')
  )
);

create index lesson_items_lesson_idx on public.lesson_items (lesson_id, position);

create table public.lesson_progress (
  student_id    uuid not null references public.profiles (id) on delete cascade,
  lesson_id     uuid not null references public.lessons (id) on delete cascade,
  best_score    integer not null default 0,
  max_score     integer not null default 0,
  attempts      integer not null default 1,
  completed_at  timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  primary key (student_id, lesson_id),
  constraint lesson_progress_score check (best_score >= 0 and best_score <= max_score and max_score <= 100)
);

create index lesson_progress_lesson_idx on public.lesson_progress (lesson_id);

alter table public.lessons enable row level security;
alter table public.lesson_items enable row level security;
alter table public.lesson_progress enable row level security;

revoke all on table public.lessons, public.lesson_items, public.lesson_progress from anon, authenticated;
grant select, insert, update, delete on table public.lessons, public.lesson_items to authenticated;
grant select on table public.lesson_progress to authenticated;
grant select, insert, update, delete on table public.lessons, public.lesson_items, public.lesson_progress to service_role;

create policy "lessons: read published"
on public.lessons for select to authenticated
using (published or (select public.is_admin()));

create policy "lessons: admins write"
on public.lessons for all to authenticated
using ((select public.is_admin()))
with check ((select public.is_admin()));

create policy "lesson_items: read with lesson"
on public.lesson_items for select to authenticated
using (exists (select 1 from public.lessons l where l.id = lesson_id and (l.published or (select public.is_admin()))));

create policy "lesson_items: admins write"
on public.lesson_items for all to authenticated
using ((select public.is_admin()))
with check ((select public.is_admin()));

-- Own progress, linked teacher (active link) and admins.
create policy "lesson_progress: student, teacher, admin read"
on public.lesson_progress for select to authenticated
using (
  student_id = (select auth.uid())
  or (select public.is_admin())
  or exists (
    select 1 from public.teacher_student_links l
     where l.student_id = lesson_progress.student_id
       and l.teacher_id = (select auth.uid())
       and l.status = 'active'
  )
);

-- Student finishes a lesson; keeps the best score.
create or replace function public.complete_lesson(p_lesson_id uuid, p_score integer, p_max integer)
returns public.lesson_progress
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  result public.lesson_progress;
begin
  if uid is null or public.current_user_role() is distinct from 'student' then
    raise exception 'only students record lesson progress' using errcode = '42501';
  end if;
  if p_max < 0 or p_max > 100 or p_score < 0 or p_score > p_max then
    raise exception 'invalid score' using errcode = '22023';
  end if;
  if not exists (select 1 from public.lessons where id = p_lesson_id and published) then
    raise exception 'lesson not found' using errcode = 'P0404';
  end if;

  insert into public.lesson_progress (student_id, lesson_id, best_score, max_score)
  values (uid, p_lesson_id, p_score, p_max)
  on conflict (student_id, lesson_id) do update
     set best_score = least(greatest(public.lesson_progress.best_score, excluded.best_score), excluded.max_score),
         max_score = excluded.max_score,
         attempts = public.lesson_progress.attempts + 1,
         completed_at = now(),
         updated_at = now()
  returning * into result;
  return result;
end;
$$;

revoke all on function public.complete_lesson(uuid, integer, integer) from public, anon;
grant execute on function public.complete_lesson(uuid, integer, integer) to authenticated;
