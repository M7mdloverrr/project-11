-- Teacher <-> student links and link requests.
-- A student has at most one pending/active teacher link at a time.

create type public.link_status as enum ('pending', 'active', 'disconnected');
create type public.link_request_status as enum ('pending', 'approved', 'declined', 'cancelled');

create table public.teacher_student_links (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid not null references public.profiles (id) on delete cascade,
  student_id  uuid not null references public.profiles (id) on delete cascade,
  status      public.link_status not null default 'pending',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint teacher_student_links_unique_pair unique (teacher_id, student_id),
  constraint teacher_student_links_distinct check (teacher_id <> student_id)
);

create index teacher_student_links_teacher_idx on public.teacher_student_links (teacher_id, status);
create index teacher_student_links_student_idx on public.teacher_student_links (student_id, status);
create unique index teacher_student_links_one_open_per_student
  on public.teacher_student_links (student_id) where status in ('pending', 'active');

create trigger teacher_student_links_touch_updated_at
before update on public.teacher_student_links
for each row execute function public.touch_updated_at();

create table public.link_requests (
  id            uuid primary key default gen_random_uuid(),
  link_id       uuid not null references public.teacher_student_links (id) on delete cascade,
  teacher_id    uuid not null references public.profiles (id) on delete cascade,
  student_id    uuid not null references public.profiles (id) on delete cascade,
  code_id       uuid references public.teacher_codes (id) on delete set null,
  status        public.link_request_status not null default 'pending',
  created_at    timestamptz not null default now(),
  responded_at  timestamptz
);

create index link_requests_teacher_idx on public.link_requests (teacher_id, status, created_at desc);
create index link_requests_student_idx on public.link_requests (student_id, created_at desc);
create index link_requests_link_idx on public.link_requests (link_id);
create index link_requests_code_idx on public.link_requests (code_id);
create unique index link_requests_one_pending_per_pair
  on public.link_requests (teacher_id, student_id) where status = 'pending';

alter table public.teacher_student_links enable row level security;
alter table public.link_requests enable row level security;

-- Read-only for clients; every write goes through the RPCs below.
revoke all on table public.teacher_student_links from anon, authenticated;
revoke all on table public.link_requests from anon, authenticated;
grant select on table public.teacher_student_links to authenticated;
grant select on table public.link_requests to authenticated;

create policy "links: readable by the two parties"
on public.teacher_student_links for select
to authenticated
using ((select auth.uid()) in (teacher_id, student_id));

create policy "link_requests: readable by the two parties"
on public.link_requests for select
to authenticated
using ((select auth.uid()) in (teacher_id, student_id));

-- The two parties of a link (any status) can see each other's profile
-- (display name, avatar, locale, level). Profiles hold no email or contact data.
create policy "profiles: linked parties read each other"
on public.profiles for select
to authenticated
using (
  exists (
    select 1 from public.teacher_student_links l
     where (l.teacher_id = (select auth.uid()) and l.student_id = profiles.id)
        or (l.student_id = (select auth.uid()) and l.teacher_id = profiles.id)
  )
);

-- Student: validate a code and create (or return) a pending link request.
-- Called by the resolve-teacher-code edge function with the student's JWT.
create or replace function public.request_teacher_link(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  normalized text := upper(trim(p_code));
  code_row public.teacher_codes;
  link_row public.teacher_student_links;
  request_row public.link_requests;
  teacher_name text;
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if public.current_user_role() is distinct from 'student' then
    raise exception 'only students can link to a teacher' using errcode = '42501';
  end if;

  perform public.check_code_lookup_rate();

  select * into code_row from public.teacher_codes where code = normalized and not revoked;
  if not found then
    raise exception 'invalid or revoked teacher code' using errcode = 'P0404';
  end if;
  if code_row.teacher_id = uid then
    raise exception 'cannot link to yourself' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.teacher_student_links
     where student_id = uid and teacher_id <> code_row.teacher_id and status in ('pending', 'active')
  ) then
    raise exception 'already linked to another teacher' using errcode = 'P0409';
  end if;

  insert into public.teacher_student_links (teacher_id, student_id, status)
  values (code_row.teacher_id, uid, 'pending')
  on conflict (teacher_id, student_id) do update
     set status = case when public.teacher_student_links.status = 'active'
                       then 'active'::public.link_status
                       else 'pending'::public.link_status end
  returning * into link_row;

  if link_row.status = 'pending' then
    select * into request_row
      from public.link_requests
     where teacher_id = code_row.teacher_id and student_id = uid and status = 'pending';
    if not found then
      insert into public.link_requests (link_id, teacher_id, student_id, code_id)
      values (link_row.id, code_row.teacher_id, uid, code_row.id)
      returning * into request_row;
    end if;
  end if;

  select display_name into teacher_name from public.profiles where id = code_row.teacher_id;

  return jsonb_build_object(
    'link_id', link_row.id,
    'request_id', request_row.id,
    'status', link_row.status,
    'teacher_display_name', teacher_name
  );
end;
$$;

revoke all on function public.request_teacher_link(text) from public, anon;
grant execute on function public.request_teacher_link(text) to authenticated;

-- Teacher: approve or decline a pending request addressed to them.
create or replace function public.respond_link_request(p_request_id uuid, p_approve boolean)
returns public.teacher_student_links
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  request_row public.link_requests;
  link_row public.teacher_student_links;
begin
  if uid is null or public.current_user_role() is distinct from 'teacher' then
    raise exception 'only teachers can respond to link requests' using errcode = '42501';
  end if;

  select * into request_row
    from public.link_requests
   where id = p_request_id and teacher_id = uid and status = 'pending'
   for update;
  if not found then
    raise exception 'request not found or already handled' using errcode = 'P0404';
  end if;

  update public.link_requests
     set status = case when p_approve then 'approved'::public.link_request_status
                       else 'declined'::public.link_request_status end,
         responded_at = now()
   where id = request_row.id;

  update public.teacher_student_links
     set status = case when p_approve then 'active'::public.link_status
                       else 'disconnected'::public.link_status end
   where id = request_row.link_id
  returning * into link_row;

  return link_row;
end;
$$;

revoke all on function public.respond_link_request(uuid, boolean) from public, anon;
grant execute on function public.respond_link_request(uuid, boolean) to authenticated;

-- Either party: end a link (also cancels a pending request).
create or replace function public.disconnect_link(p_link_id uuid)
returns public.teacher_student_links
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  link_row public.teacher_student_links;
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  update public.teacher_student_links
     set status = 'disconnected'
   where id = p_link_id and uid in (teacher_id, student_id)
  returning * into link_row;
  if not found then
    raise exception 'link not found' using errcode = 'P0404';
  end if;

  update public.link_requests
     set status = 'cancelled', responded_at = now()
   where link_id = p_link_id and status = 'pending';

  return link_row;
end;
$$;

revoke all on function public.disconnect_link(uuid) from public, anon;
grant execute on function public.disconnect_link(uuid) to authenticated;
