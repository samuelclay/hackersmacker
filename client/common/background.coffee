# HackerSmacker background script
# Manages auth token storage via chrome.storage.local / browser.storage.local

storage = chrome?.storage?.local or browser?.storage?.local

handleMessage = (request, sender, sendResponse) ->
    switch request.action
        when 'getAuthToken'
            storage.get ['hs_auth_token', 'hs_username'], (data) ->
                sendResponse
                    auth_token: data?.hs_auth_token or null
                    username: data?.hs_username or null
            return true  # Keep channel open for async response

        when 'setAuthToken'
            storage.set
                hs_auth_token: request.auth_token
                hs_username: request.username
            , ->
                sendResponse { success: true }
            return true

        when 'clearAuthToken'
            storage.remove ['hs_auth_token', 'hs_username'], ->
                sendResponse { success: true }
            return true

if chrome?.runtime?.onMessage
    chrome.runtime.onMessage.addListener handleMessage
else if typeof browser isnt 'undefined' and browser?.runtime?.onMessage
    browser.runtime.onMessage.addListener handleMessage
