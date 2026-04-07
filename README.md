# EdgeClip

Turnkey deployment of [Paperclip](https://github.com/paperclipai/paperclip) agent orchestration with PostgreSQL and Cloudflare Tunnel.

## Architecture

```
Internet
  │
  ▼
Cloudflare Tunnel (Docker) ──► https://paperclip.yourdomain.com
  │
  ▼
Paperclip Server (host, port 3100)
  ├── Claude Code CLI (host, Max plan)
  └── PostgreSQL 17 (Docker, port 5432 localhost-only)
```

- **Paperclip + Claude Code** run on the host for native filesystem and git access
- **PostgreSQL** runs in Docker for clean data isolation
- **Cloudflare Tunnel** runs in Docker, proxies your domain to localhost:3100
- No ports exposed to the internet — all traffic goes through the tunnel

## Prerequisites

- Linux VPS with Docker and Docker Compose
- Node.js 20+ and pnpm 9+
- A Cloudflare account with a domain
- Claude Max plan (or an Anthropic API key)

## Quick Start

```bash
# 1. Clone this repo on your VPS
git clone https://github.com/YOUR_USER/edgeclip.git
cd edgeclip

# 2. Run setup (clones Paperclip, installs deps, builds)
chmod +x setup.sh start.sh stop.sh start-service.sh
./setup.sh

# 3. Edit .env with your values
nano .env

# 4. Start everything
./start.sh
```

## .env Variables

| Variable | Required | How to get |
|---|---|---|
| `POSTGRES_PASSWORD` | Yes | `openssl rand -base64 24` |
| `CLOUDFLARE_TUNNEL_TOKEN` | Yes | Zero Trust → Networks → Tunnels → Create |
| `PAPERCLIP_DOMAIN` | Yes | The public hostname you configured in the tunnel |
| `BETTER_AUTH_SECRET` | Yes | `openssl rand -base64 32` |
| `PAPERCLIP_SECRETS_MASTER_KEY` | Recommended | `openssl rand -base64 32` |
| `CLAUDE_CODE_OAUTH_TOKEN` | For Max plan | `claude setup-token` (on a machine with a browser) |

## Cloudflare Tunnel Setup

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) → Networks → Tunnels
2. Create a tunnel, name it (e.g. `edgeclip`)
3. Copy the tunnel token into `.env` as `CLOUDFLARE_TUNNEL_TOKEN`
4. Add a public hostname:
   - **Subdomain:** `paperclip` (or your choice)
   - **Domain:** your domain
   - **Service:** `http://localhost:3100`

Optional: add a Cloudflare Access policy for an extra authentication layer.

## First Login

On first start, Paperclip prints a **board claim URL** to the console:

```
/board-claim/<token>?code=<code>
```

Visit `https://YOUR_DOMAIN/board-claim/<token>?code=<code>` to claim admin ownership.

## Commands

| Command | What it does |
|---|---|
| `./setup.sh` | One-time: clone, install, build, create .env |
| `./start.sh` | Start Docker infra + Paperclip (foreground) |
| `./stop.sh` | Stop Docker infra |
| `make status` | Show running services |
| `make logs` | Tail Docker logs |
| `make db-shell` | Open psql shell |
| `make update` | Pull latest Paperclip + rebuild |
| `make restart` | Stop + start |

## Running as a systemd Service

For production, install the systemd unit so EdgeClip starts on boot:

```bash
# Adjust paths in edgeclip.service if not at /root/edgeclip
sudo cp edgeclip.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now edgeclip

# View logs
journalctl -u edgeclip -f
```

## Adding Remote Agents (Server 1, etc.)

Paperclip runs as the control plane on this VPS. To run Claude Code on additional
servers, use the **HTTP adapter**:

1. Set up a webhook listener on the remote server
2. Create an agent in Paperclip with `adapterType: "http"` pointing at the remote endpoint
3. The remote agent calls back to `https://YOUR_DOMAIN/api/...` to report results

All agents appear in one dashboard regardless of where they execute.
