AsyncBinaryState = require "../AsyncBinaryState"
bluebird = require "bluebird"
EventEmitter = require "node-event-emitter"
HandshakeManager = require "./HandshakeManager"

module.exports = class PersistentConnection extends EventEmitter

    constructor: (
        @connection
        @handshakeManager = new HandshakeManager()
        @reconnectWait = 3
        @keepaliveWait = 30
    ) -> @_state = new AsyncBinaryState()

    connect: -> @_state.setOn =>
        @connection.once "disconnect", @_reconnect

        bluebird.method => @handshakeManager.buildRequest()
        .then (request) => @connection.connect request
        .then (response) =>
            @connection.once "disconnect", @_disconnect

            keepalive = => #do keepalive
            wait = Math.round @keepaliveWait * 1000

            @_keepaliveInterval = setInterval keepalive, wait

            @handshakeManager.handleResponse response

            @emit "connect", response

            response
        .catch (error) =>
            @emit "error", error

            throw error

    disconnect: -> @_state.setOff =>
        @connection.removeListener "disconnect", @_reconnect

        if @_reconnectInterval?
            clearInterval @_reconnectInterval
            delete @_reconnectInterval

        @connection.disconnect()

    send: (message) => @connect.send message

    waitForConnect: ->
        return bluebird.resolve() if @_state.isOn

        new Promise (resolve, reject) =>
            @once "connect", -> resolve()
            @once "error", -> reject()

    _disconnect: =>
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
