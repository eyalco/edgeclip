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
	@docker compose ps
	@echo ""
	@if [ -f .paperclip.pid ] && kill -0 $$(cat .paperclip.pid) 2>/dev/null; then \
		echo "Paperclip server: running (PID $$(cat .paperclip.pid))"; \
	else \
		echo "Paperclip server: not running"; \
	fi

update:
	npm update -g paperclipai
	@echo "Updated. Restart with: make restart"
