EventEmitter = require "node-event-emitter"
bluebird = require "bluebird"
{Promise} = bluebird
WebSocketFactory = require "./WebSocketFactory"

module.exports = class Connection extends EventEmitter

    constructor: (@url, @webSocketFactory = new WebSocketFactory()) ->
        @_connectionState = WebSocket.CLOSED
        @_socket          = null

    connect: (request = {}) =>
        return switch @_connectionState
            when WebSocket.CONNECTING then @_connectionPromise
            when WebSocket.OPEN       then bluebird.resolve()
            when WebSocket.CLOSING    then @_connectionPromise = @_connectionPromise.then => @_connect request
            when WebSocket.CLOSED     then @_connectionPromise = @_connect request

    disconnect: =>
        return switch @_connectionState
            when WebSocket.CONNECTING then @_connectionPromise = @_connectionPromise.then => @_disconnect()
            when WebSocket.OPEN       then @_connectionPromise = @_disconnect()
            when WebSocket.CLOSING    then @_connectionPromise
            when WebSocket.CLOSED     then bluebird.resolve()

    send: (message) =>
        @_socket.send JSON.stringify message

    _connect: (request) =>
        @_connectionState = WebSocket.CONNECTING

        return new Promise (resolve, reject) =>
            @_webSocketResolvers = {resolve, reject}
            @_socket = @webSocketFactory.create @url
            @_socket.onopen = =>
                @_open request
            @_socket.onclose = =>
                @_webSocketResolvers = null
                @_connectionState = WebSocket.CLOSED
                reject new Error "Unable to connect to server."

    _disconnect: =>
        @_connectionState = WebSocket.CLOSING

        return new Promise (resolve, reject) =>
            @on "disconnect", -> resolve()
            @_socket.close()

    _open: (request) =>
        @_socket.onclose   = @_close
        @_socket.onmessage = @_message

        @send \
            type: "handshake.request",
            version: "1.0.0",
            request: request,

    _close: (event) =>
        @_connectionState = WebSocket.CLOSED
        @_socket = null
        @emit "disconnect", event.code, event.reason

    _message: (event) =>
        try
            message = JSON.parse event.data
        catch error
            @_socket.close 4001, "Invalid message received."
            @_connectionState = WebSocket.CLOSED
            @emit "error", error
            return

        switch message.type
            when "handshake.approve"
                @_connectionState = WebSocket.OPEN
                @_webSocketResolvers.resolve message.response
                @_webSocketResolvers = null
                @emit "connect", message.response
            when "handshake.reject"
                @_connectionState = WebSocket.CLOSED
                @_webSocketResolvers.reject message.reason
                @_webSocketResolvers = null
                @emit "error", message.reason
            else
                @emit "message.#{message.type}", message
