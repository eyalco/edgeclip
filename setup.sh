#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAPERCLIP_DIR="$SCRIPT_DIR/paperclip"

echo "╔════════════════════════════════════════════╗"
echo "║        EdgeClip — One-Time Setup           ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# ── 1. Check prerequisites ──────────────────────────────────
echo "[1/6] Checking prerequisites..."
missing=()
for cmd in node pnpm git docker; do
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("$cmd")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "ERROR: Missing required tools: ${missing[*]}"
  echo ""
  echo "Install them:"
  echo "  node/pnpm : curl -fsSL https://get.pnpm.io/install.sh | sh -"
  echo "  git       : apt install git"
  echo "  docker    : https://docs.docker.com/engine/install/"
  exit 1
fi

NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "ERROR: Node.js 20+ required (found $(node -v))"
  exit 1
fi

echo "  node $(node -v), pnpm $(pnpm -v), git $(git --version | cut -d' ' -f3), docker $(docker --version | cut -d' ' -f3)"

# ── 2. Clone Paperclip ──────────────────────────────────────
echo "[2/6] Fetching Paperclip..."
if [ ! -d "$PAPERCLIP_DIR" ]; then
  git clone --depth 1 https://github.com/paperclipai/paperclip.git "$PAPERCLIP_DIR"
else
  echo "  Already cloned — pulling latest..."
  git -C "$PAPERCLIP_DIR" pull --ff-only || echo "  (pull skipped — may be on detached HEAD)"
fi

# ── 3. Install dependencies ─────────────────────────────────
echo "[3/6] Installing dependencies..."
cd "$PAPERCLIP_DIR"
pnpm install --frozen-lockfile

# ── 4. Build ─────────────────────────────────────────────────
echo "[4/6] Building Paperclip..."
pnpm --filter @paperclipai/shared build    2>/dev/null || true
pnpm --filter @paperclipai/db build        2>/dev/null || true
pnpm --filter @paperclipai/adapter-utils build 2>/dev/null || true
pnpm --filter @paperclipai/plugin-sdk build
pnpm --filter @paperclipai/ui build
pnpm --filter @paperclipai/server build

if [ ! -f server/dist/index.js ]; then
  echo "ERROR: Build failed — server/dist/index.js not found"
  exit 1
fi
echo "  Build OK"

# ── 5. Install Claude Code CLI ───────────────────────────────
echo "[5/6] Checking Claude Code CLI..."
if command -v claude &>/dev/null; then
  echo "  claude $(claude --version 2>/dev/null || echo '(installed)')"
else
  echo "  Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code@latest
fi

# ── 6. Create .env from template ─────────────────────────────
echo "[6/6] Preparing .env..."
cd "$SCRIPT_DIR"
if [ ! -f .env ]; then
  cp .env.example .env
  echo ""
  echo "  Created .env — you MUST edit it before starting."
  echo ""
  echo "  Generate secrets:"
  echo "    openssl rand -base64 24   → POSTGRES_PASSWORD"
  echo "    openssl rand -base64 32   → BETTER_AUTH_SECRET"
  echo "    openssl rand -base64 32   → PAPERCLIP_SECRETS_MASTER_KEY"
  echo "    claude setup-token        → CLAUDE_CODE_OAUTH_TOKEN"
  echo ""
  echo "  Get tunnel token:"
  echo "    Cloudflare Zero Trust → Networks → Tunnels → Create"
  echo "    Set public hostname service to: http://localhost:3100"
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
