# DeutschLearn – Setup

Everything here uses free tiers (Supabase Free plan, Flutter SDK, Android SDK).

## 1. Flutter
1. Install Flutter ≥ 3.38 (tested with 3.50.1): https://docs.flutter.dev/get-started/install
2. Install Android Studio (for the Android SDK + an emulator): https://developer.android.com/studio
3. Check: `flutter doctor`
4. Install dependencies once for the whole workspace:
   ```bash
   cd deutschlearn
   flutter pub get
   ```

You can already run both apps now — without credentials they show a clear **"Backend nicht konfiguriert"** screen:
```bash
cd deutschlearn/apps/student && flutter run
cd deutschlearn/apps/teacher && flutter run
```

## 2. Supabase project (free)
1. Sign up / log in: https://supabase.com/dashboard → **New project** (Free plan, pick region `eu-central-1` Frankfurt). Save the database password.
2. Open **Project Settings → API** (https://supabase.com/dashboard/project/_/settings/api) and copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon / publishable key** → `SUPABASE_ANON_KEY`
   - ⚠️ Do **not** copy the `service_role` / secret key into the apps. The apps refuse to start with it.
3. **Authentication → URL Configuration** (https://supabase.com/dashboard/project/_/auth/url-configuration) → add both redirect URLs:
   - `com.deutschlearn.student://auth-callback`
   - `com.deutschlearn.teacher://auth-callback`
   (used by e-mail confirmation and password-reset links).

## 3. Database + edge functions
Install the Supabase CLI: https://supabase.com/docs/guides/local-development/cli/getting-started (e.g. `npm i -g supabase` or `brew install supabase/tap/supabase`).

```bash
cd deutschlearn
supabase login
supabase link --project-ref YOUR_PROJECT_REF      # the xxxx in https://xxxx.supabase.co
supabase db push                                   # applies supabase/migrations/*.sql in order
supabase functions deploy generate-teacher-code
supabase functions deploy resolve-teacher-code
```
The edge functions automatically receive `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` from Supabase — the service-role key stays on the server.

No CLI? Paste the three files from `supabase/migrations/` into **SQL Editor** (https://supabase.com/dashboard/project/_/sql/new) in filename order, then deploy the functions from **Edge Functions → Deploy a new function** with the contents of each `index.ts` (plus `_shared/`).

## 4. Put the credentials into the apps
```bash
cd deutschlearn
cp .env.example .env        # .env is git-ignored
# edit .env: SUPABASE_URL=https://xxxx.supabase.co  SUPABASE_ANON_KEY=eyJ... (or sb_publishable_...)
```
Run / build with the file:
```bash
cd apps/student
flutter run --dart-define-from-file=../../.env
flutter build apk --debug --dart-define-from-file=../../.env

cd ../teacher
flutter run --dart-define-from-file=../../.env
```
(Equivalent: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.)

Android emulator against a local Supabase (`supabase start`): use `SUPABASE_URL=http://10.0.2.2:54321`.

## 5. First end-to-end check
1. Teacher app → register → set display name → **Code erzeugen** → you get `TCH-XXXXXX`.
2. Student app → register → Start tab → **Lehrer verbinden** → enter the code → see the teacher's name → confirm → status "pending".
3. Teacher app → pending request → **Annehmen** → student app (pull to refresh) shows "active".

## 6. Tests & checks
```bash
cd deutschlearn
flutter analyze
(cd packages/core && flutter test)
(cd packages/auth && flutter test)
(cd apps/student && flutter test)
(cd apps/teacher && flutter test)

# Supabase SQL / RLS tests (needs Docker)
supabase/tests/run_sql_tests.sh
# Edge-function unit tests (needs Deno)
(cd supabase/functions && deno test)
```
