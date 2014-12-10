EventEmitter = require "node-event-emitter"
JSONStream = require "JSONStream"
bluebird = require "bluebird"
{Promise} = bluebird
WebSocketFactory = require "./WebSocketFactory"

module.exports = class Connection extends EventEmitter

    constructor: (@url, @webSocketFactory = new WebSocketFactory()) ->
        @_connectionState = WebSocket.CLOSED
        @_socket          = null

        @parser = JSONStream.parse "*"
        @parser.on "error", @_parserError
        @parser.on "data",  @_parserMessage

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
        @_socket.send JSON.stringify [message]

    _connect: (request) =>
        @_connectionState = WebSocket.CONNECTING

        return new Promise (resolve, reject) =>
            @_socket = @webSocketFactory.create @url
            @_socket.onopen = =>
                @_open request
                resolve()
            @_socket.onclose = =>
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
        @_connectionState  = WebSocket.OPEN

        @send \
            type: "handshake.request",
            version: "1.0.0",
            request: request,

    _close: (event) =>
        @_connectionState = WebSocket.CLOSED
        @_socket = null
        @emit "disconnect", event.code, event.reason

    _message: (event) =>
        @parser.write event.data

    _parserError: (error) =>
        @_socket.close 4001, "Invalid message received."
        @_connectionState = WebSocket.CLOSED
        @emit "error", error

    _parserMessage: (message) =>
        switch message.type
            when "handshake.approve"
                @emit "connect", message.response
            when "handshake.reject"
                @emit "error", message.reason
            else
                @emit "message.#{message.type}", message
