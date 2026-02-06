window._HS = (e) ->
    console.log(["HS", e]);

# window.HS_SERVER = 'nb.local.host:3030'
window.HS_SERVER = 'www.hackersmacker.org'

class window.HSGraph

    constructor: ->
        @auth_token = null
        @stored_username = null
        @verified = false
        @loadAuthToken =>
            @decorateComments()

    loadAuthToken: (callback) ->
        if chrome?.runtime?.sendMessage
            chrome.runtime.sendMessage { action: 'getAuthToken' }, (response) =>
                @auth_token = response?.auth_token or null
                @stored_username = response?.username or null
                @verified = !!@auth_token
                callback()
        else if typeof browser isnt 'undefined' and browser?.runtime?.sendMessage
            browser.runtime.sendMessage { action: 'getAuthToken' }, (response) =>
                @auth_token = response?.auth_token or null
                @stored_username = response?.username or null
                @verified = !!@auth_token
                callback()
        else
            callback()

    storeAuthToken: (token, username) ->
        @auth_token = token
        @stored_username = username
        @verified = true
        msg = { action: 'setAuthToken', auth_token: token, username: username }
        if chrome?.runtime?.sendMessage
            chrome.runtime.sendMessage msg
        else if typeof browser isnt 'undefined' and browser?.runtime?.sendMessage
            browser.runtime.sendMessage msg

    clearAuthToken: ->
        @auth_token = null
        @stored_username = null
        @verified = false
        msg = { action: 'clearAuthToken' }
        if chrome?.runtime?.sendMessage
            chrome.runtime.sendMessage msg
        else if typeof browser isnt 'undefined' and browser?.runtime?.sendMessage
            browser.runtime.sendMessage msg

    decorateComments: ->
        found = @findCurrentUser()
        return if not found
        @findUsernames()
        @loadRelationships()
        @attachSharers()

    findCurrentUser: ->
        $pageTop = $('.pagetop a[href^=user]').eq(0)
        if $pageTop.length == 0
            console.log "Please login to use Hacker Smacker"
            return false
        @me = $pageTop.attr('href').replace('user?id=', '')

        # Check if stored token matches current user
        if @auth_token and @stored_username is @me
            @verified = true
            return true
        else if @auth_token and @stored_username isnt @me
            # User switched accounts
            @clearAuthToken()
            @showWelcome()
            return true
        else
            # No stored token — first time or unverified
            @checkVerificationStatus()
            return true

    checkVerificationStatus: ->
        return unless @me
        $.ajax
            url: "#{window.location.protocol}//#{HS_SERVER}/verify/status"
            data: { me: @me }
            dataType: 'json'
            success: (response) =>
                if response.status is 'unverified'
                    @showWelcome()

    # ============================================================
    # First-time user experience
    # ============================================================

    showWelcome: ->
        return if $('.HS-verify-banner').length > 0
        $banner = $ """
            <tr><td colspan="2">
            <div class="HS-verify-banner" style="
                background: linear-gradient(to bottom, #FFFEF7, #FFF9E6);
                border: 1px solid #E0D8B8;
                padding: 14px 18px;
                margin: 6px 8px;
                font-size: 12px;
                font-family: Verdana, Geneva, sans-serif;
                color: #333;
                border-radius: 4px;
                line-height: 1.7;
                box-shadow: 0 1px 3px rgba(0,0,0,0.06);
            ">
                <div style="margin-bottom: 8px;">
                    <strong style="font-size: 13px; color: #2C2416;">Welcome to Hacker Smacker!</strong>
                </div>
                <div style="color: #5C5444;">
                    Rate commenters as <span style="color: #4F934D; font-weight: bold;">friends</span> or
                    <span style="color: #AC473B; font-weight: bold;">foes</span> using the orbs next to each name.
                    You'll also see your friends' ratings (friend-of-a-friend).
                </div>
                <div style="margin-top: 10px; padding-top: 10px; border-top: 1px solid #EDE8D6;">
                    <strong>To get started,</strong> verify you own this HN account (takes 30 seconds):
                    <a href="#" class="HS-verify-start" style="
                        color: #fff;
                        background: #96592A;
                        padding: 4px 12px;
                        border-radius: 3px;
                        text-decoration: none;
                        font-weight: bold;
                        font-size: 11px;
                        margin-left: 8px;
                        display: inline-block;
                    ">Verify my account &rarr;</a>
                </div>
            </div>
            </td></tr>
        """
        $('table#hnmain > tbody').children().eq(0).after($banner)

        $('.HS-verify-start').on 'click', (e) =>
            e.preventDefault()
            @startVerification()

    showVerifyNudge: ->
        # Shown when an unverified user tries to click a rating orb
        return if $('.HS-verify-nudge').length > 0
        # Scroll to and highlight the banner if it exists
        $banner = $('.HS-verify-banner')
        if $banner.length
            $banner.css('box-shadow', '0 0 0 3px #E6D950, 0 2px 8px rgba(0,0,0,0.1)')
            $('html, body').animate { scrollTop: $banner.offset().top - 50 }, 300
            setTimeout (->
                $banner.css('box-shadow', '0 1px 3px rgba(0,0,0,0.06)')
            ), 2000
        else
            @showWelcome()

    startVerification: ->
        $.ajax
            url: "#{window.location.protocol}//#{HS_SERVER}/verify/start"
            data: { me: @me }
            dataType: 'json'
            success: (response) =>
                if response.code is 1
                    @showTokenInstructions(response.verification_token)
                else if response.code is 2
                    @showTokenInstructions(response.verification_token) if response.verification_token

    showTokenInstructions: (token) ->
        $('.HS-verify-banner').html """
            <div style="line-height: 1.8;">
                <div style="margin-bottom: 10px;">
                    <strong style="font-size: 13px; color: #2C2416;">Verify your account</strong>
                    <span style="color: #8A8272; font-size: 11px; margin-left: 8px;">Almost done!</span>
                </div>
                <div style="
                    background: #F8F5EB;
                    border: 1px solid #E0D8B8;
                    border-radius: 4px;
                    padding: 12px 16px;
                    margin-bottom: 12px;
                ">
                    <div style="margin-bottom: 8px;">
                        <span style="
                            background: #96592A;
                            color: #fff;
                            padding: 1px 7px;
                            border-radius: 10px;
                            font-size: 11px;
                            font-weight: bold;
                            margin-right: 6px;
                        ">1</span>
                        <a href="https://news.ycombinator.com/user?id=#{@me}" target="_blank" style="
                            color: #96592A;
                            font-weight: bold;
                        ">Open your HN profile</a>
                        and add this anywhere in your <em>about</em> section:
                    </div>
                    <div style="text-align: center; margin: 8px 0;">
                        <code style="
                            background: #fff;
                            padding: 6px 14px;
                            border-radius: 3px;
                            font-size: 13px;
                            user-select: all;
                            border: 1px solid #DDD8C8;
                            letter-spacing: 0.5px;
                            cursor: text;
                        ">#{token}</code>
                    </div>
                    <div style="font-size: 11px; color: #8A8272; text-align: center;">
                        Click the code to select it, then copy &amp; paste into your profile.
                    </div>
                </div>
                <div>
                    <span style="
                        background: #96592A;
                        color: #fff;
                        padding: 1px 7px;
                        border-radius: 10px;
                        font-size: 11px;
                        font-weight: bold;
                        margin-right: 6px;
                    ">2</span>
                    After saving your profile, come back here and
                    <a href="#" class="HS-verify-check" style="
                        color: #fff;
                        background: #4F934D;
                        padding: 4px 12px;
                        border-radius: 3px;
                        text-decoration: none;
                        font-weight: bold;
                        font-size: 11px;
                        margin-left: 4px;
                    ">Check now</a>
                    <span class="HS-verify-status" style="color: #8A8272; margin-left: 8px; font-size: 11px;"></span>
                </div>
                <div style="margin-top: 8px; font-size: 11px; color: #8A8272;">
                    You can remove the token from your profile after verification.
                </div>
            </div>
        """
        @_verifyAttempt = 0
        $('.HS-verify-check').on 'click', (e) =>
            e.preventDefault()
            @pollVerification()

        # Start auto-polling after a delay
        setTimeout (=> @pollVerification()), 8000

    pollVerification: ->
        @_verifyAttempt = (@_verifyAttempt or 0)
        $('.HS-verify-status').text 'Checking...'
        $.ajax
            url: "#{window.location.protocol}//#{HS_SERVER}/verify/check"
            data: { me: @me }
            dataType: 'json'
            success: (response) =>
                if response.status is 'verified'
                    @storeAuthToken response.auth_token, @me
                    @showVerified()
                else if response.status is 'pending'
                    @_verifyAttempt++
                    retryAfter = response.retry_after or 10
                    $('.HS-verify-status').text "Not found yet. Will check again in #{retryAfter}s..."
                    setTimeout (=> @pollVerification()), retryAfter * 1000
                else if response.status is 'rate_limited'
                    retryAfter = response.retry_after or 20
                    $('.HS-verify-status').text "Checking again in #{retryAfter}s..."
                    setTimeout (=> @pollVerification()), retryAfter * 1000
                else if response.status is 'expired'
                    $('.HS-verify-banner').html """
                        <div style="color: #AC473B;">
                            Verification expired (took too long).
                            <a href="#" class="HS-verify-start" style="color: #96592A; font-weight: bold; margin-left: 6px;">Start over &rarr;</a>
                        </div>
                    """
                    $('.HS-verify-start').on 'click', (e) =>
                        e.preventDefault()
                        @startVerification()
            error: =>
                $('.HS-verify-status').text 'Could not reach server. Try again.'

    showVerified: ->
        $('.HS-verify-banner').html """
            <div>
                <span style="color: #4F934D; font-weight: bold; font-size: 13px;">&#10003; You're verified!</span>
                <span style="color: #5C5444; margin-left: 8px;">
                    You can now rate commenters. Click the orbs next to any username.
                </span>
                <a href="https://#{HS_SERVER}/user/#{@me}" target="_blank" style="
                    color: #96592A;
                    margin-left: 10px;
                    font-size: 11px;
                ">View your profile &rarr;</a>
            </div>
        """
        # Fade out after a while
        setTimeout (->
            $('.HS-verify-banner').animate { opacity: 0 }, 1000, ->
                $(@).parent().parent().remove()
        ), 10000

    # ============================================================
    # Core functionality
    # ============================================================

    findUsernames: ->
        @usernames = _.uniq($('a[href^=user]').map ->
            $(@).attr('href').replace('user?id=', '')
        )

    loadRelationships: ->
        data =
            u: @usernames
            me: @me
        data.auth_token = @auth_token if @auth_token
        $.ajax
            url: "#{window.location.protocol}//#{HS_SERVER}/load"
            data: data
            traditional: true
            success: @attachRaters

    attachRaters: (@graph) =>
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
        # Block saves if not verified — nudge user to verify
        if not HS.verified
            HS.showVerifyNudge()
            return

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

        context = @extractContext()

        data =
            username: @username
            me: @me
            relationship: @relationship
            auth_token: HS.auth_token
            comment_text: context.comment_text
            comment_url: context.comment_url
            thread_title: context.thread_title
            thread_url: context.thread_url
            parent_author: context.parent_author
        $.ajax
            url: "#{window.location.protocol}//#{HS_SERVER}/save"
            type: 'POST'
            data: data
            traditional: true
            error: (xhr) =>
                if xhr.status is 401
                    HS.clearAuthToken()
                    HS.showWelcome()

        console.log 'Saving Hackersmacker', @relationship, @username, HS_SERVER
        @reset()
        @resetDuplicates()

    extractContext: ->
        context =
            comment_text: ''
            comment_url: ''
            thread_title: ''
            thread_url: window.location.href
            parent_author: ''

        # Find the comment row containing this username
        $commentRow = @$user.closest('tr.athing.comtr')
        if not $commentRow.length
            $commentRow = @$user.closest('tr').filter ->
                $(@).find('.commtext').length > 0

        if $commentRow.length
            # Comment text (truncate to 500 chars)
            $commtext = $commentRow.find('.commtext')
            if $commtext.length
                text = $commtext.text()
                text = text.replace(/reply$/i, '').trim()
                context.comment_text = text.substring(0, 500)

            # Comment permalink
            $ageLink = $commentRow.find('.age a')
            if $ageLink.length
                href = $ageLink.attr('href')
                if href
                    context.comment_url = "https://news.ycombinator.com/#{href}" unless href.indexOf('http') is 0

        # Thread title
        $titleLink = $('.titleline a').first()
        $titleLink = $('.storylink').first() if not $titleLink.length
        if $titleLink.length
            context.thread_title = $titleLink.text().substring(0, 200)

        # For submission subtext ratings (rating the submitter, not a commenter)
        $subtext = @$user.closest('.subtext')
        if $subtext.length
            context.comment_text = ''
            context.comment_url = window.location.href

        context

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
