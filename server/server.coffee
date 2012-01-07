express = require 'express'
app = express.createServer()
graph = require './graph'

app.use(express.bodyParser());

app.get '/load', (req, res) ->
    res.header 'Access-Control-Allow-Origin', 'http://news.ycombinator.com'
    originalUsername = req.query.me
    usernames = req.query.u
    graph.findRelationships originalUsername, usernames, (m) ->
        console.log " ---> [#{originalUsername}] Load #{req.headers.referer}:" +
                    " #{usernames.length} users -" +
                    " #{m.friends.length} friends, #{m.foes.length} foes," +
                    " #{m.foaf_friends.length}/#{m.foaf_foes.length} foaf"
        res.contentType 'json'
        res.send "#{JSON.stringify(m)}"
    
app.get '/save', (req, res) ->
    res.header 'Access-Control-Allow-Origin', 'http://news.ycombinator.com'
    username = req.query.username
    relationship = req.query.relationship
    originalUsername = req.query.me
    graph.saveRelationship originalUsername, relationship, username
    response = code: 1, message: "OK"
    res.send "#{JSON.stringify(response)}"

app.listen 3030
