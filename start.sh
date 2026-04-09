#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Load .env ────────────────────────────────────────────────
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "ERROR: .env not found. Run ./setup.sh first."
  exit 1
fi

set -a
source "$SCRIPT_DIR/.env"
set +a

for var in POSTGRES_PASSWORD BETTER_AUTH_SECRET PAPERCLIP_DOMAIN; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: $var is not set in .env"
    exit 1
  fi
done

if ! command -v paperclipai &>/dev/null; then
  echo "ERROR: paperclipai not installed. Run ./setup.sh first."
  exit 1
fi

# ── Start infrastructure (PostgreSQL + Cloudflare Tunnel) ────
echo ""
echo "════════════════════════════════════════════════"
echo "  EdgeClip starting"
echo "  Public : https://$PAPERCLIP_DOMAIN"
echo "  Local  : http://localhost:3100"
echo "════════════════════════════════════════════════"
echo ""

docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d
echo "  PostgreSQL + Cloudflare Tunnel started."

echo "  Waiting for database..."
until docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T db \
  pg_isready -U paperclip -d paperclip &>/dev/null; do
  sleep 1
done
echo "  Database ready."
echo ""

# ── Stop infrastructure on exit ──────────────────────────────
cleanup() {
  echo ""
  echo "Shutting down..."
  docker compose -f "$SCRIPT_DIR/docker-compose.yml" down
  echo "All services stopped."
}
trap cleanup EXIT

# ── Start Paperclip server on the host ───────────────────────
export PAPERCLIP_HOME="$SCRIPT_DIR/data"
export HOST="${EDGECLIP_BIND_HOST:-127.0.0.1}"
export PORT="3100"
export SERVE_UI="true"
export NODE_ENV="production"
export DATABASE_URL="postgres://paperclip:${POSTGRES_PASSWORD}@localhost:5432/paperclip"
export PAPERCLIP_DEPLOYMENT_MODE="authenticated"
export PAPERCLIP_DEPLOYMENT_EXPOSURE="public"
export PAPERCLIP_PUBLIC_URL="https://${PAPERCLIP_DOMAIN}"
export PAPERCLIP_AUTH_BASE_URL_MODE="explicit"
export BETTER_AUTH_SECRET
export PAPERCLIP_SECRETS_MASTER_KEY="${PAPERCLIP_SECRETS_MASTER_KEY:-}"
export PAPERCLIP_AGENT_JWT_SECRET="${PAPERCLIP_AGENT_JWT_SECRET:-${BETTER_AUTH_SECRET}}"

exec paperclipai run
