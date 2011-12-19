(function() {
  var app, express, graph;

  express = require('express');

  app = express.createServer();

  graph = require('./graph');

  app.use(express.bodyParser());

  app.get('/load', function(req, res) {
    var originalUsername, usernames;
    originalUsername = req.query.me;
    usernames = req.query.usernames;
    return graph.findRelationships(originalUsername, usernames, function(m) {
      console.log("Load: " + m);
      return res.send("_HS('" + (JSON.stringify(m)) + "')");
    });
  });

  app.get('/save', function(req, res) {
    var originalUsername, relationship, username;
    username = req.query.username;
    relationship = req.query.relationship;
    originalUsername = req.query.me;
    graph.saveRelationship(originalUsername, relationship, username);
    return res.send("_HS('OK')");
  });

  app.listen(3030);

}).call(this);
