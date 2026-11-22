# DeutschLearn – Project status (Phase 1)

Legend: ✅ implemented & tested locally · 🔑 implemented, needs Supabase credentials to work for real · ⏳ not started (later phase)

## Done
| Area | Feature | State |
|---|---|---|
| Repo | Flutter pub-workspace mono-repo (`apps/student`, `apps/teacher`, `packages/*`, `supabase/`) | ✅ |
| Repo | App IDs `com.deutschlearn.student` / `com.deutschlearn.teacher`, both build `flutter build apk --debug` | ✅ |
| Design system | Color tokens, light/dark theme, Cairo font, RTL/LTR helpers, cards/buttons/progress/feedback widgets | ✅ |
| Core | Models `Profile`, `Role`, `CefrLevel`, `TeacherCode`, `TeacherStudentLink`, `LinkRequest`; env validation; Supabase wrapper; Riverpod providers | ✅ |
| Core | "Backend not configured" mode when env is missing/placeholder/service-role key (no fake backend in the apps) | ✅ |
| Auth | Validation (e-mail, password ≥ 8 with letters+digits, display name), role-aware router guard | ✅ |
| Auth | E-mail sign-up, login, password reset (e-mail link → new password screen), session restore | 🔑 |
| Supabase | Migrations: `profiles`, `teacher_codes`, `teacher_student_links`, `link_requests`, FKs, indexes, RLS, RPCs (`lookup_teacher_by_code`, `issue_teacher_code`, `request_teacher_link`, `respond_link_request`, `disconnect_link`) | ✅ tested in Postgres 16 (`supabase/tests`) — 🔑 needs `supabase db push` to a real project |
| Supabase | Edge functions `generate-teacher-code` (crypto-random) and `resolve-teacher-code` | ✅ Deno unit tests — 🔑 needs deploy |
| Student app | Splash + session restore, Arabic onboarding (3 pages), sign-up/login/reset screens | ✅ UI · 🔑 backend calls |
| Student app | Link teacher: enter code → teacher public name → confirm → pending / active / disconnected, disconnect, re-link | ✅ UI (widget-tested with fake backend) · 🔑 real data |
| Student app | Home shell: greeting, CEFR stage from profile, 5 tabs (Start, Lektionen, Fortschritt, Chat, Profil); Lektionen/Fortschritt/Chat show honest "coming soon" | ✅ |
| Teacher app | Splash, registration/login, profile setup (display name), dashboard | ✅ UI · 🔑 backend calls |
| Teacher app | Teacher code: generate, copy, share, regenerate, revoke | ✅ UI (widget-tested) · 🔑 real codes |
| Teacher app | Pending link requests (approve/decline), linked students (disconnect) | ✅ UI (widget-tested) · 🔑 real data |
| Docs | `SETUP.md`, `DECISIONS.md`, `.env.example`, this file | ✅ |
| Tests | Unit: code format, link-state model, env validation, validators, router guard · Widget: login validation, link-teacher flow, teacher dashboard, not-configured app start | ✅ `flutter test` green, `flutter analyze` clean |

## Current
- Phase 1 is feature-complete in code. Next step is connecting a real Supabase project (see `SETUP.md` §2–4) and running the end-to-end check in `SETUP.md` §5 on a device.

## Blocked / awaiting credentials
- 🔑 **Supabase project not created yet** → no real sign-up/login, codes or links. Needed: `SUPABASE_URL` + anon/publishable key in `deutschlearn/.env`, migrations pushed, both edge functions deployed, redirect URLs added.
- E-mail confirmation & reset links use the default Supabase mailer (free tier: low hourly limit). A custom SMTP can be added later.

## Not started (later phases)
- ⏳ Lessons content, progress tracking, chat, notifications, admin tools, iOS builds, release signing / Play Store.
