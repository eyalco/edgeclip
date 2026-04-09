#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔════════════════════════════════════════════╗"
echo "║        EdgeClip — One-Time Setup           ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# ── 1. Check prerequisites ──────────────────────────────────
echo "[1/3] Checking prerequisites..."
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
echo "[2/3] Installing Paperclip..."
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
echo "[3/3] Preparing .env..."
if [ ! -f "$SCRIPT_DIR/.env" ]; then
  cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
  echo ""
  echo "  Created .env — you MUST edit it before starting."
  echo ""
  echo "  Generate secrets:"
  echo "    openssl rand -base64 24   → POSTGRES_PASSWORD"
  echo "    openssl rand -base64 32   → BETTER_AUTH_SECRET"
  echo "    openssl rand -base64 32   → PAPERCLIP_SECRETS_MASTER_KEY"
  echo "    openssl rand -base64 32   → PAPERCLIP_AGENT_JWT_SECRET (or reuse BETTER_AUTH_SECRET)"
  echo ""
  echo "  Get tunnel credentials:"
  echo "    cloudflared tunnel login"
  echo "    cloudflared tunnel create edgeclip"
  echo "    cloudflared tunnel route dns edgeclip YOUR_DOMAIN"
else
  echo "  .env already exists — skipping"
fi

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║            Setup complete!                 ║"
echo "╠════════════════════════════════════════════╣"
echo "║  1. Edit .env with your values             ║"
echo "║  2. Run: ./start.sh                        ║"
echo "╚════════════════════════════════════════════╝"
