redis = require 'redis'
client = redis.createClient null, process.env.REDIS_HOST || null

USER_FRIENDS_WITH = "F"
USER_FRIENDED_BY = "f"
USER_FOES_WITH = "X"
USER_FOED_BY = "x"

module.exports =
    saveRelationship: (originalUsername, relationship, username) ->
        console.log " ---> [#{originalUsername}] Adding #{username} as a #{relationship}."

        friendsWith = "G:#{originalUsername}:#{USER_FRIENDS_WITH}"
        friendedBy  = "G:#{username}:#{USER_FRIENDED_BY}"
        foesWith    = "G:#{originalUsername}:#{USER_FOES_WITH}"
        foedBy      = "G:#{username}:#{USER_FOED_BY}"

        if relationship is 'friend'
            client.sadd friendsWith, username
            client.sadd friendedBy, originalUsername
            client.srem foesWith, username
            client.srem foedBy, originalUsername
        else if relationship is 'foe'
            client.srem friendsWith, username
            client.srem friendedBy, originalUsername
            client.sadd foesWith, username
            client.sadd foedBy, originalUsername
        else if relationship is 'neutral'
            client.srem friendsWith, username
            client.srem friendedBy, originalUsername
            client.srem foesWith, username
            client.srem foedBy, originalUsername

    saveRatingContext: (originalUsername, relationship, username, context) ->
        ratingKey = "R:#{originalUsername}:#{username}"
        timestamp = Math.floor(Date.now() / 1000)
        friendsHistory = "H:#{originalUsername}:F"
        foesHistory    = "H:#{originalUsername}:X"

        if relationship is 'neutral'
            client.del ratingKey
            client.zrem friendsHistory, username
            client.zrem foesHistory, username
            return

        client.hmset ratingKey,
            'relationship', relationship
            'comment_text', (context.comment_text or '').substring(0, 500)
            'comment_url', context.comment_url or ''
            'thread_title', context.thread_title or ''
            'thread_url', context.thread_url or ''
            'parent_author', context.parent_author or ''
            'timestamp', String(timestamp)

        if relationship is 'friend'
            client.zadd friendsHistory, timestamp, username
            client.zrem foesHistory, username
        else if relationship is 'foe'
            client.zadd foesHistory, timestamp, username
            client.zrem friendsHistory, username

    getProfile: (username, callback) ->
        friendsWith = "G:#{username}:#{USER_FRIENDS_WITH}"
        foesWith    = "G:#{username}:#{USER_FOES_WITH}"
        settingsKey = "U:#{username}"

        # Enrichment: check if each friend/foe has their own HS profile
        enrichAndReturn = (profile, cb) ->
            allNames = (f.name for f in profile.friends).concat(f.name for f in profile.foes)
            if allNames.length is 0
                return cb(profile)
            multi = client.multi()
            for name in allNames
                multi.scard "G:#{name}:#{USER_FRIENDS_WITH}"
                multi.scard "G:#{name}:#{USER_FOES_WITH}"
            multi.exec (e, results) ->
                for name, idx in allNames
                    has = (results[idx * 2] or 0) > 0 or (results[idx * 2 + 1] or 0) > 0
                    for f in profile.friends
                        f.hasProfile = has if f.name is name
                    for f in profile.foes
                        f.hasProfile = has if f.name is name
                cb(profile)

        client.hgetall settingsKey, (e, settings) ->
            profile =
                settings: settings or { profile_public: '1' }
                friends: []
                foes: []

            # Get all friends from both G: set and H: sorted set
            client.smembers friendsWith, (e, allFriends) ->
                allFriends = allFriends or []
                client.zrevrangebyscore "H:#{username}:F", '+inf', '-inf', 'WITHSCORES', (e, friendsWithScores) ->
                    # Build friends list with timestamps from sorted set
                    timestampMap = {}
                    if friendsWithScores
                        i = 0
                        while i < friendsWithScores.length
                            timestampMap[friendsWithScores[i]] = friendsWithScores[i + 1]
                            i += 2

                    # Merge: all friends from G: set, with timestamps from H: if available
                    friendNames = allFriends
                    # Add any from H: that might not be in G: (shouldn't happen but be safe)
                    for name of timestampMap
                        friendNames.push(name) unless name in friendNames

                    # Define fetchFoes before use (CoffeeScript var hoisting)
                    fetchFoes = ->
                        # Sort friends by timestamp desc (those with timestamps first)
                        profile.friends.sort (a, b) ->
                            ta = if a.timestamp then parseInt(a.timestamp) else 0
                            tb = if b.timestamp then parseInt(b.timestamp) else 0
                            tb - ta

                        # Now get foes
                        client.smembers foesWith, (e, allFoes) ->
                            allFoes = allFoes or []
                            client.zrevrangebyscore "H:#{username}:X", '+inf', '-inf', 'WITHSCORES', (e, foesWithScores) ->
                                foeTimestampMap = {}
                                if foesWithScores
                                    i = 0
                                    while i < foesWithScores.length
                                        foeTimestampMap[foesWithScores[i]] = foesWithScores[i + 1]
                                        i += 2

                                foeNames = allFoes
                                for name of foeTimestampMap
                                    foeNames.push(name) unless name in foeNames

                                foeRemaining = foeNames.length
                                if foeRemaining is 0
                                    return enrichAndReturn(profile, callback)

                                for name in foeNames
                                    do (name) ->
                                        client.hgetall "R:#{username}:#{name}", (e, ctx) ->
                                            profile.foes.push
                                                name: name
                                                timestamp: foeTimestampMap[name] or null
                                                context: ctx or {}
                                            foeRemaining--
                                            if foeRemaining is 0
                                                profile.foes.sort (a, b) ->
                                                    ta = if a.timestamp then parseInt(a.timestamp) else 0
                                                    tb = if b.timestamp then parseInt(b.timestamp) else 0
                                                    tb - ta
                                                enrichAndReturn(profile, callback)

                    # Fetch context for each friend
                    remaining = friendNames.length
                    if remaining is 0
                        return fetchFoes()

                    for name in friendNames
                        do (name) ->
                            client.hgetall "R:#{username}:#{name}", (e, ctx) ->
                                profile.friends.push
                                    name: name
                                    timestamp: timestampMap[name] or null
                                    context: ctx or {}
                                remaining--
                                fetchFoes() if remaining is 0

    getProfileSettings: (username, callback) ->
        client.hgetall "U:#{username}", (e, settings) ->
            callback settings or { profile_public: '1' }

    setProfileVisibility: (username, isPublic, callback) ->
        client.hset "U:#{username}", 'profile_public', (if isPublic then '1' else '0'), ->
            callback?()

    findRelationships: (originalUsername, usernames, callback) ->
        multi1 = client.multi()
        multi2 = client.multi()
        graph = friends: [], foes: [], foaf_friends: [], foaf_foes: []
        onpageUserSet = "T:#{originalUsername}:onpage"
        friendsWith = "G:#{originalUsername}:#{USER_FRIENDS_WITH}"
        foesWith    = "G:#{originalUsername}:#{USER_FOES_WITH}"

        # Store all users on the page in Redis to be used for set intersections
        client.sadd onpageUserSet, usernames, (e, m) ->

            # Match friends/foes of current user with users on page
            multi1.sinter friendsWith, onpageUserSet, (e, m) ->
                graph.friends = graph.friends.concat m if m
            multi1.sinter foesWith, onpageUserSet, (e, m) ->
                graph.foes = graph.foes.concat m if m

            # For each of the current user's friends, match the friend's friends/foes with users on the page
            multi1.smembers friendsWith, (e, m) ->
                m = m or []
                for friend in m
                    do (friend) ->
                        multi2.sinter "G:#{friend}:#{USER_FRIENDS_WITH}", onpageUserSet, (e, m) ->
                            graph.foaf_friends = graph.foaf_friends.concat m if m
                        multi2.sinter "G:#{friend}:#{USER_FOES_WITH}", onpageUserSet, (e, m) ->
                            graph.foaf_foes = graph.foaf_foes.concat m if m
                multi2.exec ->
                    callback graph
                    client.del onpageUserSet

            multi1.exec()
