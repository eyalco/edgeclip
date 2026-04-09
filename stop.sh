#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Stopping EdgeClip..."

# Stop Docker infrastructure (PostgreSQL + Cloudflare Tunnel)
docker compose -f "$SCRIPT_DIR/docker-compose.yml" down

echo ""
echo "All services stopped."
echo "Note: if the Paperclip server is running in a terminal, press Ctrl+C to stop it."
