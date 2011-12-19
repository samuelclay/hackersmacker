redis = require 'redis'
client = redis.createClient()

USER_FRIENDS_WITH = "F"
USER_FRIENDED_BY = "f"
USER_FOES_WITH = "X"
USER_FOED_BY = "x"

module.exports =
    saveRelationship: (originalUsername, relationship, username) ->
        console.log " ---> #{originalUsername} thinks #{username} is a #{relationship}."
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
    
    findRelationships: (originalUsername, usernames, callback) ->
        multi = client.multi()
        graph = friends: [], foes: []
        for username in usernames
            ((username) ->
                multi.sismember "G:#{originalUsername}:#{USER_FRIENDS_WITH}", username, (e, m) ->
                    graph.friends.push username if m
                multi.sismember "G:#{originalUsername}:#{USER_FOES_WITH}", username, (e, m) ->
                    graph.foes.push username if m
            )(username)
        multi.exec (e, m) ->
            callback graph
