.PHONY: setup start stop restart logs db-shell status update

setup:
	./setup.sh

start:
	./start.sh

stop:
	./stop.sh

restart: stop start

logs:
	docker compose logs -f

db-shell:
	docker compose exec db psql -U paperclip paperclip

status:
	@echo "── Docker ──"
	@docker compose ps
	@echo ""
	@echo "── Paperclip process ──"
	@ps aux | grep 'server/dist/index.js' | grep -v grep || echo "Not running"

update:
	cd paperclip && git pull --ff-only
	cd paperclip && pnpm install --frozen-lockfile
	cd paperclip && pnpm --filter @paperclipai/shared build 2>/dev/null || true
	cd paperclip && pnpm --filter @paperclipai/db build 2>/dev/null || true
	cd paperclip && pnpm --filter @paperclipai/adapter-utils build 2>/dev/null || true
	cd paperclip && pnpm --filter @paperclipai/plugin-sdk build
	cd paperclip && pnpm --filter @paperclipai/ui build
	cd paperclip && pnpm --filter @paperclipai/server build
	@echo "Updated. Restart with: make restart"
