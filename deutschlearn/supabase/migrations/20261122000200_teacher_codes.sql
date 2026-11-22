-- Teacher codes (TCH-XXXXXX). Codes are minted only server-side by the
-- generate-teacher-code edge function, which calls issue_teacher_code() with
-- the service role. Clients can read and revoke their own codes.

create table public.teacher_codes (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid not null references public.profiles (id) on delete cascade,
  code        text not null unique check (code ~ '^TCH-[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$'),
  revoked     boolean not null default false,
  created_at  timestamptz not null default now(),
  revoked_at  timestamptz
);

create index teacher_codes_teacher_idx on public.teacher_codes (teacher_id);
-- At most one active code per teacher.
create unique index teacher_codes_one_active_idx on public.teacher_codes (teacher_id) where not revoked;

-- Revocation is one-way and the code itself is immutable.
create or replace function public.guard_teacher_code_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.code <> old.code or new.teacher_id <> old.teacher_id or new.created_at <> old.created_at then
    raise exception 'teacher code is immutable' using errcode = '42501';
  end if;
  if old.revoked and not new.revoked then
    raise exception 'a revoked code cannot be re-activated' using errcode = '42501';
  end if;
  if new.revoked and not old.revoked then
    new.revoked_at := now();
  end if;
  return new;
end;
$$;

create trigger teacher_codes_guard_update
before update on public.teacher_codes
for each row execute function public.guard_teacher_code_update();

alter table public.teacher_codes enable row level security;

revoke all on table public.teacher_codes from anon, authenticated;
grant select on table public.teacher_codes to authenticated;
grant update (revoked) on table public.teacher_codes to authenticated;

create policy "teacher_codes: teacher reads own"
on public.teacher_codes for select
to authenticated
using (teacher_id = (select auth.uid()));

create policy "teacher_codes: teacher revokes own"
on public.teacher_codes for update
to authenticated
using (teacher_id = (select auth.uid()) and (select public.current_user_role()) = 'teacher')
with check (teacher_id = (select auth.uid()) and revoked);

-- Inserts happen only through issue_teacher_code (service role, bypasses RLS).
-- This policy documents the rule for any future client insert grant.
create policy "teacher_codes: teacher creates own"
on public.teacher_codes for insert
to authenticated
with check (teacher_id = (select auth.uid()) and (select public.current_user_role()) = 'teacher');

-- Called by the generate-teacher-code edge function with the service role.
-- Revokes the teacher's current code and stores the new crypto-random code.
create or replace function public.issue_teacher_code(p_teacher_id uuid, p_code text)
returns public.teacher_codes
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.teacher_codes;
begin
  if not exists (select 1 from public.profiles where id = p_teacher_id and role = 'teacher') then
    raise exception 'only teachers can own teacher codes' using errcode = '42501';
  end if;

  update public.teacher_codes
     set revoked = true
   where teacher_id = p_teacher_id and not revoked;

  insert into public.teacher_codes (teacher_id, code)
  values (p_teacher_id, p_code)
  returning * into result;

  return result;
end;
$$;

revoke all on function public.issue_teacher_code(uuid, text) from public, anon, authenticated;
grant execute on function public.issue_teacher_code(uuid, text) to service_role;

-- Brute-force protection for code lookups.
create table public.code_lookup_attempts (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index code_lookup_attempts_user_time_idx on public.code_lookup_attempts (user_id, created_at desc);

alter table public.code_lookup_attempts enable row level security;
revoke all on table public.code_lookup_attempts from anon, authenticated;

create or replace function public.check_code_lookup_rate()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  recent integer;
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select count(*) into recent
    from public.code_lookup_attempts
   where user_id = uid and created_at > now() - interval '10 minutes';

  if recent >= 20 then
    raise exception 'too many code attempts, try again later' using errcode = 'P0429';
  end if;

  insert into public.code_lookup_attempts (user_id) values (uid);
end;
$$;

revoke all on function public.check_code_lookup_rate() from public, anon, authenticated;

-- Public teacher preview for a code: display name and avatar only.
create or replace function public.lookup_teacher_by_code(code text)
returns table (display_name text, avatar_url text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.check_code_lookup_rate();

  return query
  select p.display_name, p.avatar_url
    from public.teacher_codes c
    join public.profiles p on p.id = c.teacher_id
   where c.code = upper(trim(lookup_teacher_by_code.code))
     and not c.revoked
     and p.role = 'teacher';
end;
$$;

revoke all on function public.lookup_teacher_by_code(text) from public, anon;
grant execute on function public.lookup_teacher_by_code(text) to authenticated;
