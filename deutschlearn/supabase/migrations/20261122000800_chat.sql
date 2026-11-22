-- Chat between a teacher and an actively linked student.

create table public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid not null references public.profiles (id) on delete cascade,
  student_id  uuid not null references public.profiles (id) on delete cascade,
  sender_id   uuid not null references public.profiles (id) on delete cascade,
  body        text not null check (char_length(btrim(body)) between 1 and 2000),
  created_at  timestamptz not null default now(),
  constraint chat_messages_sender_is_party check (sender_id = teacher_id or sender_id = student_id)
);

create index chat_messages_pair_idx on public.chat_messages (student_id, teacher_id, created_at);

alter table public.chat_messages enable row level security;
revoke all on table public.chat_messages from anon, authenticated;
grant select, insert on table public.chat_messages to authenticated;
grant select, insert, update, delete on table public.chat_messages to service_role;

create policy "chat_messages: parties and admins read"
on public.chat_messages for select to authenticated
using (teacher_id = (select auth.uid()) or student_id = (select auth.uid()) or (select public.is_admin()));

create policy "chat_messages: party sends on active link"
on public.chat_messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and exists (
    select 1 from public.teacher_student_links l
     where l.teacher_id = chat_messages.teacher_id
       and l.student_id = chat_messages.student_id
       and l.status = 'active'
  )
);

-- Live updates for the apps (Supabase Realtime respects the select policy).
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;
