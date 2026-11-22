-- Structured A1–B1 curriculum: levels → modules → lessons (lesson, module test,
-- level exam, placement test) with richer exercise kinds.

create table public.modules (
  id              uuid primary key default gen_random_uuid(),
  slug            text not null unique check (slug ~ '^[a-z0-9-]+$'),
  cefr_level      text not null default 'A1' check (cefr_level in ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
  position        integer not null default 0,
  title_de        text not null check (char_length(title_de) between 1 and 120),
  title_ar        text not null default '' check (char_length(title_ar) <= 120),
  description_ar  text not null default '' check (char_length(description_ar) <= 500),
  icon            text not null default 'book' check (char_length(icon) <= 40),
  published       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index modules_level_position_idx on public.modules (cefr_level, position);

create trigger modules_touch_updated_at
before update on public.modules
for each row execute function public.touch_updated_at();

alter table public.lessons
  add column module_id uuid references public.modules (id) on delete set null,
  add column slug text unique check (slug is null or slug ~ '^[a-z0-9-]+$'),
  add column kind text not null default 'lesson' check (kind in ('lesson', 'test', 'exam', 'placement')),
  add column goal_ar text not null default '' check (char_length(goal_ar) <= 500),
  add column explanation_ar text not null default '' check (char_length(explanation_ar) <= 8000),
  add column pass_percent integer not null default 70 check (pass_percent between 0 and 100);

create index lessons_module_idx on public.lessons (module_id, position);

alter table public.lesson_items
  drop constraint lesson_items_quiz_shape,
  drop constraint lesson_items_kind_check,
  drop constraint lesson_items_german_check,
  drop constraint lesson_items_arabic_check,
  drop constraint lesson_items_options_check;

alter table public.lesson_items
  add constraint lesson_items_kind_check
    check (kind in ('vocab', 'phrase', 'text', 'rule', 'quiz', 'gap', 'listen', 'order', 'match', 'write')),
  add constraint lesson_items_german_check check (char_length(german) <= 4000),
  add constraint lesson_items_arabic_check check (char_length(arabic) <= 4000),
  add constraint lesson_items_options_check
    check (options is null or (jsonb_typeof(options) = 'array' and jsonb_array_length(options) between 2 and 8)),
  add constraint lesson_items_shape check (
    case kind
      when 'quiz' then options is not null and answer is not null and answer >= 0 and answer < jsonb_array_length(options)
      when 'gap' then german like '%\_\_\_%' and options is not null and answer is not null
                      and answer >= 0 and answer < jsonb_array_length(options)
      when 'listen' then german <> '' and options is not null and answer is not null
                      and answer >= 0 and answer < jsonb_array_length(options)
      when 'match' then options is not null and jsonb_array_length(options) >= 2
      when 'rule' then arabic <> ''
      else german <> ''
    end
  );

alter table public.modules enable row level security;
revoke all on table public.modules from anon, authenticated;
grant select, insert, update, delete on table public.modules to authenticated;
grant select, insert, update, delete on table public.modules to service_role;

create policy "modules: read published"
on public.modules for select to authenticated
using (published or (select public.is_admin()));

create policy "modules: admins write"
on public.modules for all to authenticated
using ((select public.is_admin()))
with check ((select public.is_admin()));

-- Placement test result: a student sets their own starting level (A1–B1).
create or replace function public.set_placement_level(p_level text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or public.current_user_role() is distinct from 'student' then
    raise exception 'only students take the placement test' using errcode = '42501';
  end if;
  if p_level not in ('A1', 'A2', 'B1') then
    raise exception 'invalid level' using errcode = '22023';
  end if;
  update public.profiles set cefr_level = p_level where id = auth.uid();
end;
$$;

revoke all on function public.set_placement_level(text) from public, anon;
grant execute on function public.set_placement_level(text) to authenticated;
