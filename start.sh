#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAPERCLIP_DIR="$SCRIPT_DIR/paperclip"

# ── Load .env ────────────────────────────────────────────────
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "ERROR: .env not found. Run ./setup.sh first."
  exit 1
fi
set -a
source "$SCRIPT_DIR/.env"
set +a

# ── Validate ─────────────────────────────────────────────────
if [ ! -f "$PAPERCLIP_DIR/server/dist/index.js" ]; then
  echo "ERROR: Paperclip not built. Run ./setup.sh first."
  exit 1
fi

for var in POSTGRES_PASSWORD CLOUDFLARE_TUNNEL_TOKEN BETTER_AUTH_SECRET PAPERCLIP_DOMAIN; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: $var is not set in .env"
    exit 1
  fi
done

# ── Start Docker services ───────────────────────────────────
echo "Starting PostgreSQL + Cloudflare Tunnel..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

echo "Waiting for PostgreSQL..."
until docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T db pg_isready -U paperclip &>/dev/null; do
  sleep 1
done
echo "PostgreSQL ready."

# ── Run database migrations ──────────────────────────────────
echo "Pushing database schema..."
cd "$PAPERCLIP_DIR"
DATABASE_URL="postgres://paperclip:${POSTGRES_PASSWORD}@localhost:5432/paperclip" \
  npx drizzle-kit push --force 2>/dev/null || true

# ── Export Paperclip environment ─────────────────────────────
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

if [ -n "${PAPERCLIP_SECRETS_MASTER_KEY:-}" ]; then
  export PAPERCLIP_SECRETS_MASTER_KEY
fi

if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  export CLAUDE_CODE_OAUTH_TOKEN
fi

# Force subscription billing — do not use metered API key
unset ANTHROPIC_API_KEY 2>/dev/null || true

mkdir -p "$SCRIPT_DIR/data/paperclip"

# ── Start Paperclip ──────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════"
echo "  Paperclip starting"
echo "  Public : https://${PAPERCLIP_DOMAIN}"
echo "  Local  : http://localhost:3100"
echo "════════════════════════════════════════════════"
echo "  Press Ctrl+C to stop Paperclip."
echo "  Docker services keep running (use ./stop.sh)."
echo ""

cd "$PAPERCLIP_DIR"
exec node --import ./server/node_modules/tsx/dist/loader.mjs server/dist/index.js
