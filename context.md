# EdgeClip — Context

Turnkey deployment project for Paperclip agent orchestration with PostgreSQL and
Cloudflare Tunnel. Designed for a Linux VPS where Claude Code runs on the host.

## Architecture

- **Host**: Paperclip Node.js server + Claude Code CLI (Max plan)
- **Docker**: PostgreSQL 17 (data) + Cloudflared (ingress tunnel)
- No ports exposed to the internet; all traffic via Cloudflare Tunnel

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | Defines PostgreSQL and Cloudflared Docker services |
| `.env.example` | Template for environment variables (passwords, tokens, domain) |
| `setup.sh` | One-time setup: clones Paperclip, installs deps, builds, creates `.env` |
| `start.sh` | Starts Docker infra + Paperclip server in foreground |
| `start-service.sh` | Headless Paperclip startup for systemd (skips docker compose) |
| `stop.sh` | Stops Docker services |
| `edgeclip.service` | Systemd unit file for boot-persistent production deployment |
| `Makefile` | Convenience targets: setup, start, stop, restart, logs, update, etc. |
| `.gitignore` | Excludes `.env`, `data/`, `paperclip/` (cloned at setup time) |
| `README.md` | Full setup and usage instructions |
| `context.md` | This file — project overview and file index |

## Subfolders (created at runtime)

| Folder | Purpose |
|---|---|
| `paperclip/` | Cloned Paperclip repo (gitignored, created by `setup.sh`) |
| `data/paperclip/` | Paperclip runtime data — secrets, sessions, config (gitignored) |
