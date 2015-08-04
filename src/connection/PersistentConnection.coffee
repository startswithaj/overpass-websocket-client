Promise = require "bluebird"
random = require "lodash.random"
{EventEmitter} = require "events"

AsyncBinaryState = require "../AsyncBinaryState"
HandshakeManager = require "./HandshakeManager"

module.exports = class PersistentConnection extends EventEmitter

    constructor: (
        @connection
        @handshakeManager = new HandshakeManager()
        @reconnectWaitMin = 3
        @reconnectWaitMax = 5
        @reconnectLimit = 20
        @keepaliveWait = 30
    ) ->
        @_state = new AsyncBinaryState()
        @_waitForConnectResolver = null

    connect: -> @_connect()

    disconnect: -> @_state.setOff =>
        @connection.removeListener "disconnect", @_reconnect

        @_cancelReconnect()

        @connection.disconnect().then =>
            @connection.removeListener "message", @_message

    _connect: (isReconnect = false) -> @_state.setOn =>
        buildRequest = Promise.method => @handshakeManager.buildRequest()

        buildRequest()
        .then (request) => @connection.connect request
        .catch (error) =>
            @_reconnect() unless isReconnect

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

        @_state.setOff().then =>
          @emit "disconnect", arguments...

    _reconnect: =>
        return if @_reconnectTimeout?

        @_reconnectCount = 0
        @_scheduleReconnect()

    _scheduleReconnect: ->
        wait = Math.round \
            random(@reconnectWaitMin, @reconnectWaitMax, true) * 1000
        @_reconnectTimeout = setTimeout @_handleReconnect, wait

    _cancelReconnect: ->
        if @_reconnectTimeout?
            clearTimeout @_reconnectTimeout
            delete @_reconnectTimeout

    _handleReconnect: =>
        isLastAttempt = ++@_reconnectCount >= @reconnectLimit

        @_cancelReconnect() if isLastAttempt

        @emit "reconnect", @_reconnectCount

        @_connect true
        .tap => @_cancelReconnect()
        .catch (error) =>
            if isLastAttempt
                if @_waitForConnectResolver?
                    @_waitForConnectResolver.reject error

                @emit "reconnectFailure", error, @
            else
                @_scheduleReconnect()

    _message: (message) =>
        @emit "message", arguments...
        @emit "message.#{message.type}", arguments...
