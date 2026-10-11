#!/usr/bin/env bash

# Runs only against a temporary local Supabase stack. It never accepts a linked
# project, database URL, or production credential.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
workspace=$(mktemp -d)
workspace_root="$workspace/release1"
migrations_dir="$workspace_root/supabase/migrations"

mkdir -p "$migrations_dir"
cp "$repo_root/supabase/config.toml" "$workspace_root/supabase/config.toml"

for migration in "$repo_root"/supabase/migrations/*.sql; do
  filename=$(basename "$migration")
  version=${filename%%_*}
  if [[ "$version" < "202610090001" ]]; then
    cp "$migration" "$migrations_dir/$filename"
  fi
done

# 202607180001 deliberately refuses to schedule an outbox without a Vault
# secret. Supply a non-production placeholder only in this disposable chain.
cp "$repo_root/ci/release1/pre_outbox_vault_fixture.sql" \
  "$migrations_dir/202607170002_ci_release1_vault_fixture.sql"

for excluded in 202610090001 202610090002 202610100001 202610100002 202610100003; do
  if compgen -G "$migrations_dir/${excluded}_*.sql" > /dev/null; then
    echo "Unexpected pre-fixture migration $excluded in Release 1 workspace." >&2
    exit 1
  fi
done

for required in 202609220001 202609240002; do
  if ! compgen -G "$migrations_dir/${required}_*.sql" > /dev/null; then
    echo "Required migration $required is missing from Release 1 workspace." >&2
    exit 1
  fi
done

echo 'Release 1 local migration workspace:'
find "$migrations_dir" -maxdepth 1 -type f -name '*.sql' -printf '%f\n' | sort

pushd "$workspace_root" > /dev/null
supabase start
supabase db reset --local
popd > /dev/null

# Seed legacy-shaped data against the remote-equivalent migration baseline
# before the Release 1 migrations are present. This makes the backfill in
# 202610100001 executable rather than merely syntactically checked.
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' \
  --set ON_ERROR_STOP=1 \
  --file "$repo_root/ci/release1/pre_lifecycle_migration_fixture.sql"

cp "$repo_root/supabase/migrations/202610090002_track_cancellation_sync_state.sql" "$migrations_dir/"
cp "$repo_root/supabase/migrations/202610100001_secure_paid_appointment_lifecycle.sql" "$migrations_dir/"

pushd "$workspace_root" > /dev/null
supabase db push --local
supabase db lint --local --level error --fail-on error
popd > /dev/null

for required in 202610090002 202610100001; do
  if ! compgen -G "$migrations_dir/${required}_*.sql" > /dev/null; then
    echo "Required post-fixture migration $required is missing from Release 1 workspace." >&2
    exit 1
  fi
done

# The local Supabase default database is disposable. The lifecycle test creates
# additional synthetic identities, clinics, services, appointments, payments,
# and webhook events itself.
psql 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' \
  --set ON_ERROR_STOP=1 \
  --file "$repo_root/ci/release1/payment_lifecycle.sql"

echo 'Release 1 structural migration validation passed.'
