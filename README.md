# EdgeClip

Turnkey deployment of [Paperclip](https://github.com/paperclipai/paperclip) agent orchestration with PostgreSQL and Cloudflare Tunnel. Paperclip and Claude Code run natively on the host for direct system access.

## Architecture

```
Internet
  │
  ▼
Cloudflare Tunnel (Docker) ──► https://edgeclip.yourdomain.com
  │
  ▼
Paperclip Server (host, port 3100)
  ├── Claude Code CLI (host, full system access)
  └── PostgreSQL 17 (Docker, port 5432)
```

- **Paperclip server** runs on the host via the `paperclipai` npm package
- **Claude Code CLI** runs on the host with full filesystem and Docker access
- **PostgreSQL** runs in Docker, exposed on `localhost:5432`
- **Cloudflare Tunnel** runs in Docker (host network), proxies your domain to `localhost:3100`
- No ports exposed to the internet — Paperclip binds to `127.0.0.1` by default, all traffic goes through the tunnel

## Prerequisites

- **Node.js** v20+
- **Docker** and Docker Compose (for PostgreSQL + Cloudflare Tunnel)
- **Claude Code CLI** (`npm install -g @anthropic-ai/claude-code`)
- A **Cloudflare account** with a domain
- **Claude Max plan** (or an Anthropic API key)

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/YOUR_USER/edgeclip.git
cd edgeclip

# 2. Run setup (installs paperclipai globally, creates .env)
chmod +x setup.sh start.sh stop.sh start-service.sh
./setup.sh

# 3. Edit .env with your values
nano .env

# 4. Start everything (Ctrl+C to stop)
./start.sh
```

## .env Variables

| Variable | Required | How to get |
|---|---|---|
| `POSTGRES_PASSWORD` | Yes | `openssl rand -base64 24` |
| `PAPERCLIP_DOMAIN` | Yes | The public hostname you configured in the tunnel |
| `BETTER_AUTH_SECRET` | Yes | `openssl rand -base64 32` |
| `PAPERCLIP_SECRETS_MASTER_KEY` | Recommended | `openssl rand -base64 32` |
| `EDGECLIP_BIND_HOST` | No | `127.0.0.1` (default) or `0.0.0.0` for local dev with Docker Desktop |

## Cloudflare Tunnel Setup

1. Install `cloudflared` locally: `brew install cloudflared` or [download](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/)
2. Authenticate: `cloudflared tunnel login`
3. Create tunnel: `cloudflared tunnel create edgeclip`
4. Route DNS: `cloudflared tunnel route dns edgeclip edgeclip.yourdomain.com`
5. Copy the credentials JSON from `~/.cloudflared/<TUNNEL_ID>.json` into `cloudflared/credentials.json`
6. Update `cloudflared/config.yml` with your tunnel ID and hostname

## First Login

On first start, Paperclip prints a **board claim URL** to the console:

```
/board-claim/<token>?code=<code>
```

Visit `https://YOUR_DOMAIN/board-claim/<token>?code=<code>` to claim admin ownership.

## Commands

| Command | What it does |
|---|---|
| `./setup.sh` | One-time: install paperclipai, create .env |
| `./start.sh` | Start DB + tunnel + Paperclip server (foreground, Ctrl+C to stop) |
| `./stop.sh` | Stop Docker infrastructure (DB + tunnel) |
| `make status` | Show running services |
| `make logs` | Tail Docker logs (DB + tunnel) |
| `make db-shell` | Open psql shell |
| `make update` | Update paperclipai to latest version |
| `make restart` | Stop + start |

## Running as a systemd Service

For production on a Linux server:

```bash
# Adjust paths in edgeclip.service if not at /root/edgeclip
sudo cp edgeclip.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now edgeclip

# View logs
journalctl -u edgeclip -f
tail -f paperclip.log
```
