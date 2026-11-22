# DeutschLearn – Architecture decisions

## 1. Mono-repo with Dart pub workspaces
- Layout: `apps/student`, `apps/teacher` (two separate Android apps) + `packages/design_system`, `packages/core`, `packages/auth` + `supabase/`.
- The root `pubspec.yaml` declares a [pub workspace](https://dart.dev/tools/pub/workspaces): one `flutter pub get` at `deutschlearn/` resolves every app and package with a single lockfile, so versions can never drift between the two apps. No Melos needed.
- Two apps instead of one app with role switching: separate store listings / IDs (`com.deutschlearn.student`, `com.deutschlearn.teacher`), smaller apps, and a student can never reach teacher UI. Both share one Supabase project; each app only admits its own role (`allowedRolesProvider`), a wrong-role login shows an explicit screen.
- Lives in `deutschlearn/` so the existing Quran web app at the repo root is untouched.

## 2. Riverpod everywhere
- `flutter_riverpod` 3 is the single state-management and dependency-injection mechanism (no `setState` for business state, no GetIt, no Bloc).
- Backend access goes through interfaces (`AuthGateway`, `ProfileRepository`, `LinkRepository`) exposed as providers in `core`. Tests override them with in-memory fakes (`package:core/testing.dart`); production picks Supabase or the explicit "not configured" implementation.
- Why Riverpod: compile-safe providers, trivial overrides for tests, `AsyncValue` gives loading/error/data states for free, works without `BuildContext`.
- Automatic provider retry is disabled (`retry: noRetry`) so failures are shown to the user instead of being silently retried.

## 3. Honest "backend not configured" state
- Credentials come from `--dart-define(-from-file)` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). `AppEnv.issues` rejects missing values, `.env.example` placeholders, non-https URLs (except localhost/emulator) and service-role/secret keys.
- When invalid, `Supabase.initialize` is never called; repositories are replaced by `Unconfigured*` implementations that throw `FailureKind.backendNotConfigured`. The apps show a "Backend nicht konfiguriert" screen/banner. Nothing pretends to work.

## 4. Teacher code format: `TCH-XXXXXX`
- 6 characters from a 32-symbol alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no `0/O/1/I`, easy to read aloud and type) → 32⁶ ≈ 1.07 billion codes.
- Generated server-side only: edge function `generate-teacher-code` uses `crypto.getRandomValues` with rejection-free mapping (256 is a multiple of 32, so no modulo bias), then the security-definer SQL function `issue_teacher_code` stores it (unique index, retries on collision, revokes the previous code). Clients can't insert codes (no INSERT policy).
- One active code per teacher (partial unique index). Revocation is one-way; "regenerate" = revoke + issue new.
- Input is normalised leniently (`tch 7k2p9q`, `7K2-P9Q` → `TCH-7K2P9Q`) in both Dart (`TeacherCodeFormat`) and TypeScript.
- Lookup (`lookup_teacher_by_code`) is a security-definer RPC returning only display name + avatar, and is rate-limited per user (20/10 min) to stop enumeration.

## 5. Linking model
- `teacher_student_links` (unique `(teacher_id, student_id)`; status `pending → active → disconnected`, `disconnected → pending` on re-request) plus `link_requests` (audit trail of each request: pending/approved/declined/cancelled).
- A student may have at most one pending/active link at a time (partial unique index). All state changes go through security-definer RPCs (`request_teacher_link`, `respond_link_request`, `disconnect_link`); tables have no client INSERT/UPDATE policies, so transitions can't be forged.

## 6. Design system
- Tokens from the spec (Navy `#102A43`, Teal `#0E9488`, Blue `#2387D1`, Mint `#E8F8F3`, Yellow `#FFC857`, Success `#28A745`, Error `#EA5353`, Background `#F6F9FC`), light + dark `ThemeData`, bundled **Cairo** font (Arabic + Latin, OFL) so Arabic and German render consistently offline.
- Arabic UI is RTL by default; German strings are shown next to Arabic (`عربي • Deutsch`). `DLDirectional`/`LtrIsland` helpers keep codes, emails and German sentences LTR inside RTL layouts.

## 7. Admin panel as a Flutter web app on GitHub Pages
- Reuses the shared packages (core models, Riverpod, session/guard, design system), so there is one codebase and one data layer.
- Free hosting with no extra account: the repo already serves GitHub Pages from `main`, so the built panel lives in `deutschlearn/admin-web/` (hash URLs, so reloads work on Pages).
- English UI (the operator reads English). Only role `admin` passes the router guard; every write goes through `admin_*` RPCs or the `admin-users` edge function, which re-check the role on the server and write to `admin_audit_log`.
- Account operations (create, block, delete, password reset, confirm e-mail) need the Auth admin API, so they run in the edge function with the service role; the panel itself only ships the publishable key.
- Admins cannot change their own role, block or delete themselves, so the last admin cannot lock everyone out.
