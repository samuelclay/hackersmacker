(function() {
  var USER_FOED_BY, USER_FOES_WITH, USER_FRIENDED_BY, USER_FRIENDS_WITH, client, redis;

  redis = require('redis');

  client = redis.createClient();

  USER_FRIENDS_WITH = "F";

  USER_FRIENDED_BY = "f";

  USER_FOES_WITH = "X";

  USER_FOED_BY = "x";

  module.exports = {
    saveRelationship: function(originalUsername, relationship, username) {
      var foedBy, foesWith, friendedBy, friendsWith;
      console.log(" ---> " + originalUsername + " thinks " + username + " is a " + relationship + ".");
      friendsWith = "G:" + originalUsername + ":" + USER_FRIENDS_WITH;
      friendedBy = "G:" + username + ":" + USER_FRIENDED_BY;
      foesWith = "G:" + originalUsername + ":" + USER_FOES_WITH;
      foedBy = "G:" + username + ":" + USER_FOED_BY;
      if (relationship === 'friend') {
        client.sadd(friendsWith, username);
        client.sadd(friendedBy, originalUsername);
        client.srem(foesWith, username);
        return client.srem(foedBy, originalUsername);
      } else if (relationship === 'foe') {
        client.srem(friendsWith, username);
        client.srem(friendedBy, originalUsername);
        client.sadd(foesWith, username);
        return client.sadd(foedBy, originalUsername);
      } else if (relationship === 'neutral') {
        client.srem(friendsWith, username);
        client.srem(friendedBy, originalUsername);
        client.srem(foesWith, username);
        return client.srem(foedBy, originalUsername);
      }
    },
    findRelationships: function(originalUsername, usernames, callback) {
      var graph, multi, username, _fn, _i, _len;
      multi = client.multi();
      graph = {
        friends: [],
        foes: []
      };
      _fn = function(username) {
        multi.sismember("G:" + originalUsername + ":" + USER_FRIENDS_WITH, username, function(e, m) {
          if (m) return graph.friends.push(username);
        });
        return multi.sismember("G:" + originalUsername + ":" + USER_FOES_WITH, username, function(e, m) {
          if (m) return graph.foes.push(username);
        });
      };
      for (_i = 0, _len = usernames.length; _i < _len; _i++) {
        username = usernames[_i];
        _fn(username);
      }
      return multi.exec(function(e, m) {
        return callback(graph);
      });
    }
  };

}).call(this);
