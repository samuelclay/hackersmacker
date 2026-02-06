FROM node:18-alpine

RUN npm install -g coffeescript

WORKDIR /app

# Copy server code (node_modules are committed to the repo)
COPY server/ ./server/
COPY web/ ./web/

# Compile CoffeeScript
RUN coffee -c server/server.coffee server/graph.coffee server/auth.coffee

EXPOSE 3040

CMD ["node", "server/server.js"]
