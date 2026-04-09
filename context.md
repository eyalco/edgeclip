# EdgeClip — Context

Host-based deployment of Paperclip agent orchestration with Docker infrastructure
(PostgreSQL + Cloudflare Tunnel). Paperclip and Claude Code run natively on the
host for direct filesystem and Docker access.

## Architecture

- **Paperclip server**: Runs on the host via the `paperclipai` npm package (`paperclipai run`)
- **Claude Code CLI**: Runs on the host with full system access (filesystem, Docker, etc.)
- **PostgreSQL 17**: Docker container, exposed on localhost:5432
- **Cloudflared**: Docker container (host network), token-based auth, ingress managed remotely in Cloudflare dashboard
- Paperclip binds to `127.0.0.1` by default (loopback only); set `EDGECLIP_BIND_HOST=0.0.0.0` for local dev with Docker Desktop
- No ports exposed to the internet; all traffic via Cloudflare Tunnel

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | Defines infrastructure services: db (PostgreSQL) and cloudflared |
| `.env.example` | Template for environment variables (passwords, domain, secrets) |
| `setup.sh` | One-time setup: installs paperclipai globally, creates `.env` |
| `start.sh` | Starts Docker infra + Paperclip server on host (foreground) |
| `stop.sh` | Stops Docker infrastructure |
| `start-service.sh` | Headless startup for systemd (Paperclip as background process) |
| `edgeclip.service` | Systemd unit file for boot-persistent production deployment |
| `Makefile` | Convenience targets: setup, start, stop, restart, logs, update, etc. |
| `.gitignore` | Excludes `.env`, `data/`, logs, PID file |
| `README.md` | Full setup and usage instructions |
| `context.md` | This file — project overview and file index |

## Subfolders

None — all configuration is via `.env` and the Cloudflare dashboard.
