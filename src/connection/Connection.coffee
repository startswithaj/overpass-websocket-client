{EventEmitter} = require "events"
{Promise, TimeoutError} = require "bluebird"

AsyncBinaryState = require "../AsyncBinaryState"
WebSocketFactory = require "./WebSocketFactory"

module.exports = class Connection extends EventEmitter

    constructor: (
        @url,
        @connectTimeout = 3,
        @webSocketFactory = new WebSocketFactory()
    ) ->
        @_state = new AsyncBinaryState()
        @_socket = null
        @_connectionResolver = null

    connect: (request = {}) =>
        return @_connectPromise = @_state.setOn =>
            @_connectionResolver = Promise.defer()

            @_socket = @webSocketFactory.create @url
            @_socket.onopen = => @_open request
            @_socket.onclose = @_closeDuringConnect

            timeout = Math.round @connectTimeout * 1000

            @_connectionResolver.promise
            .timeout timeout, "Connection timed out."
            .catch TimeoutError, (error) =>
                @_socket.close 4001, "Connection handshake timed out."

                throw error

    disconnect: =>
        deferred = Promise.defer();

        @_state.setOff =>
            deferred.promise
            .tap =>
                @emit "disconnect", 1000, "Connection terminated by client."
            .catch ->

            @_socket.onopen = ->
            @_socket.onclose = ->
            @_socket.onmessage = ->

            @_socket.close()
            @_socket = null

        deferred.resolve()

        return deferred.promise

    send: (message) =>
        if @_state.isOn
            @_send message
        else
            throw new Error "Unable to send message. Not connected."

    _send: (message) => @_socket.send JSON.stringify message

    _open: (request) =>
        @_socket.onmessage = @_message

        @_send
            type: "handshake.request"
            version: "1.0.0"
            request: request

    _closeDuringConnect: =>
        @_connectionResolver.reject new Error "Unable to connect to server."
        @_connectionResolver = null

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
            return

        switch message.type
            when "handshake.approve"
                @_connectPromise
                .then => @emit "connect", message.response

                @_connectionResolver.resolve message.response
                @_connectionResolver = null
                @_socket.onclose = @_close
            when "handshake.reject"
                @_connectionResolver.reject new Error message.reason
                @_connectionResolver = null
                @_socket.onclose = null
                @_socket = null
                @_state.setOff()
            else
                @emit "message", message
                @emit "message.#{message.type}", message
