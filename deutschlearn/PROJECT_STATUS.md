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
| Auth | E-mail sign-up, login, password reset (e-mail link → new password screen), session restore | 🔑 (backend live) |
| Supabase | Migrations: `profiles`, `teacher_codes`, `teacher_student_links`, `link_requests`, FKs, indexes, RLS, RPCs (`lookup_teacher_by_code`, `issue_teacher_code`, `request_teacher_link`, `respond_link_request`, `disconnect_link`) | ✅ tested in Postgres 16 (`supabase/tests`) — 🔑 needs `supabase db push` to a real project |
| Supabase | Edge functions `generate-teacher-code` (crypto-random) and `resolve-teacher-code` | ✅ Deno unit tests — 🔑 needs deploy |
| Student app | Splash + session restore, Arabic onboarding (3 pages), sign-up/login/reset screens | ✅ UI · 🔑 backend calls |
| Student app | Link teacher: enter code → teacher public name → confirm → pending / active / disconnected, disconnect, re-link | ✅ UI (widget-tested with fake backend) · 🔑 real data |
| Student app | Home shell: greeting, CEFR stage from profile, 5 tabs (Start, Lektionen, Fortschritt, Chat, Profil); Chat shows honest "coming soon" | ✅ |
| Lessons | 8 seeded A1 lessons (100 items: words, phrases, quizzes, Arabic explanations); lesson player with quiz feedback; best score + attempts saved via `complete_lesson`; Fortschritt tab (overall/level progress, average score, next lesson) | ✅ live |
| Teacher tools | Tap a linked student: lesson-by-lesson progress (best score, attempts, average) and assign/remove lessons as homework (`lesson_assignments`, RLS: active link + published lesson). Students see Hausaufgaben on Start and a badge in Lektionen | ✅ live |
| Chat | Live teacher ↔ student chat (`chat_messages`, Supabase Realtime). Students: Chat tab once the link is active. Teachers: chat icon on a student's page. RLS: only the two parties (and admins) read; sending needs an active link; no edits | ✅ live |
| Admin lessons | Create/edit/publish/delete lessons; edit, reorder and remove words/phrases/quiz questions | ✅ live |
| Teacher app | Splash, registration/login, profile setup (display name), dashboard | ✅ UI · 🔑 backend calls |
| Teacher app | Teacher code: generate, copy, share, regenerate, revoke | ✅ UI (widget-tested) · 🔑 real codes |
| Teacher app | Pending link requests (approve/decline), linked students (disconnect) | ✅ UI (widget-tested) · 🔑 real data |
| Admin panel | Web app `apps/admin` (Flutter web, English), published from `admin-web/` on GitHub Pages; admins only | ✅ widget-tested · ✅ checked against the live backend |
| Admin panel | Overview numbers; users: search, filter by role, edit name/role/CEFR level/language, add (password or invite e-mail), block/unblock, delete, confirm e-mail, password reset link or e-mail | ✅ |
| Admin panel | Teacher codes: list (incl. revoked), issue for any teacher, revoke · Links: approve/decline requests, link a student to a teacher directly, disconnect · Activity log of every admin action | ✅ |
| Supabase | Migration `…0400_admin.sql` (admin read policies, `admin_audit_log`, `admin_*` RPCs) + edge function `admin-users` (Auth admin API, service role server-side only) | ✅ applied & deployed |
| Docs | `SETUP.md`, `DECISIONS.md`, `.env.example`, this file | ✅ |
| Tests | Unit: code format, link-state model, env validation, validators, router guard · Widget: login validation, link-teacher flow, teacher dashboard, not-configured app start | ✅ `flutter test` green, `flutter analyze` clean |

## Current
- ✅ **Supabase project connected** (ref `tbmeljyfczvtpxiowvub`): the 3 migrations are applied, both edge functions are deployed, and the auth redirect URLs for both apps are set. 🔑 items above now work against it.
- ✅ Live backend check (scripted with throw-away users, deleted afterwards): sign-in, profile fetch/update, generate/regenerate/revoke code, public lookup, link request, decline, re-request, approve, linked students, disconnect; a student cannot generate codes, read `teacher_codes` or change their own role; anonymous users cannot read profiles.
- ✅ Admin panel: migration applied, `admin-users` deployed, live check of every admin action with throw-away users. First admin: `almuhamad.mouhamad319@gmail.com`.
- Next: run the end-to-end check in `SETUP.md` §5 on a phone with APKs built with `--dart-define-from-file=../../.env`.

## Blocked / limits
- "Confirm email" is **off** on the live project (sign-ups need no e-mail). Password-reset e-mails use Supabase's built-in mailer, limited to 2 e-mails/hour on the free plan; admins can instead create a one-time reset link in the admin panel and share it by hand. To raise the limit, add free SMTP (e.g. Resend) under Authentication → Emails → SMTP.

## Not started (later phases)
- ⏳ notifications, iOS builds, release signing / Play Store.
