-- Behaviour tests for the Phase 1 schema. Run with tests/run_sql_tests.sh.
\set ON_ERROR_STOP on
set client_min_messages = notice;

create or replace function pg_temp.as_user(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(uid::text, ''), false);
  execute 'set role authenticated';
end $$;

create or replace function pg_temp.expect_error(stmt text, label text) returns void language plpgsql as $$
begin
  begin
    execute stmt;
  exception when others then
    raise notice 'ok (rejected): % -> %', label, sqlerrm;
    return;
  end;
  raise exception 'expected failure: %', label;
end $$;

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-00000000000a', 't@x.de', '{"role":"teacher","display_name":"Herr Müller"}'),
  ('00000000-0000-0000-0000-00000000000b', 's@x.de', '{"role":"student","display_name":"Ahmed"}'),
  ('00000000-0000-0000-0000-00000000000c', 's2@x.de', '{"role":"student","display_name":"Sara"}'),
  ('00000000-0000-0000-0000-00000000000d', 'evil@x.de', '{"role":"admin","display_name":"Mallory"}');

do $$ begin
  assert (select role from public.profiles where id = '00000000-0000-0000-0000-00000000000a') = 'teacher';
  assert (select role from public.profiles where id = '00000000-0000-0000-0000-00000000000d') = 'student', 'admin must not be self-assigned';
end $$;

-- Service role mints a code (what the edge function does).
set role service_role;
select code from public.issue_teacher_code('00000000-0000-0000-0000-00000000000a', 'TCH-ABC234');
select pg_temp.expect_error($$select public.issue_teacher_code('00000000-0000-0000-0000-00000000000b', 'TCH-ZZZ234')$$, 'student cannot own code');
reset role;

-- Students cannot mint codes or call the service-only function.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
select pg_temp.expect_error($$select public.issue_teacher_code('00000000-0000-0000-0000-00000000000b', 'TCH-ZZZ234')$$, 'client cannot call issue_teacher_code');
select pg_temp.expect_error($$insert into public.teacher_codes (teacher_id, code) values ('00000000-0000-0000-0000-00000000000b', 'TCH-ZZZ234')$$, 'client insert into teacher_codes');
-- Student cannot see raw codes table, profile of unlinked teacher, or change own role.
do $$ begin
  assert (select count(*) from public.teacher_codes) = 0;
  assert (select count(*) from public.profiles) = 1, 'student sees only own profile';
end $$;
select pg_temp.expect_error($$update public.profiles set role = 'teacher' where id = auth.uid()$$, 'self role change');
update public.profiles set display_name = 'Ahmed A.' where id = auth.uid();
-- Lookup returns only the public fields.
do $$ declare r record; begin
  select * into r from public.lookup_teacher_by_code(' tch-abc234 ');
  assert r.display_name = 'Herr Müller';
  assert (select count(*) from public.lookup_teacher_by_code('TCH-NOPE22')) = 0;
end $$;
-- Request a link.
do $$ declare j jsonb; begin
  j := public.request_teacher_link('TCH-ABC234');
  assert j->>'status' = 'pending', j::text;
  assert j->>'teacher_display_name' = 'Herr Müller';
  -- Idempotent: same pending request returned.
  assert (public.request_teacher_link('TCH-ABC234')->>'request_id') = j->>'request_id';
end $$;
do $$ begin
  assert (select count(*) from public.teacher_student_links) = 1;
  assert (select count(*) from public.profiles) = 2, 'linked student can now see teacher profile';
end $$;
reset role;

-- Another student cannot see that link.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000c');
do $$ begin
  assert (select count(*) from public.teacher_student_links) = 0;
  assert (select count(*) from public.link_requests) = 0;
end $$;
select pg_temp.expect_error($$select public.respond_link_request((select id from public.link_requests limit 1), true)$$, 'student cannot approve');
reset role;

-- Teacher approves.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
do $$ declare rid uuid; l record; begin
  select id into rid from public.link_requests where status = 'pending';
  assert rid is not null, 'teacher sees pending request';
  assert (select display_name from public.profiles where id = '00000000-0000-0000-0000-00000000000b') = 'Ahmed A.';
  select * into l from public.respond_link_request(rid, true);
  assert l.status = 'active';
end $$;
select pg_temp.expect_error($$select public.request_teacher_link('TCH-ABC234')$$, 'teacher cannot request link');
-- Revoke via direct update is allowed, un-revoke is not.
update public.teacher_codes set revoked = true where code = 'TCH-ABC234';
select pg_temp.expect_error($$update public.teacher_codes set revoked = false where code = 'TCH-ABC234'$$, 'un-revoke');
select pg_temp.expect_error($$update public.teacher_codes set code = 'TCH-AAAAAA'$$, 'change code column');
reset role;

-- Revoked code no longer resolves; existing link stays active.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000c');
do $$ begin
  assert (select count(*) from public.lookup_teacher_by_code('TCH-ABC234')) = 0;
end $$;
select pg_temp.expect_error($$select public.request_teacher_link('TCH-ABC234')$$, 'revoked code');
reset role;

-- Student disconnects, then re-links with a fresh code; teacher declines.
set role service_role;
select code from public.issue_teacher_code('00000000-0000-0000-0000-00000000000a', 'TCH-NEW789');
reset role;
select pg_temp.as_user('00000000-0000-0000-0000-00000000000b');
do $$ declare l record; begin
  select * into l from public.disconnect_link((select id from public.teacher_student_links limit 1));
  assert l.status = 'disconnected';
  assert public.request_teacher_link('TCH-NEW789')->>'status' = 'pending';
end $$;
reset role;
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
do $$ declare l record; begin
  select * into l from public.respond_link_request((select id from public.link_requests where status = 'pending'), false);
  assert l.status = 'disconnected';
  assert (select count(*) from public.teacher_codes where not revoked) = 1, 'one active code';
end $$;
reset role;

-- Rate limit: 20 attempts per 10 minutes.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000c');
do $$ begin
  for i in 1..30 loop
    begin
      perform public.lookup_teacher_by_code('TCH-XXXXXX');
    exception when sqlstate 'P0429' then
      raise notice 'ok (rejected): rate limited after % attempts', i - 1;
      return;
    end;
  end loop;
  raise exception 'rate limit never triggered';
end $$;
reset role;

-- Anonymous callers get nothing.
set role anon;
select pg_temp.expect_error($$select * from public.lookup_teacher_by_code('TCH-NEW789')$$, 'anon lookup');
select pg_temp.expect_error($$select * from public.profiles$$, 'anon profiles');
reset role;

-- Admin -----------------------------------------------------------------------
-- Non-admins cannot use admin RPCs or read other users.
select pg_temp.as_user('00000000-0000-0000-0000-00000000000a');
select pg_temp.expect_error($$select public.admin_stats()$$, 'teacher calls admin_stats');
select pg_temp.expect_error($$select * from public.admin_list_users()$$, 'teacher lists users');
select pg_temp.expect_error($$select public.admin_update_profile('00000000-0000-0000-0000-00000000000a', p_role => 'admin')$$, 'teacher self-promotes via admin RPC');
select pg_temp.expect_error($$select public.log_admin_action('x', 'user', null)$$, 'client writes audit log directly');
select pg_temp.expect_error($$insert into public.admin_audit_log (action, target_type) values ('x', 'user')$$, 'client inserts audit row');
do $$ begin
  assert (select count(*) from public.admin_audit_log) = 0, 'non-admin sees no audit rows';
end $$;
reset role;

-- Promote the first admin directly in the database.
update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-00000000000d';
select pg_temp.as_user('00000000-0000-0000-0000-00000000000d');
do $$ declare s jsonb; n int; begin
  s := public.admin_stats();
  assert (s ->> 'teachers')::int = 1 and (s ->> 'students')::int = 2 and (s ->> 'admins')::int = 1, s::text;
  select count(*) into n from public.profiles;
  assert n = 4, 'admin reads all profiles';
  assert (select count(*) from public.teacher_codes) >= 1, 'admin reads all codes';
  assert (select count(*) from public.admin_list_users()) = 4;
  assert (select total_count from public.admin_list_users(p_search => 'müller') limit 1) = 1, 'search by name';
  assert (select count(*) from public.admin_list_users(p_search => 's2@x')) = 1, 'search by e-mail';
  assert (select count(*) from public.admin_list_users(p_role => 'student')) = 2;
end $$;
select pg_temp.expect_error($$select public.admin_update_profile(auth.uid(), p_role => 'student')$$, 'admin demotes self');

-- Link Sara directly to the teacher, then disconnect.
do $$ declare l record; begin
  select * into l from public.admin_link_student('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000c');
  assert l.status = 'active';
  select * into l from public.admin_disconnect_link(l.id);
  assert l.status = 'disconnected';
end $$;
select pg_temp.expect_error($$select public.admin_link_student('00000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-00000000000b')$$, 'link to a non-teacher');

-- Changing a teacher to student revokes the code and ends links.
do $$ declare p record; begin
  select * into p from public.admin_update_profile('00000000-0000-0000-0000-00000000000a', p_display_name => 'Herr M.', p_role => 'student', p_cefr_level => 'B2');
  assert p.role = 'student' and p.display_name = 'Herr M.' and p.cefr_level = 'B2';
  assert (select count(*) from public.teacher_codes where teacher_id = p.id and not revoked) = 0;
  assert (select count(*) from public.teacher_student_links where teacher_id = p.id and status <> 'disconnected') = 0;
  assert (select count(*) from public.admin_audit_log) = 3, 'three audited actions';
  assert (select details ->> 'role' from public.admin_audit_log where action = 'update_profile') = 'student';
end $$;
select pg_temp.expect_error($$select public.admin_update_profile('00000000-0000-0000-0000-00000000000b', p_cefr_level => 'Z9')$$, 'invalid CEFR level');
reset role;

set role service_role;
select public.log_admin_action_as('00000000-0000-0000-0000-00000000000d', 'block_user', 'user', '00000000-0000-0000-0000-00000000000b');
reset role;

select 'ALL SQL TESTS PASSED' as result;
