-- DeutschLearn Phase 1: profiles and roles.
-- Every auth user gets exactly one profile row, created by a trigger.

create type public.user_role as enum ('student', 'teacher', 'admin');

create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  role         public.user_role not null default 'student',
  display_name text not null default '' check (char_length(display_name) <= 80),
  locale       text not null default 'ar' check (locale in ('ar', 'de', 'en')),
  avatar_url   text check (avatar_url is null or avatar_url ~ '^https://'),
  cefr_level   text not null default 'A1' check (cefr_level in ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index profiles_role_idx on public.profiles (role);

-- Helper used by policies and RPCs. SECURITY DEFINER so policies on other
-- tables can check the caller's role without recursing into profiles RLS.
create or replace function public.current_user_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select p.role from public.profiles p where p.id = auth.uid();
$$;

revoke all on function public.current_user_role() from public, anon;
grant execute on function public.current_user_role() to authenticated;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

-- Create the profile when a user signs up. Only 'student' and 'teacher' may be
-- requested through sign-up metadata; 'admin' is never self-assigned.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text := coalesce(new.raw_user_meta_data ->> 'role', 'student');
  requested_locale text := coalesce(new.raw_user_meta_data ->> 'locale', 'ar');
begin
  if requested_role not in ('student', 'teacher') then
    requested_role := 'student';
  end if;
  if requested_locale not in ('ar', 'de', 'en') then
    requested_locale := 'ar';
  end if;

  insert into public.profiles (id, role, display_name, locale)
  values (
    new.id,
    requested_role::public.user_role,
    left(coalesce(new.raw_user_meta_data ->> 'display_name', ''), 80),
    requested_locale
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;

-- Users only change their own non-privileged columns. role and cefr_level are
-- not granted, so they cannot be self-promoted.
revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to authenticated;
grant update (display_name, locale, avatar_url) on table public.profiles to authenticated;

create policy "profiles: read own"
on public.profiles for select
to authenticated
using (id = (select auth.uid()));

create policy "profiles: update own"
on public.profiles for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));
