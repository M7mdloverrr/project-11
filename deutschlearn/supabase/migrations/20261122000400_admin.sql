-- Admin panel: read-all policies for admins, an audit log, and admin RPCs.
-- Admins are never self-assigned (see handle_new_user); the first admin is
-- promoted directly in the database.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.current_user_role() = 'admin', false);
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated, service_role;

create or replace function public.assert_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'admin only' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.assert_admin() from public, anon, authenticated;

create policy "profiles: admins read all"
on public.profiles for select to authenticated
using ((select public.is_admin()));

create policy "teacher_codes: admins read all"
on public.teacher_codes for select to authenticated
using ((select public.is_admin()));

create policy "links: admins read all"
on public.teacher_student_links for select to authenticated
using ((select public.is_admin()));

create policy "link_requests: admins read all"
on public.link_requests for select to authenticated
using ((select public.is_admin()));

-- Audit log ------------------------------------------------------------------

create table public.admin_audit_log (
  id           bigint generated always as identity primary key,
  admin_id     uuid references public.profiles (id) on delete set null,
  action       text not null check (char_length(action) <= 60),
  target_type  text not null check (target_type in ('user', 'teacher_code', 'link', 'link_request')),
  target_id    uuid,
  details      jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);

create index admin_audit_log_created_idx on public.admin_audit_log (created_at desc);
create index admin_audit_log_admin_idx on public.admin_audit_log (admin_id);
create index admin_audit_log_target_idx on public.admin_audit_log (target_id);

alter table public.admin_audit_log enable row level security;
revoke all on table public.admin_audit_log from anon, authenticated;
grant select on table public.admin_audit_log to authenticated;

create policy "admin_audit_log: admins read"
on public.admin_audit_log for select to authenticated
using ((select public.is_admin()));

create or replace function public.log_admin_action(
  p_action text,
  p_target_type text,
  p_target_id uuid,
  p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.admin_audit_log (admin_id, action, target_type, target_id, details)
  values (auth.uid(), p_action, p_target_type, p_target_id, coalesce(p_details, '{}'::jsonb));
$$;

revoke all on function public.log_admin_action(text, text, uuid, jsonb) from public, anon, authenticated;

-- Read RPCs ------------------------------------------------------------------

create or replace function public.admin_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.assert_admin();
  return jsonb_build_object(
    'students', (select count(*) from public.profiles where role = 'student'),
    'teachers', (select count(*) from public.profiles where role = 'teacher'),
    'admins', (select count(*) from public.profiles where role = 'admin'),
    'new_users_7d', (select count(*) from public.profiles where created_at > now() - interval '7 days'),
    'blocked_users', (select count(*) from auth.users where banned_until > now()),
    'unconfirmed_users', (select count(*) from auth.users where email_confirmed_at is null),
    'active_links', (select count(*) from public.teacher_student_links where status = 'active'),
    'pending_requests', (select count(*) from public.link_requests where status = 'pending'),
    'active_codes', (select count(*) from public.teacher_codes where not revoked),
    'students_without_teacher', (
      select count(*) from public.profiles p
       where p.role = 'student'
         and not exists (select 1 from public.teacher_student_links l
                          where l.student_id = p.id and l.status = 'active'))
  );
end;
$$;

revoke all on function public.admin_stats() from public, anon;
grant execute on function public.admin_stats() to authenticated;

-- Users joined with auth data (e-mail, sign-in, block state) that profiles
-- deliberately do not hold.
create or replace function public.admin_list_users(
  p_search text default null,
  p_role public.user_role default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  email text,
  role public.user_role,
  display_name text,
  locale text,
  cefr_level text,
  created_at timestamptz,
  last_sign_in_at timestamptz,
  email_confirmed_at timestamptz,
  banned_until timestamptz,
  teacher_name text,
  student_count bigint,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  pattern text := nullif('%' || trim(coalesce(p_search, '')) || '%', '%%');
begin
  perform public.assert_admin();
  return query
  select p.id, u.email::text, p.role, p.display_name, p.locale, p.cefr_level, p.created_at,
         u.last_sign_in_at, u.email_confirmed_at, u.banned_until,
         (select t.display_name from public.teacher_student_links l
            join public.profiles t on t.id = l.teacher_id
           where l.student_id = p.id and l.status = 'active' limit 1),
         (select count(*) from public.teacher_student_links l
           where l.teacher_id = p.id and l.status = 'active'),
         count(*) over ()
    from public.profiles p
    join auth.users u on u.id = p.id
   where (p_role is null or p.role = p_role)
     and (pattern is null or p.display_name ilike pattern or u.email ilike pattern)
   order by p.created_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

revoke all on function public.admin_list_users(text, public.user_role, integer, integer) from public, anon;
grant execute on function public.admin_list_users(text, public.user_role, integer, integer) to authenticated;

-- Write RPCs -----------------------------------------------------------------

-- Ends every open link of a user, cancels their pending requests and revokes
-- their code. Used when a user's role changes.
create or replace function public.admin_detach_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.link_requests set status = 'cancelled', responded_at = now()
   where status = 'pending' and p_user_id in (teacher_id, student_id);
  update public.teacher_student_links set status = 'disconnected'
   where status in ('pending', 'active') and p_user_id in (teacher_id, student_id);
  update public.teacher_codes set revoked = true
   where teacher_id = p_user_id and not revoked;
end;
$$;

revoke all on function public.admin_detach_user(uuid) from public, anon, authenticated;

create or replace function public.admin_update_profile(
  p_user_id uuid,
  p_display_name text default null,
  p_role public.user_role default null,
  p_cefr_level text default null,
  p_locale text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row public.profiles;
  after_row public.profiles;
begin
  perform public.assert_admin();

  select * into before_row from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'user not found' using errcode = 'P0404';
  end if;

  if p_role is not null and p_role <> before_row.role then
    if p_user_id = auth.uid() then
      raise exception 'you cannot change your own role' using errcode = '22023';
    end if;
    perform public.admin_detach_user(p_user_id);
  end if;

  update public.profiles
     set display_name = coalesce(left(trim(p_display_name), 80), display_name),
         role = coalesce(p_role, role),
         cefr_level = coalesce(p_cefr_level, cefr_level),
         locale = coalesce(p_locale, locale)
   where id = p_user_id
  returning * into after_row;

  perform public.log_admin_action('update_profile', 'user', p_user_id, jsonb_strip_nulls(jsonb_build_object(
    'display_name', case when after_row.display_name <> before_row.display_name then after_row.display_name end,
    'role', case when after_row.role <> before_row.role then after_row.role end,
    'cefr_level', case when after_row.cefr_level <> before_row.cefr_level then after_row.cefr_level end,
    'locale', case when after_row.locale <> before_row.locale then after_row.locale end
  )));
  return after_row;
end;
$$;

revoke all on function public.admin_update_profile(uuid, text, public.user_role, text, text) from public, anon;
grant execute on function public.admin_update_profile(uuid, text, public.user_role, text, text) to authenticated;

create or replace function public.admin_revoke_code(p_code_id uuid)
returns public.teacher_codes
language plpgsql
security definer
set search_path = ''
as $$
declare
  result public.teacher_codes;
begin
  perform public.assert_admin();
  update public.teacher_codes set revoked = true
   where id = p_code_id and not revoked
  returning * into result;
  if not found then
    raise exception 'code not found or already revoked' using errcode = 'P0404';
  end if;
  perform public.log_admin_action('revoke_code', 'teacher_code', p_code_id,
    jsonb_build_object('code', result.code, 'teacher_id', result.teacher_id));
  return result;
end;
$$;

revoke all on function public.admin_revoke_code(uuid) from public, anon;
grant execute on function public.admin_revoke_code(uuid) to authenticated;

create or replace function public.admin_respond_request(p_request_id uuid, p_approve boolean)
returns public.teacher_student_links
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_row public.link_requests;
  link_row public.teacher_student_links;
begin
  perform public.assert_admin();

  select * into request_row from public.link_requests
   where id = p_request_id and status = 'pending' for update;
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

  perform public.log_admin_action(case when p_approve then 'approve_request' else 'decline_request' end,
    'link_request', p_request_id,
    jsonb_build_object('teacher_id', request_row.teacher_id, 'student_id', request_row.student_id));
  return link_row;
end;
$$;

revoke all on function public.admin_respond_request(uuid, boolean) from public, anon;
grant execute on function public.admin_respond_request(uuid, boolean) to authenticated;

create or replace function public.admin_disconnect_link(p_link_id uuid)
returns public.teacher_student_links
language plpgsql
security definer
set search_path = ''
as $$
declare
  link_row public.teacher_student_links;
begin
  perform public.assert_admin();

  update public.teacher_student_links set status = 'disconnected'
   where id = p_link_id and status in ('pending', 'active')
  returning * into link_row;
  if not found then
    raise exception 'link not found or already disconnected' using errcode = 'P0404';
  end if;

  update public.link_requests set status = 'cancelled', responded_at = now()
   where link_id = p_link_id and status = 'pending';

  perform public.log_admin_action('disconnect_link', 'link', p_link_id,
    jsonb_build_object('teacher_id', link_row.teacher_id, 'student_id', link_row.student_id));
  return link_row;
end;
$$;

revoke all on function public.admin_disconnect_link(uuid) from public, anon;
grant execute on function public.admin_disconnect_link(uuid) to authenticated;

-- Links a student to a teacher directly (no code, no request).
create or replace function public.admin_link_student(p_teacher_id uuid, p_student_id uuid)
returns public.teacher_student_links
language plpgsql
security definer
set search_path = ''
as $$
declare
  link_row public.teacher_student_links;
begin
  perform public.assert_admin();

  if not exists (select 1 from public.profiles where id = p_teacher_id and role = 'teacher') then
    raise exception 'teacher not found' using errcode = 'P0404';
  end if;
  if not exists (select 1 from public.profiles where id = p_student_id and role = 'student') then
    raise exception 'student not found' using errcode = 'P0404';
  end if;
  if exists (
    select 1 from public.teacher_student_links
     where student_id = p_student_id and teacher_id <> p_teacher_id and status in ('pending', 'active')
  ) then
    raise exception 'student is already linked to another teacher' using errcode = 'P0409';
  end if;

  insert into public.teacher_student_links (teacher_id, student_id, status)
  values (p_teacher_id, p_student_id, 'active')
  on conflict (teacher_id, student_id) do update set status = 'active'
  returning * into link_row;

  update public.link_requests set status = 'approved', responded_at = now()
   where link_id = link_row.id and status = 'pending';

  perform public.log_admin_action('link_student', 'link', link_row.id,
    jsonb_build_object('teacher_id', p_teacher_id, 'student_id', p_student_id));
  return link_row;
end;
$$;

revoke all on function public.admin_link_student(uuid, uuid) from public, anon;
grant execute on function public.admin_link_student(uuid, uuid) to authenticated;

-- Used by the admin-users edge function (service role) to record auth-level
-- actions (create, block, delete, password reset) under the calling admin.
create or replace function public.log_admin_action_as(
  p_admin_id uuid,
  p_action text,
  p_target_type text,
  p_target_id uuid,
  p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.admin_audit_log (admin_id, action, target_type, target_id, details)
  values (p_admin_id, p_action, p_target_type, p_target_id, coalesce(p_details, '{}'::jsonb));
$$;

revoke all on function public.log_admin_action_as(uuid, text, text, uuid, jsonb) from public, anon, authenticated;
grant execute on function public.log_admin_action_as(uuid, text, text, uuid, jsonb) to service_role;

-- Explicit grants for server-side code (edge functions use the service role).
-- Tables created by the migration runner do not always inherit Supabase's
-- default service_role privileges.
grant select, insert, update, delete on table
  public.profiles,
  public.teacher_codes,
  public.teacher_student_links,
  public.link_requests,
  public.code_lookup_attempts,
  public.admin_audit_log
to service_role;
grant usage, select on all sequences in schema public to service_role;
