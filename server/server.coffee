express = require 'express'
app = express.createServer()
graph = require './graph'

app.use(express.bodyParser());

app.get '/load', (req, res) ->
    originalUsername = req.query.me
    usernames = req.query.usernames
    graph.findRelationships originalUsername, usernames, (m) ->
        console.log "Load: #{m}"
        res.send "_HS('#{JSON.stringify(m)}')"
    
app.get '/save', (req, res) ->
    username = req.query.username
    relationship = req.query.relationship
    originalUsername = req.query.me
    graph.saveRelationship originalUsername, relationship, username
    res.send "_HS('OK')"

app.listen 3030
