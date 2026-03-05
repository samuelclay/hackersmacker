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

# Build extensions pointing at production server and package for store submission
prod: compile
	@cd client/chrome && zip -r ../chrome.zip . -x "*.DS_Store"
	@cd client/firefox && zip -r ../firefox.zip . -x "*.DS_Store"
	@echo ""
	@echo "Extensions built for production (www.hackersmacker.org)"
	@echo "  Chrome/Edge: client/chrome.zip"
	@echo "  Firefox:     client/firefox.zip"

compile-dev: compile
	@echo "window.HS_SERVER = 'localhost:3040';" > client/common/config.js
	@cp client/common/config.js client/chrome/config.js
	@cp client/common/config.js client/firefox/data/config.js
	@cp client/common/config.js client/safari/WebExtension/config.js
	@# Add localhost permissions for local development
	@sed -i '' 's|"https://www.hackersmacker.org/"|"https://www.hackersmacker.org/",\n    "http://localhost:3040/"|' client/chrome/manifest.json
	@sed -i '' 's|"https://www.hackersmacker.org/",|"https://www.hackersmacker.org/",\n    "http://localhost:3040/",|' client/firefox/manifest.json client/safari/WebExtension/manifest.json

compile:
	@coffee -c client/common/client.coffee
	@coffee -c client/common/background.coffee
	@echo "// Default: production (www.hackersmacker.org)" > client/common/config.js
	@cp client/common/client.js client/chrome/client.js
	@cp client/common/background.js client/chrome/background.js
	@cp client/common/client.css client/chrome/client.css
	@cp client/common/config.js client/chrome/config.js
	@cp client/common/client.js client/firefox/data/client.js
	@cp client/common/background.js client/firefox/data/background.js
	@cp client/common/client.css client/firefox/data/client.css
	@cp client/common/config.js client/firefox/data/config.js
	@cp client/common/client.js client/safari/WebExtension/client.js
	@cp client/common/background.js client/safari/WebExtension/background.js
	@cp client/common/client.css client/safari/WebExtension/client.css
	@cp client/common/config.js client/safari/WebExtension/config.js
	@# Strip localhost from manifests (safety net for production builds)
	@node -e "var fs=require('fs');process.argv.slice(1).forEach(function(f){var c=fs.readFileSync(f,'utf8');c=c.replace(/,\n\s*\"http:\/\/localhost:[^\"]*\"/g,'');c=c.replace(/\n\s*\"http:\/\/localhost:[^\"]*\",?/g,'');fs.writeFileSync(f,c)});" client/chrome/manifest.json client/firefox/manifest.json client/safari/WebExtension/manifest.json

ssh:
	ssh -i /srv/secrets-newsblur/keys/newsblur.key root@hackersmacker.org

tail:
	ssh -i /srv/secrets-newsblur/keys/newsblur.key root@hackersmacker.org "journalctl -u hackersmacker -f"

renew:
	sudo /etc/init.d/haproxy stop
	sudo letsencrypt renew
	DOMAIN='hackersmacker.org' sudo -E bash -c 'cat /etc/letsencrypt/live/$$DOMAIN/fullchain.pem /etc/letsencrypt/live/$$DOMAIN/privkey.pem > /etc/haproxy/certs/$$DOMAIN.pem'
	sudo /etc/init.d/haproxy start

.PHONY: all up down logs restart dev prod compile-dev compile ssh tail renew
