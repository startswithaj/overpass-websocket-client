AsyncBinaryState = require "../AsyncBinaryState"
bluebird = require "bluebird"
{Promise} = require "bluebird"
EventEmitter = require "node-event-emitter"
HandshakeManager = require "./HandshakeManager"

module.exports = class PersistentConnection extends EventEmitter

    constructor: (
        @connection
        @handshakeManager = new HandshakeManager()
        @reconnectWait = 3
        @keepaliveWait = 30
    ) ->
        @_state = new AsyncBinaryState()
        @_waitForConnect = null
        @_waitForConnectResolvers = null

    connect: -> @_state.setOn =>
        @connection.once "disconnect", @_reconnect

        buildRequest = bluebird.method => @handshakeManager.buildRequest()

        buildRequest()
        .then (request) => @connection.connect request
        .then (response) =>
            @connection.on "message", @_message
            @connection.once "disconnect", @_disconnect

            keepalive = => #do keepalive
            wait = Math.round @keepaliveWait * 1000

            @_keepaliveInterval = setInterval keepalive, wait

            @handshakeManager.handleResponse response

            @emit "connect", response

            @_waitForConnectResolvers.resolve response if @_waitForConnect?

            response
        .catch (error) =>
            @emit "error", error

            if @_waitForConnect
                @_waitForConnectResolvers.reject error
                @_waitForConnect = null
                @_waitForConnectResolvers = null

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
        @_waitForConnect ?= new Promise (resolve, reject) =>
            @_waitForConnectResolvers = {resolve, reject}

    _disconnect: =>
        @_waitForConnect = null
        @_waitForConnectResolvers = null

        clearInterval @_keepaliveInterval
        delete @_keepaliveInterval

        @_state.setOff()

        @emit "disconnect", @

    _reconnect: =>
        reconnect = =>
            @connect().then =>
                clearInterval @_reconnectInterval
                delete @_reconnectInterval
        wait = Math.round @reconnectWait * 1000

        @_reconnectInterval = setInterval reconnect, wait

    _message: (message) =>
        @emit "message", message
        @emit "message.#{message.type}", message

