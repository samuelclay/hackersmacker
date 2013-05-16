express = require 'express'
fs = require 'fs'
graph = require './graph'
crypto = require 'crypto'
http = require 'http'
                 
privateKey = fs.readFileSync('certificates/hackersmacker.key').toString()
certificate = fs.readFileSync('certificates/hackersmacker.pem').toString()

app = express.createServer key: privateKey, cert: certificate
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

app.get '/safari', (req, res) ->
    res.redirect '/safari.safariextz'
    
app.get '/safari.safariextz', (req, res) ->
    fs.readFile '../client/Safari.safariextz', (err, data) ->
        throw err if err
        res.contentType 'application/octet-stream'
        res.send data

app.get '/safari.manifest.plist', (req, res) ->
    fs.readFile 'config/safari.manifest.plist', (err, data) ->
        throw err if err
        res.contentType 'application/octet-stream'
        res.send data
    
app.use express.static "#{__dirname}/../web"

app.listen 3030
