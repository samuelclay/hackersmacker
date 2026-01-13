# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hacker Smacker is a browser extension that adds friend/foe functionality to Hacker News. Users can mark commenters as friends (highlighted) or foes (filtered), and see friend-of-a-friend (FoaF) relationships from other users of the extension.

## Architecture

### Client-Server Model

**Server** (`server/`): Node.js/Express.js backend with Redis for relationship storage
- `server.coffee` - Express HTTP server on port 3040, serves `/load` and `/save` endpoints
- `graph.coffee` - Redis-based social graph operations using sets for relationship storage

**Client** (`client/`): Browser extensions that inject into news.ycombinator.com
- `common/` - Shared CoffeeScript/JS code used by all browser extensions
- `chrome/`, `firefox/`, `safari/` - Browser-specific extension packaging

### Data Model (Redis)

Relationships stored as Redis sets with key patterns:
- `G:{username}:F` - Users that {username} has friended
- `G:{username}:f` - Users that have friended {username}
- `G:{username}:X` - Users that {username} has foed
- `G:{username}:x` - Users that have foed {username}
- `T:{username}:onpage` - Temporary set for page intersection queries

### Client Flow

1. Extension injects into HN pages, finds current logged-in user
2. Collects all usernames visible on page
3. Calls `/load` endpoint with usernames to get friends/foes/foaf data
4. Decorates each username with rating orbs (friend/neutral/foe)
5. On rating click, calls `/save` endpoint and updates local graph

## Development Commands

### Server

```bash
cd server
coffee server.coffee    # Run server (requires Redis running)
```

The server requires:
- Node.js with CoffeeScript
- Redis (default localhost, or set REDIS_HOST env var)

### Client

CoffeeScript files in `client/common/` need to be compiled to JS:
```bash
coffee -c client/common/client.coffee
```

Chrome extension can be loaded unpacked from `client/chrome/` directory.

### SSL Certificate Renewal

```bash
make renew    # Renews Let's Encrypt certs for hackersmacker.org
```

## Key Files

- `client/common/client.coffee` - Main extension logic (HSGraph and HSRater classes)
- `server/graph.coffee` - Redis graph operations for FoaF queries
- `server/server.coffee` - Express API endpoints
