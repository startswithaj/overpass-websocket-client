EventEmitter = require "node-event-emitter"
JSONStream = require "JSONStream"
Promise = require "promise"

module.exports = class Connection extends EventEmitter

    constructor: (@url) ->
        @connectionState = WebSocket.CLOSED
        @isReady         = false
        @socket          = null

        @parser = JSONStream.parse "*"
        @parser.on "error", @_parserError
        @parser.on "data",  @_parserMessage

    connect: (request = {}) =>
        return switch @connectionState
            when WebSocket.CONNECTING then @_connectionPromise
            when WebSocket.OPEN       then Promise.resolve()
            when WebSocket.CLOSING    then @_connectionPromise = @_connectionPromise.then => @_connect request
            when WebSocket.CLOSED     then @_connectionPromise = @_connect request

    disconnect: =>
        return switch @connectionState
            when WebSocket.CONNECTING then @_connectionPromise = @_connectionPromise.then => @_disconnect()
            when WebSocket.OPEN       then @_connectionPromise = @_disconnect()
            when WebSocket.CLOSING    then @_connectionPromise
            when WebSocket.CLOSED     then Promise.resolve()

    send: (message) =>
        @socket.send JSON.stringify [message]

    _connect: (request) =>
        @connectionState = WebSocket.CONNECTING

        return new Promise (resolve, reject) =>
            @socket = new WebSocket @url
            @socket.onopen = =>
                @_open request
                resolve()
            @socket.onclose = =>
                @connectionState = WebSocket.CLOSED
                @emit "error", "Unable to connect to server."
                reject()

    _disconnect: =>
        return new Promise (resolve, reject) =>
            @socket.close()
            resolve()

    _open: (request) =>
        @socket.onclose   = @_close
        @socket.onmessage = @_message
        @connectionState  = WebSocket.OPEN

        @send \
            type: "handshake.request",
            version: "1.0.0",
            request: request,

    _close: (event) =>
        @connectionState = WebSocket.CLOSED
        @socket = null
        @emit "disconnect", event.code, event.reason

    _message: (event) =>
        @parser.write event.data

    _parserError: (error) =>
        @socket.close 4001, "Invalid message received."
        @connectionState = WebSocket.CLOSED
        @emit "error", error

    _parserMessage: (message) =>
        switch message.type
            when 'handshake.approve'
                @isReady = true
                @emit 'connect', message.response
            when 'handshake.reject'
                @emit "error", message.reason
            else
                @emit message.type, message
