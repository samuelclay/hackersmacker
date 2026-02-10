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

        when 'setPendingVerification'
            storage.set
                hs_pending_token: request.token
                hs_pending_username: request.username
            , ->
                sendResponse { success: true }
            return true

        when 'getPendingVerification'
            storage.get ['hs_pending_token', 'hs_pending_username'], (data) ->
                sendResponse
                    token: data?.hs_pending_token or null
                    username: data?.hs_pending_username or null
            return true

        when 'clearPendingVerification'
            storage.remove ['hs_pending_token', 'hs_pending_username'], ->
                sendResponse { success: true }
            return true

        when 'getColorblind'
            storage.get ['hs_colorblind'], (data) ->
                sendResponse
                    colorblind: !!data?.hs_colorblind
            return true

        when 'setColorblind'
            storage.set { hs_colorblind: !!request.enabled }, ->
                sendResponse { success: true }
            return true

if chrome?.runtime?.onMessage
    chrome.runtime.onMessage.addListener handleMessage
else if typeof browser isnt 'undefined' and browser?.runtime?.onMessage
    browser.runtime.onMessage.addListener handleMessage
