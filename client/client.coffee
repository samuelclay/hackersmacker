window._HS = (e) ->
    console.log(["HS", e]);

# window.HS_SERVER = 'nb.local.host:3030'
window.HS_SERVER = 'www.hackersmacker.org'

class window.HSGraph
    
    constructor: ->
        @decorateComments()
        
    decorateComments: ->
        @findCurrentUser()
        @findUsernames()
        @loadRelationships()
        @attachSharers()
        
    findCurrentUser: ->
        @me = $('.pagetop a[href^=user]').eq(0).attr('href').replace('user?id=', '')
        
    findUsernames: ->
        @usernames = _.uniq($('a[href^=user]').map ->
            $(@).attr('href').replace('user?id=', '')
        )
    
    loadRelationships: ->
        data = 
            u: @usernames
            me: @me
        $.ajax 
            url: "#{window.location.protocol}//#{HS_SERVER}/load"
            data: data
            traditional: true
            success: @attachRaters
        
    attachRaters: (@graph) =>
        # @graph = JSON.parse graphJSON
        $users = $('.default a[href^=user], .subtext a[href^=user]')
        console.log 'Hackersmacker graph', @graph, "#{$users.length} users"
        new HSRater $($user), @me for $user in $users

    attachSharers: ->

class window.HSRater
    
    constructor: (@$user, @me, @username) ->
        @username = @$user.attr('href').replace('user?id=', '')
        @clear()
        @build()
        @attach()
        @handle()
        return
    
    clear: ->
        @$user.siblings('.HS-rater').remove()
        
    build: ->
        foafFriend  = !!_.contains(HS.graph.foaf_friends, @username)
        foafFoe     = !!_.contains(HS.graph.foaf_foes, @username)
        graphStatus = ""
        graphStatus = "HS-friend" if _.contains(HS.graph.friends, @username)
        graphStatus = "HS-foe" if _.contains(HS.graph.foes, @username)
        foafStatus  = "HS-foaf-friend" if foafFriend
        foafStatus  = "HS-foaf-foe" if foafFoe
        foafTitle   = if foafFriend then 'Friend' else 'Foe'
        
        $pills = $ """<div class="HS-rater #{graphStatus}" data-username="#{@username}">
          <div class="HS-rater-button HS-rater-neutral"></div>
          <div class="HS-rater-button HS-rater-friend"></div>
          <div class="HS-rater-button HS-rater-foe"></div>
        </div>
        <div class="HS-foaf #{foafStatus}" title="#{foafTitle} of a friend">
          <div class="HS-foaf-start"></div>
          <div class="HS-foaf-end"></div>
        </div>"""
        
        @rater = $pills.filter '.HS-rater'
        @foaf = $pills.filter '.HS-foaf'
        @neutral = $ '.HS-rater-neutral', @rater
        @foe     = $ '.HS-rater-foe',     @rater
        @friend  = $ '.HS-rater-friend',  @rater
        
    attach: ->
        @$user.after @foaf
        @$user.after @rater
    
    handle: ->
        @animationOpts = 
            duration : 300,
            easing   : 'easeOutQuint'
            queue    : false
        @rater.filter('.HS-rater').bind('mouseenter', @expand)
              .bind('mouseleave', @collapse)
        _.each [@friend, @foe, @neutral], ($button) =>
            $button.bind 'click', (e) =>
                @save e
        return
                
    expand: =>
        clearTimeout @collapseTimeout
        @rater.animate  width: 70, @animationOpts
        @friend.animate left:  24, @animationOpts
        @foe.animate    left:  48, @animationOpts
    
    maybeCollapse: =>
        @collapseTimeout = setTimeout =>
            @collapse() if @collapseTimeout
        , 300
        
    collapse: =>
        @rater.animate  width: 22, @animationOpts
        @friend.animate left:  0,  @animationOpts
        @foe.animate    left:  0,  @animationOpts
        
    save: (e) ->
        $target = $ e.currentTarget
        if $target.hasClass('HS-rater-friend')
            @relationship = 'friend'
            HS.graph.friends.push(@username)
            HS.graph.foes = _.without HS.graph.foes, @username
        else if $target.hasClass('HS-rater-foe')
            @relationship = 'foe'
            HS.graph.friends = _.without HS.graph.friends, @username
            HS.graph.foes.push(@username)
        else
            HS.graph.friends = _.without HS.graph.friends, @username
            HS.graph.foes = _.without HS.graph.foes, @username
            @relationship = 'neutral'
            
        data = 
            username: @username
            me: @me
            relationship: @relationship
        $.ajax 
            url: "#{window.location.protocol}//#{HS_SERVER}/save"
            data: data
            traditional: true

        console.log 'Saving Hackersmacker', data, HS_SERVER, @
        HS.graph.friends.push
        @reset()
        @resetDuplicates()
    
    reset: ->
        @rater.removeClass 'HS-foe'
        @rater.removeClass 'HS-friend'
        @rater.addClass    "HS-#{@relationship}"
        @collapse()
    
    resetDuplicates: ->
        $dupes = $("a[href^=\"user?id=#{@username}\"]").not(@$user)
        new HSRater $($dupe), @me for $dupe in $dupes
        
$(document).ready ->
    window.HS = new HSGraph()