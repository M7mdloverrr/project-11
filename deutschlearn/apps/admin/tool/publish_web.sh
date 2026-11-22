#!/usr/bin/env bash
# Builds the admin panel for GitHub Pages and copies it to deutschlearn/admin-web/,
# which Pages serves at https://m7mdloverrr.github.io/project-11/deutschlearn/admin-web/
# Needs deutschlearn/.env with SUPABASE_URL and SUPABASE_ANON_KEY (anon key only).
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --release --no-wasm-dry-run \
  --base-href /project-11/deutschlearn/admin-web/ \
  --dart-define-from-file=../../.env
rm -rf ../../admin-web
cp -r build/web ../../admin-web
rm -f ../../admin-web/.last_build_id
echo "Built into deutschlearn/admin-web/"
