#!/usr/bin/env bash
# Headless startup for systemd — skips docker compose (handled by ExecStartPre).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAPERCLIP_DIR="$SCRIPT_DIR/paperclip"

set -a
source "$SCRIPT_DIR/.env"
set +a

# Wait for Postgres
until pg_isready -h localhost -U paperclip -q 2>/dev/null || \
      docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T db pg_isready -U paperclip &>/dev/null; do
  sleep 1
done

cd "$PAPERCLIP_DIR"

DATABASE_URL="postgres://paperclip:${POSTGRES_PASSWORD}@localhost:5432/paperclip" \
  npx drizzle-kit push --force 2>/dev/null || true

export NODE_ENV=production
export HOST=0.0.0.0
export PORT=3100
export SERVE_UI=true
export DATABASE_URL="postgres://paperclip:${POSTGRES_PASSWORD}@localhost:5432/paperclip"
export PAPERCLIP_HOME="$SCRIPT_DIR/data/paperclip"
export PAPERCLIP_INSTANCE_ID=default
export PAPERCLIP_DEPLOYMENT_MODE=authenticated
export PAPERCLIP_DEPLOYMENT_EXPOSURE=public
export PAPERCLIP_PUBLIC_URL="https://${PAPERCLIP_DOMAIN}"

[ -n "${PAPERCLIP_SECRETS_MASTER_KEY:-}" ] && export PAPERCLIP_SECRETS_MASTER_KEY
[ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]      && export CLAUDE_CODE_OAUTH_TOKEN
unset ANTHROPIC_API_KEY 2>/dev/null || true

mkdir -p "$SCRIPT_DIR/data/paperclip"

exec node --import ./server/node_modules/tsx/dist/loader.mjs server/dist/index.js
