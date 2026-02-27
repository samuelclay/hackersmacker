express = require 'express'
fs = require 'fs'
graph = require './graph'
auth = require './auth'

app = express.createServer()

# Reject multipart/form-data before bodyParser to avoid Buffer.write crash
# in old formidable (Node 7+ removed the 4-arg Buffer.write API)
app.use (req, res, next) ->
    contentType = req.headers['content-type'] or ''
    if contentType.indexOf('multipart/form-data') isnt -1
        res.contentType 'json'
        res.send JSON.stringify({ code: -1, message: 'Unsupported content type' }), 400
        return
    next()

app.use express.bodyParser()

# CORS middleware for all requests
app.use (req, res, next) ->
    res.header 'Access-Control-Allow-Origin', '*'
    res.header 'Access-Control-Allow-Methods', 'GET, POST, OPTIONS'
    res.header 'Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, X-HS-Auth'
    if req.method == 'OPTIONS'
        res.send 200
    else
        next()

# Auth middleware (enforces on /save)
requireAuth = (req, res, next) ->
    username = req.query.me or req.body?.me
    authToken = req.query.auth_token or req.body?.auth_token or req.headers['x-hs-auth']
    if not username or not authToken
        console.log " ---> [AUTH FAIL] Missing credentials for #{username or '(no user)'} on #{req.method} #{req.url} from #{req.headers.referer or '(no referer)'}"
        res.contentType 'json'
        res.send JSON.stringify({ code: -1, message: 'Authentication required. Please verify your identity.' }), 401
        return
    auth.validateAuthToken username, authToken, (valid) ->
        if valid
            next()
        else
            auth.debugAuthToken username, authToken, (info) ->
                console.log " ---> [AUTH FAIL] Invalid token for #{username}: #{info}"
            res.contentType 'json'
            res.send JSON.stringify({ code: -1, message: 'Invalid authentication. Please re-verify.' }), 401

# HTML escape helper
escapeHtml = (str) ->
    return '' unless str
    String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;')

# Time ago helper
timeAgo = (timestamp) ->
    return '' unless timestamp
    seconds = Math.floor(Date.now() / 1000) - parseInt(timestamp)
    if seconds < 60 then return 'just now'
    minutes = Math.floor(seconds / 60)
    if minutes < 60 then return "#{minutes}m ago"
    hours = Math.floor(minutes / 60)
    if hours < 24 then return "#{hours}h ago"
    days = Math.floor(hours / 24)
    if days < 30 then return "#{days}d ago"
    months = Math.floor(days / 30)
    if months < 12 then return "#{months}mo ago"
    years = Math.floor(days / 365)
    "#{years}y ago"

# ============================================================
# Extension API endpoints
# ============================================================

app.get '/load', (req, res) ->
    originalUsername = req.query.me
    usernames = req.query.u or []
    graph.findRelationships originalUsername, usernames, (m) ->
        console.log " ---> [#{originalUsername}] Load #{req.headers.referer or ''}:" +
                    " #{usernames.length} users -" +
                    " #{m.friends.length} friends, #{m.foes.length} foes," +
                    " #{m.foaf_friends.length}/#{m.foaf_foes.length} foaf"
        res.contentType 'json'
        res.send "#{JSON.stringify(m)}"

# Legacy GET /save (no context, auth required)
app.get '/save', requireAuth, (req, res) ->
    username = req.query.username
    relationship = req.query.relationship
    originalUsername = req.query.me
    graph.saveRelationship originalUsername, relationship, username
    response = code: 1, message: "OK"
    res.send "#{JSON.stringify(response)}"

# New POST /save with rating context (auth required)
app.post '/save', requireAuth, (req, res) ->
    username = req.body.username
    relationship = req.body.relationship
    originalUsername = req.body.me
    context =
        comment_text: req.body.comment_text or ''
        comment_url: req.body.comment_url or ''
        thread_title: req.body.thread_title or ''
        thread_url: req.body.thread_url or ''
        parent_author: req.body.parent_author or ''
    graph.saveRelationship originalUsername, relationship, username
    graph.saveRatingContext originalUsername, relationship, username, context
    console.log " ---> [#{originalUsername}] Save #{username} as #{relationship} (with context)"
    res.contentType 'json'
    res.send JSON.stringify({ code: 1, message: "OK" })

# ============================================================
# Verification endpoints
# ============================================================

app.get '/verify/start', (req, res) ->
    username = req.query.me
    auth.startVerification username, (result) ->
        res.contentType 'json'
        res.send JSON.stringify(result)

app.get '/verify/check', (req, res) ->
    username = req.query.me
    auth.checkVerification username, (result) ->
        res.contentType 'json'
        res.send JSON.stringify(result)

app.get '/verify/status', (req, res) ->
    username = req.query.me
    authToken = req.query.auth_token or req.body?.auth_token or req.headers['x-hs-auth']
    auth.checkStatus username, authToken, (result) ->
        res.contentType 'json'
        res.send JSON.stringify(result)

# ============================================================
# Profile endpoints
# ============================================================

app.get '/user/:username', (req, res) ->
    username = req.params.username
    return res.send('Invalid username', 400) unless auth.validateUsername(username)
    authToken = req.query.token

    graph.getProfile username, (profile) ->
        isPublic = profile.settings?.profile_public isnt '0'

        if authToken
            auth.validateAuthToken username, authToken, (isOwner) ->
                res.send profilePageHTML(username, profile, isPublic, isOwner, authToken)
        else
            res.send profilePageHTML(username, profile, isPublic, false, null)

app.get '/api/profile/:username', (req, res) ->
    username = req.params.username
    return res.send(JSON.stringify({ error: 'Invalid username' }), 400) unless auth.validateUsername(username)
    authToken = req.query.token or req.query.auth_token or req.headers['x-hs-auth']

    graph.getProfile username, (profile) ->
        isPublic = profile.settings?.profile_public isnt '0'

        checkOwner = (cb) ->
            if authToken
                auth.validateAuthToken username, authToken, cb
            else
                cb false

        checkOwner (isOwner) ->
            if not isPublic and not isOwner
                res.contentType 'json'
                return res.send JSON.stringify({ error: 'Profile is private', code: 0 })
            res.contentType 'json'
            res.send JSON.stringify(profile)

app.get '/user/:username/settings', (req, res) ->
    username = req.params.username
    return res.send(JSON.stringify({ error: 'Invalid username' }), 400) unless auth.validateUsername(username)
    authToken = req.query.token or req.query.auth_token or req.headers['x-hs-auth']
    isPublic = req.query.public

    return res.send(JSON.stringify({ error: 'Auth required' }), 401) unless authToken

    auth.validateAuthToken username, authToken, (valid) ->
        if not valid
            res.contentType 'json'
            return res.send JSON.stringify({ error: 'Invalid token', code: 0 }), 401
        graph.setProfileVisibility username, (isPublic isnt '0'), ->
            res.contentType 'json'
            res.send JSON.stringify({ code: 1, message: 'OK' })

# ============================================================
# Profile page HTML renderer
# ============================================================

profilePageHTML = (username, profile, isPublic, isOwner, authToken) ->
    eUser = escapeHtml(username)

    # Build rating cards HTML
    renderCard = (item, type) ->
        eName = escapeHtml(item.name)
        ctx = item.context or {}
        eComment = escapeHtml(ctx.comment_text)
        eThreadTitle = escapeHtml(ctx.thread_title)
        eCommentUrl = escapeHtml(ctx.comment_url)
        eThreadUrl = escapeHtml(ctx.thread_url)
        time = if item.timestamp then timeAgo(item.timestamp) else ''

        contextHtml = ''
        if eComment or eThreadTitle
            threadLine = ''
            if eThreadTitle and eThreadUrl
                threadLine = """<div class="HS-rating-thread">in: <a href="#{eThreadUrl}">#{eThreadTitle}</a></div>"""
            else if eThreadUrl
                threadLine = """<div class="HS-rating-thread"><a href="#{eThreadUrl}">view thread</a></div>"""

            commentLine = ''
            if eComment
                commentLine = """<blockquote class="HS-rating-comment">#{eComment}</blockquote>"""

            permalinkLine = ''
            if eCommentUrl
                permalinkLine = """<a href="#{eCommentUrl}" class="HS-rating-permalink">view on HN &rarr;</a>"""

            contextHtml = """
                <div class="HS-rating-context">
                    #{threadLine}
                    #{commentLine}
                    #{permalinkLine}
                </div>"""

        noContextClass = if not eComment and not eThreadTitle then ' HS-no-context' else ''

        """
        <div class="HS-rating-card HS-rating-#{type}#{noContextClass}">
            <div class="HS-rating-card-header">
                <span class="HS-rating-orb HS-orb-#{type}"></span>
                <a href="https://news.ycombinator.com/user?id=#{eName}" class="HS-rated-user">#{eName}</a>
                #{if item.hasProfile then '<a href="/user/' + eName + '" class="HS-profile-link">[profile]</a>' else ''}
                <span class="HS-rating-time">#{time}</span>
            </div>#{contextHtml}
        </div>"""

    # Main content depends on visibility
    mainContent = ''
    if not isPublic and not isOwner
        mainContent = """
        <div class="HS-private-message">
            <h3>#{eUser}'s profile is private</h3>
            <p>This user has chosen to keep their friends and foes list private.</p>
        </div>"""
    else
        friendCards = ''
        friendCards += renderCard(f, 'friend') for f in (profile.friends or [])
        if profile.friends?.length is 0
            friendCards = '<p class="HS-empty">No friends yet.</p>'

        foeCards = ''
        foeCards += renderCard(f, 'foe') for f in (profile.foes or [])
        if profile.foes?.length is 0
            foeCards = '<p class="HS-empty">No foes yet.</p>'

        mainContent = """
        <div class="HS-profile-section">
            <h3 class="HS-section-title HS-friends-title">
                Friends <span class="HS-count">(#{profile.friends?.length or 0})</span>
            </h3>
            <div class="HS-rating-list">#{friendCards}</div>
        </div>
        <div class="HS-profile-section">
            <h3 class="HS-section-title HS-foes-title">
                Foes <span class="HS-count">(#{profile.foes?.length or 0})</span>
            </h3>
            <div class="HS-rating-list">#{foeCards}</div>
        </div>"""

    # Owner controls
    ownerControls = ''
    if isOwner
        checkedAttr = if isPublic then 'checked' else ''
        ownerControls = """
        <div class="HS-profile-controls">
            <label class="HS-toggle-label">
                <input type="checkbox" id="HS-visibility-toggle" #{checkedAttr}>
                <span>Profile is public</span>
            </label>
        </div>"""

    # Settings script (only for owner)
    settingsScript = ''
    if isOwner
        settingsScript = """
    <script>
    document.getElementById('HS-visibility-toggle').addEventListener('change', function() {
        var isPublic = this.checked ? '1' : '0';
        var xhr = new XMLHttpRequest();
        xhr.open('GET', '/user/#{eUser}/settings?token=#{escapeHtml(authToken)}&public=' + isPublic);
        xhr.send();
        var label = this.parentNode.querySelector('span');
        label.textContent = this.checked ? 'Profile is public' : 'Profile is private';
    });
    </script>"""

    """<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#{eUser} - Hacker Smacker</title>
    <link rel="icon" type="image/png" href="/favicon.png">
    <link rel="stylesheet" href="/profile.css">
</head>
<body>
    <header class="HS-top">
        <a href="/"><img src="/images/hackersmacker_logo.png" alt="Hacker Smacker" class="HS-logo"></a>
        <p class="HS-tagline">Friend/foe individual writers on Hacker News</p>
    </header>

    <div class="HS-profile">
        <div class="HS-profile-header">
            <h2>#{eUser}</h2>
            <p class="HS-profile-meta">
                <a href="https://news.ycombinator.com/user?id=#{eUser}">#{eUser} on Hacker News</a>
            </p>
            #{ownerControls}
        </div>
        #{mainContent}
    </div>

    <div class="HS-footer">
        <p><a href="/">Hacker Smacker</a> &mdash; Friend and foe writers on Hacker News</p>
    </div>

    <div id="doodle-field" class="HS-doodle-field"></div>
    #{settingsScript}
    <script>
    (function() {
        var field = document.getElementById('doodle-field');
        if (!field) return;
        var icons = [
            'icon-chair.png', 'icon-duck.png', 'icon-bottles.png',
            'icon-harmonica.png', 'icon-globe.png', 'icon-shoes.png',
            'icon-oranges.png', 'icon-peppers.png'
        ];
        for (var s = icons.length - 1; s > 0; s--) {
            var j = Math.floor(Math.random() * (s + 1));
            var tmp = icons[s]; icons[s] = icons[j]; icons[j] = tmp;
        }
        var sprites = [];
        var count = window.innerWidth < 640 ? 6 : 12;
        for (var i = 0; i < count; i++) {
            var img = document.createElement('img');
            img.src = '/images/' + icons[i % icons.length];
            img.className = 'HS-doodle-sprite';
            img.alt = '';
            field.appendChild(img);
            var sprite = {
                el: img,
                x: Math.random() * window.innerWidth,
                y: Math.random() * window.innerHeight,
                vx: (Math.random() - 0.5) * 0.25,
                vy: (Math.random() - 0.5) * 0.15,
                rot: Math.random() * 360,
                vrot: (Math.random() - 0.5) * 0.3,
                wobblePhase: Math.random() * Math.PI * 2,
                wobbleSpeed: 0.004 + Math.random() * 0.007,
                wobbleAmp: 10 + Math.random() * 20,
                opacity: 0.12 + Math.random() * 0.18,
                scale: 0.7 + Math.random() * 0.7
            };
            sprites.push(sprite);
            var px = 32 * sprite.scale;
            img.style.opacity = sprite.opacity;
            img.style.width = px + 'px';
            img.style.height = px + 'px';
        }
        var w, h;
        function updateSize() { w = window.innerWidth; h = window.innerHeight; }
        updateSize();
        window.addEventListener('resize', updateSize);
        function tick() {
            for (var i = 0; i < sprites.length; i++) {
                var sp = sprites[i];
                sp.wobblePhase += sp.wobbleSpeed;
                var wobbleX = Math.sin(sp.wobblePhase) * sp.wobbleAmp;
                var wobbleY = Math.cos(sp.wobblePhase * 0.7) * sp.wobbleAmp * 0.6;
                sp.x += sp.vx; sp.y += sp.vy; sp.rot += sp.vrot;
                if (sp.x < -80) sp.x = w + 40;
                if (sp.x > w + 80) sp.x = -40;
                if (sp.y < -80) sp.y = h + 40;
                if (sp.y > h + 80) sp.y = -40;
                var drawX = sp.x + wobbleX;
                var drawY = sp.y + wobbleY;
                sp.el.style.transform = 'translate(' + drawX + 'px, ' + drawY + 'px) rotate(' + sp.rot + 'deg)';
            }
            requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);
    })();
    </script>
</body>
</html>"""

# ============================================================
# Safari extension download
# ============================================================

app.get '/safari', (req, res) ->
    res.redirect '/safari/safari.safariextz'

app.get '/safari.safariextz', (req, res) ->
    fs.readFile '../client/safari/Safari.safariextz', (err, data) ->
        throw err if err
        res.contentType 'application/octet-stream'
        res.send data

app.get '/safari.manifest.plist', (req, res) ->
    fs.readFile 'config/safari.manifest.plist', (err, data) ->
        throw err if err
        res.contentType 'application/octet-stream'
        res.send data

# Static files
app.use express.static "#{__dirname}/../web"

app.listen 3040
