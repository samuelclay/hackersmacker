all: up dev

up:
	docker compose up --build -d
	@echo ""
	@echo "Hacker Smacker running at http://localhost:3040"
	@echo "  Logs: docker compose logs -f"
	@echo "  Stop: make down"

down:
	docker compose down

logs:
	docker compose logs -f

restart:
	docker compose restart app

# Build extensions pointing at localhost:3040 for local testing
dev: compile-dev
	@echo ""
	@echo "Extensions built for local development (localhost:3040)"
	@echo "  Chrome: Load unpacked from client/chrome/"
	@echo "  Firefox: Load temporary add-on from client/firefox/manifest.json"

# Build extensions pointing at production server
prod: compile-prod
	@echo ""
	@echo "Extensions built for production (www.hackersmacker.org)"

compile-dev:
	@sed "s|window.HS_SERVER = 'www.hackersmacker.org'|window.HS_SERVER = 'localhost:3040'|" \
		client/common/client.coffee > client/common/client.dev.coffee
	@coffee -c client/common/client.dev.coffee
	@mv client/common/client.dev.js client/common/client.js
	@rm client/common/client.dev.coffee
	@coffee -c client/common/background.coffee
	@cp client/common/client.js client/chrome/client.js
	@cp client/common/background.js client/chrome/background.js
	@cp client/common/client.js client/firefox/data/client.js
	@cp client/common/background.js client/firefox/data/background.js
	@cp client/common/client.js client/safari/WebExtension/client.js
	@cp client/common/background.js client/safari/WebExtension/background.js

compile-prod:
	@coffee -c client/common/client.coffee
	@coffee -c client/common/background.coffee
	@cp client/common/client.js client/chrome/client.js
	@cp client/common/background.js client/chrome/background.js
	@cp client/common/client.js client/firefox/data/client.js
	@cp client/common/background.js client/firefox/data/background.js
	@cp client/common/client.js client/safari/WebExtension/client.js
	@cp client/common/background.js client/safari/WebExtension/background.js

renew:
	sudo /etc/init.d/haproxy stop
	sudo letsencrypt renew
	DOMAIN='hackersmacker.org' sudo -E bash -c 'cat /etc/letsencrypt/live/$$DOMAIN/fullchain.pem /etc/letsencrypt/live/$$DOMAIN/privkey.pem > /etc/haproxy/certs/$$DOMAIN.pem'
	sudo /etc/init.d/haproxy start

.PHONY: all up down logs restart dev prod compile-dev compile-prod renew
