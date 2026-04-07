#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Stopping Docker services (PostgreSQL + Cloudflared)..."
docker compose -f "$SCRIPT_DIR/docker-compose.yml" down

echo ""
echo "Docker services stopped."
echo "If Paperclip is running in the foreground, press Ctrl+C in that terminal."
echo "If running via systemd: sudo systemctl stop edgeclip"
