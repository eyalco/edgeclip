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
- A **Cloudflare account** with a domain and tunnel token
- **Claude Max plan** (or an Anthropic API key)

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/YOUR_USER/edgeclip.git
cd edgeclip

# 2. First run — installs paperclipai, creates .env template, then exits
./setup.sh

# 3. Edit .env with your values
nano .env

# 4. Second run — validates .env, installs + starts systemd service
./setup.sh
```

After setup, EdgeClip runs as a persistent systemd service that survives reboots. Migrations and onboarding run automatically with no prompts.

## .env Variables

| Variable | Required | How to get |
|---|---|---|
| `CLOUDFLARE_TUNNEL_TOKEN` | Yes | `cloudflared tunnel token <TUNNEL_NAME>` |
| `POSTGRES_PASSWORD` | Yes | `openssl rand -base64 24` |
| `PAPERCLIP_DOMAIN` | Yes | The public hostname you configured in the tunnel |
| `BETTER_AUTH_SECRET` | Yes | `openssl rand -base64 32` |
| `PAPERCLIP_SECRETS_MASTER_KEY` | Recommended | `openssl rand -base64 32` |
| `PAPERCLIP_AGENT_JWT_SECRET` | No | `openssl rand -base64 32` (falls back to `BETTER_AUTH_SECRET`) |
| `EDGECLIP_BIND_HOST` | No | `127.0.0.1` (default) or `0.0.0.0` for local dev with Docker Desktop |

## Cloudflare Tunnel Setup

1. Install `cloudflared` locally: `brew install cloudflared` or [download](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/)
2. Authenticate: `cloudflared tunnel login`
3. Create tunnel: `cloudflared tunnel create edgeclip`
4. Route DNS: `cloudflared tunnel route dns edgeclip edgeclip.yourdomain.com`
5. Get the token: `cloudflared tunnel token edgeclip` -- set as `CLOUDFLARE_TUNNEL_TOKEN` in `.env`

Ingress rules are managed remotely in the Cloudflare dashboard (Zero Trust > Networks > Tunnels).

## First Login

On first start, Paperclip prints a **board claim URL** to the log:

```
/board-claim/<token>?code=<code>
```

Find it with `tail -f paperclip.log` or `journalctl -u edgeclip`, then visit `https://YOUR_DOMAIN/board-claim/<token>?code=<code>` to claim admin ownership.

## Service Management

| Command | What it does |
|---|---|
| `sudo systemctl status edgeclip` | Check service status |
| `sudo systemctl stop edgeclip` | Stop EdgeClip |
| `sudo systemctl start edgeclip` | Start EdgeClip |
| `sudo systemctl restart edgeclip` | Restart EdgeClip |
| `journalctl -u edgeclip -f` | Tail service logs |
| `tail -f paperclip.log` | Tail Paperclip application logs |

## Other Commands

| Command | What it does |
|---|---|
| `./start.sh` | Run in foreground (dev/debug, Ctrl+C to stop) |
| `./stop.sh` | Stop Docker infrastructure (DB + tunnel) |
| `make db-shell` | Open psql shell |
| `make update` | Update paperclipai to latest version |
