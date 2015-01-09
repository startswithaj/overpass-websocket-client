EventEmitter = require "node-event-emitter"
bluebird = require "bluebird"
{Promise, TimeoutError} = bluebird
WebSocketFactory = require "./WebSocketFactory"
AsyncBinaryState = require "../AsyncBinaryState"

module.exports = class Connection extends EventEmitter

    constructor: (
        @url,
        @connectTimeout = 10,
        @webSocketFactory = new WebSocketFactory()
    ) ->
        @_state = new AsyncBinaryState()
        @_socket = null
        @_socketResolvers = null

    connect: (request = {}) =>
        return @_state.setOn =>
            promise = new Promise (resolve, reject) =>
                @_socketResolvers = {resolve, reject}
                @_socket = @webSocketFactory.create @url
                @_socket.onopen = =>
                    @_open request
                @_socket.onclose = =>
                    @_socketResolvers = null
                    reject new Error "Unable to connect to server."

            timeout = Math.round @connectTimeout * 1000

            promise.timeout timeout, "Connection timed out."
            .catch TimeoutError, (error) =>
                @_socket.close 4001, "Connection handshake timed out."

                throw error

    disconnect: =>
        return @_state.setOff =>
            return new Promise (resolve, reject) =>
                @on "disconnect", -> resolve()
                @_socket.close()

    send: (message) => @_socket.send JSON.stringify message

    _open: (request) =>
        @_socket.onclose = @_close
        @_socket.onmessage = @_message

        @send \
            type: "handshake.request",
            version: "1.0.0",
            request: request,

    _close: (event) =>
        @_state.setOff()
        @_socket = null
        @emit "disconnect", event.code, event.reason

    _message: (event) =>
        try
            message = JSON.parse event.data
        catch error
            @_socket.close 4001, "Invalid message received."
            @_state.setOff()
            @emit "error", error
            return

        switch message.type
            when "handshake.approve"
                @_socketResolvers.resolve message.response
                @_socketResolvers = null
                @emit "connect", message.response
            when "handshake.reject"
                @_socketResolvers.reject message.reason
                @_socketResolvers = null
                @emit "error", message.reason
            else
                @emit "message.#{message.type}", message
