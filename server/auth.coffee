crypto = require 'crypto'
https  = require 'https'
redis  = require 'redis'
client = redis.createClient null, process.env.REDIS_HOST || null

VERIFICATION_TTL = 3600
MAX_BACKOFF      = 120
BASE_DELAY       = 5
BASE62_CHARS     = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
USERNAME_RE      = /^[a-zA-Z0-9_-]+$/

module.exports =

    generateVerificationToken: ->
        bytes = crypto.randomBytes(18)
        token = ''
        token += BASE62_CHARS[b % 62] for b in bytes
        "HS:#{token}"

    generateAuthToken: (callback) ->
        crypto.randomBytes 32, (err, buf) ->
            callback buf.toString('hex')

    validateUsername: (username) ->
        username and typeof username is 'string' and USERNAME_RE.test(username)

    startVerification: (username, callback) ->
        return callback(error: 'Invalid username', code: -1) unless @validateUsername(username)

        pendingKey = "V:#{username}:pending"
        authKey    = "V:#{username}:auth_token"

        # Check if already verified
        client.get authKey, (err, existingToken) =>
            if existingToken
                return callback
                    code: 2
                    status: 'already_verified'
                    message: 'Already verified. Start again to re-verify.'

            # Check for existing pending verification (idempotent)
            client.hgetall pendingKey, (err, pending) =>
                if pending and pending.token
                    return callback
                        code: 1
                        username: username
                        verification_token: pending.token
                        instructions: "Add this token to your Hacker News profile's 'about' section."
                        expires_in: VERIFICATION_TTL

                # Generate new verification
                token = @generateVerificationToken()
                now = new Date().toISOString()
                client.hmset pendingKey,
                    'token', token
                    'created_at', now
                    'attempts', '0'
                    'last_attempt', ''
                client.expire pendingKey, VERIFICATION_TTL

                callback
                    code: 1
                    username: username
                    verification_token: token
                    instructions: "Add this token to your Hacker News profile's 'about' section."
                    expires_in: VERIFICATION_TTL

    checkVerification: (username, callback) ->
        return callback(error: 'Invalid username', code: -1) unless @validateUsername(username)

        pendingKey = "V:#{username}:pending"

        client.hgetall pendingKey, (err, pending) =>
            if not pending or not pending.token
                return callback
                    code: -2
                    status: 'expired'
                    message: 'Verification request has expired. Please start again.'

            attempts = parseInt(pending.attempts, 10) or 0
            lastAttempt = pending.last_attempt
            now = Date.now()
            delay = @calculateBackoff(attempts)

            # Enforce backoff
            if lastAttempt
                elapsed = (now - new Date(lastAttempt).getTime()) / 1000
                if elapsed < delay
                    remaining = Math.ceil(delay - elapsed)
                    return callback
                        code: -1
                        status: 'rate_limited'
                        message: 'Please wait before checking again.'
                        retry_after: remaining

            # Update attempt count
            client.hincrby pendingKey, 'attempts', 1
            client.hset pendingKey, 'last_attempt', new Date().toISOString()

            # Scrape HN profile
            @scrapeHNProfile username, (err, foundToken) =>
                if err
                    return callback
                        code: 0
                        status: 'error'
                        message: 'Could not reach Hacker News. Try again shortly.'
                        retry_after: delay

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
                    nextDelay = @calculateBackoff(attempts + 1)
                    callback
                        code: 0
                        status: 'pending'
                        message: "Token not found in profile. Next check in #{nextDelay}s."
                        retry_after: nextDelay

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
            # Ensure same length for timingSafeEqual
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

    scrapeHNProfile: (username, callback) ->
        url = "https://news.ycombinator.com/user?id=#{encodeURIComponent(username)}"
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
                # HN profile: about field is in a <td> after the "about:" label
                aboutMatch = body.match(/about:<\/td><td>([\s\S]*?)<\/td>/i)
                if aboutMatch
                    aboutContent = aboutMatch[1]
                    tokenMatch = aboutContent.match(/HS:[a-zA-Z0-9]{24}/)
                    callback null, tokenMatch?[0] or null
                else
                    callback null, null

        req.on 'error', (err) -> callback(err, null)
        req.on 'timeout', ->
            req.destroy()
            callback(new Error('Request timed out'), null)

    calculateBackoff: (attempts) ->
        Math.min(BASE_DELAY * Math.pow(2, attempts), MAX_BACKOFF)
