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
