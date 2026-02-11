crypto = require 'crypto'
https  = require 'https'
redis  = require 'redis'
client = redis.createClient null, process.env.REDIS_HOST || null

MIN_CHECK_INTERVAL = 3   # seconds between HN scrapes
BASE62_CHARS       = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
USERNAME_RE        = /^[a-zA-Z0-9_-]+$/

module.exports =

    generateVerificationToken: (username) ->
        bytes = crypto.randomBytes(18)
        code = ''
        code += BASE62_CHARS[b % 62] for b in bytes
        "https://www.hackersmacker.org/user/#{username}?hs=#{code}"

    generateAuthToken: (callback) ->
        crypto.randomBytes 32, (err, buf) ->
            callback buf.toString('hex')

    validateUsername: (username) ->
        username and typeof username is 'string' and USERNAME_RE.test(username)

    startVerification: (username, callback) ->
        return callback(error: 'Invalid username', code: -1) unless @validateUsername(username)

        pendingKey = "V:#{username}:pending"
        authKey    = "V:#{username}:auth_token"

        # Check if already verified — return auth token so extension can recover
        client.get authKey, (err, existingToken) =>
            if existingToken
                return callback
                    code: 2
                    status: 'already_verified'
                    auth_token: existingToken

            # Return existing token or generate one — token is stable per user
            client.hgetall pendingKey, (err, pending) =>
                if pending and pending.token
                    return callback
                        code: 1
                        username: username
                        verification_token: pending.token

                # Generate new verification (first time only)
                token = @generateVerificationToken(username)
                now = new Date().toISOString()
                client.hmset pendingKey,
                    'token', token
                    'created_at', now
                    'last_attempt', ''
                # No TTL — token lives until verified

                callback
                    code: 1
                    username: username
                    verification_token: token

    checkVerification: (username, callback) ->
        return callback(error: 'Invalid username', code: -1) unless @validateUsername(username)

        pendingKey = "V:#{username}:pending"

        client.hgetall pendingKey, (err, pending) =>
            if not pending or not pending.token
                return callback
                    code: -2
                    status: 'no_pending'
                    message: 'No verification in progress. Please start verification first.'

            # Light rate limit — just prevent hammering HN
            now = Date.now()
            if pending.last_attempt
                elapsed = (now - new Date(pending.last_attempt).getTime()) / 1000
                if elapsed < MIN_CHECK_INTERVAL
                    remaining = Math.ceil(MIN_CHECK_INTERVAL - elapsed)
                    return callback
                        code: -1
                        status: 'rate_limited'
                        retry_after: remaining

            client.hset pendingKey, 'last_attempt', new Date().toISOString()

            # Scrape HN profile
            @scrapeHNProfile username, (err, foundToken) =>
                if err
                    return callback
                        code: 0
                        status: 'error'
                        message: 'Could not reach Hacker News. Try again shortly.'

                if foundToken and foundToken is pending.token
                    # Verification succeeded
                    @generateAuthToken (authToken) ->
                        client.set "V:#{username}:auth_token", authToken
                        client.set "V:#{username}:verified_at", new Date().toISOString()
                        client.del pendingKey
                        callback
                            code: 1
                            status: 'verified'
                            auth_token: authToken
                else
                    callback
                        code: 0
                        status: 'pending'
                        message: 'Token not found in your HN profile yet.'

    checkStatus: (username, authToken, callback) ->
        return callback(code: 0, status: 'unverified') unless @validateUsername(username)
        return callback(code: 0, status: 'unverified') unless authToken

        @validateAuthToken username, authToken, (valid) ->
            if valid
                client.get "V:#{username}:verified_at", (err, verifiedAt) ->
                    callback
                        code: 1
                        status: 'verified'
                        verified_at: verifiedAt
            else
                callback code: 0, status: 'unverified'

    validateAuthToken: (username, providedToken, callback) ->
        key = "V:#{username}:auth_token"
        client.get key, (err, storedToken) ->
            return callback(false) if err or not storedToken or not providedToken
            if providedToken.length isnt storedToken.length
                return callback(false)
            try
                valid = crypto.timingSafeEqual(
                    Buffer.from(providedToken, 'utf8'),
                    Buffer.from(storedToken, 'utf8')
                )
                callback(valid)
            catch
                callback(false)

    debugAuthToken: (username, providedToken, callback) ->
        key = "V:#{username}:auth_token"
        client.get key, (err, storedToken) ->
            if err
                return callback "Redis error: #{err.message}"
            if not storedToken
                return callback "No stored token in Redis (key #{key} missing — likely Redis restart)"
            if not providedToken
                return callback "Client sent empty token"
            if providedToken.length isnt storedToken.length
                return callback "Token length mismatch: client=#{providedToken.length} server=#{storedToken.length}, client_prefix=#{providedToken.substring(0, 8)}..."
            return callback "Token mismatch: client_prefix=#{providedToken.substring(0, 8)}... stored_prefix=#{storedToken.substring(0, 8)}..."

    scrapeHNProfile: (username, callback) ->
        options =
            hostname: 'news.ycombinator.com'
            path: "/user?id=#{encodeURIComponent(username)}"
            headers:
                'User-Agent': 'HackerSmacker/1.0 (https://www.hackersmacker.org)'
            timeout: 10000

        req = https.get options, (res) ->
            body = ''
            res.on 'data', (chunk) -> body += chunk
            res.on 'end', ->
                aboutMatch = body.match(/about:<\/td><td[^>]*>([\s\S]*?)<\/td>/i)
                if aboutMatch
                    aboutContent = aboutMatch[1]
                    # HN encodes / as &#x2F;
                    normalized = aboutContent.replace(/&#x2F;/g, '/').replace(/&amp;/g, '&')
                    tokenMatch = normalized.match(/hackersmacker\.org\/user\/([a-zA-Z0-9_-]+)\?hs=([a-zA-Z0-9]{18})/)
                    if tokenMatch
                        fullToken = "https://www.hackersmacker.org/user/#{tokenMatch[1]}?hs=#{tokenMatch[2]}"
                        callback null, fullToken
                    else
                        callback null, null
                else
                    callback null, null

        req.on 'error', (err) -> callback(err, null)
        req.on 'timeout', ->
            req.destroy()
            callback(new Error('Request timed out'), null)
