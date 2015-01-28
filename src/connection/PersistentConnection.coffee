AsyncBinaryState = require "../AsyncBinaryState"
Promise = require "bluebird"
EventEmitter = require "node-event-emitter"
HandshakeManager = require "./HandshakeManager"

module.exports = class PersistentConnection extends EventEmitter

    constructor: (
        @connection
        @handshakeManager = new HandshakeManager()
        @reconnectWait = 3
        @reconnectLimit = 20
        @keepaliveWait = 30
    ) ->
        @_state = new AsyncBinaryState()
        @_waitForConnectResolver = null

    connect: -> @_state.setOn =>
        buildRequest = Promise.method => @handshakeManager.buildRequest()

        buildRequest()
        .then (request) => @connection.connect request
        .catch (error) =>
            @_reconnect()

            throw error
        .then (response) =>
            @connection.on "message", @_message
            @connection.once "disconnect", @_disconnect
            @connection.once "disconnect", @_reconnect

            keepalive = => @send type: "connection.heartbeat"
            wait = Math.round @keepaliveWait * 1000

            @_keepaliveInterval = setInterval keepalive, wait

            @handshakeManager.handleResponse response

            @emit "connect", response

            if @_waitForConnectResolver?
                @_waitForConnectResolver.resolve response

            response
        .catch (error) =>
            @connection.removeListener "message", @_message
            @connection.removeListener "disconnect", @_disconnect
            @connection.removeListener "disconnect", @_reconnect
            @emit "error", error

            throw error

    disconnect: -> @_state.setOff =>
        @connection.removeListener "disconnect", @_reconnect

        if @_reconnectInterval?
            clearInterval @_reconnectInterval
            delete @_reconnectInterval

        @connection.disconnect().then =>
            @connection.removeListener "message", @_message

    send: (message) => @connection.send message

    waitForConnect: ->
        unless @_waitForConnectResolver?
            @_waitForConnectResolver = Promise.defer()
            @_waitForConnectResolver.resolve() if @_state.isOn

        @_waitForConnectResolver.promise

    _disconnect: =>
        @_waitForConnectResolver = null

        clearInterval @_keepaliveInterval
        delete @_keepaliveInterval

        @_state.setOff()

        @emit "disconnect", @

    _reconnect: =>
        reconnect = =>
            isLastAttempt = ++@_reconnectCount >= @reconnectLimit

            if isLastAttempt
                clearInterval @_reconnectInterval
                delete @_reconnectInterval

            @connect()
            .tap =>
                clearInterval @_reconnectInterval
                delete @_reconnectInterval
            .catch (error) =>
                if isLastAttempt and @_waitForConnectResolver?
                    @_waitForConnectResolver.reject error

        wait = Math.round @reconnectWait * 1000

        @_reconnectCount = 0
        @_reconnectInterval = setInterval reconnect, wait

    _message: (message) =>
        @emit "message", message
        @emit "message.#{message.type}", message

