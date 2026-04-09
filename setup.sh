#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔════════════════════════════════════════════╗"
echo "║        EdgeClip — One-Time Setup           ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# ── 1. Check prerequisites ──────────────────────────────────
echo "[1/4] Checking prerequisites..."
missing=()
for cmd in node docker claude; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "ERROR: Missing required tools: ${missing[*]}"
  echo ""
  echo "Install them:"
  echo "  node   : https://nodejs.org (v20+)"
  echo "  docker : https://docs.docker.com/engine/install/"
  echo "  claude : npm install -g @anthropic-ai/claude-code"
  exit 1
fi

if ! docker compose version &>/dev/null; then
  echo "ERROR: docker compose plugin not found"
  echo "  Install: https://docs.docker.com/compose/install/"
  exit 1
fi

echo "  node $(node --version), docker $(docker --version | cut -d' ' -f3)"

# ── 2. Install Paperclip ─────────────────────────────────────
echo "[2/4] Installing Paperclip..."
if command -v paperclipai &>/dev/null; then
  echo "  paperclipai already installed ($(paperclipai --version 2>/dev/null || echo 'unknown version'))"
  echo "  To update: npm update -g paperclipai"
else
  SUDO=""
  if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi
  $SUDO npm install -g paperclipai
  echo "  Installed paperclipai $(paperclipai --version 2>/dev/null || echo '')"
fi

# ── 3. Create .env from template ─────────────────────────────
echo "[3/4] Preparing .env..."
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
  echo ""
  echo "  Created .env — you MUST edit it before starting the service."
  echo ""
  echo "  Required values:"
  echo "    CLOUDFLARE_TUNNEL_TOKEN  → cloudflared tunnel token <name>"
  echo "    POSTGRES_PASSWORD        → openssl rand -base64 24"
  echo "    PAPERCLIP_DOMAIN         → your public hostname"
  echo "    BETTER_AUTH_SECRET       → openssl rand -base64 32"
  echo ""
  echo "  After editing .env, re-run this script to install the service."
  exit 0
fi

# Validate required values are set
source "$SCRIPT_DIR/.env"
missing_vars=()
for var in POSTGRES_PASSWORD BETTER_AUTH_SECRET PAPERCLIP_DOMAIN CLOUDFLARE_TUNNEL_TOKEN; do
  if [ -z "${!var:-}" ]; then
    missing_vars+=("$var")
  fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
  echo "  ERROR: Missing required values in .env: ${missing_vars[*]}"
  echo "  Edit .env and re-run this script."
  exit 1
fi
echo "  .env validated."

# ── 4. Install systemd service ───────────────────────────────
echo "[4/4] Installing systemd service..."

SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

CURRENT_USER="$(whoami)"
SERVICE_FILE="/etc/systemd/system/edgeclip.service"

$SUDO tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=EdgeClip — Paperclip Agent Orchestration
After=network-online.target docker.service
Requires=docker.service
Wants=network-online.target

[Service]
Type=forking
PIDFile=$SCRIPT_DIR/.paperclip.pid
User=$CURRENT_USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/start-service.sh
ExecStop=$SCRIPT_DIR/stop.sh
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

$SUDO systemctl daemon-reload
$SUDO systemctl enable edgeclip
$SUDO systemctl start edgeclip

echo "  Service installed and started."
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║            Setup complete!                 ║"
echo "╠════════════════════════════════════════════╣"
echo "║  Service: sudo systemctl status edgeclip   ║"
echo "║  Logs:    journalctl -u edgeclip -f        ║"
echo "║           tail -f paperclip.log            ║"
echo "║  Stop:    sudo systemctl stop edgeclip     ║"
echo "║  Start:   sudo systemctl start edgeclip    ║"
echo "╚════════════════════════════════════════════╝"
