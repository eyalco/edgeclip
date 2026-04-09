#!/usr/bin/env bash
# Headless startup for systemd / background use.
# Starts infrastructure in Docker, then runs Paperclip as a background process.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/.paperclip.pid"

if [ ! -f "$SCRIPT_DIR/.env" ]; then
  echo "ERROR: .env not found. Run ./setup.sh first."
  exit 1
fi

set -a
source "$SCRIPT_DIR/.env"
set +a

for var in POSTGRES_PASSWORD BETTER_AUTH_SECRET PAPERCLIP_DOMAIN CLOUDFLARE_TUNNEL_TOKEN; do
  if [ -z "${!var:-}" ]; then
    echo "ERROR: $var is not set in .env"
    exit 1
  fi
done

# Start infrastructure
docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d

# Wait for database
until docker compose -f "$SCRIPT_DIR/docker-compose.yml" exec -T db \
  pg_isready -U paperclip -d paperclip &>/dev/null; do
  sleep 1
done

# Paperclip environment
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
export PAPERCLIP_MIGRATION_AUTO_APPLY="true"
export PAPERCLIP_OPEN_ON_LISTEN="false"

# Create config non-interactively if it doesn't exist yet
if [ ! -f "$SCRIPT_DIR/data/instances/default/config.json" ]; then
  echo "First run — running onboard..."
  paperclipai onboard --yes --data-dir "$SCRIPT_DIR/data"
fi

# Start Paperclip in background
nohup paperclipai run --data-dir "$SCRIPT_DIR/data" >> "$SCRIPT_DIR/paperclip.log" 2>&1 &
echo $! > "$PID_FILE"

echo "EdgeClip started (PID $(cat "$PID_FILE"))"
echo "Logs: tail -f $SCRIPT_DIR/paperclip.log"
