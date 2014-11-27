EventEmitter = require 'node-event-emitter'
JSONStream = require 'JSONStream'
Promise = require 'promise'

module.exports = class Connection extends EventEmitter

    constructor: (@url) ->
        @_connectionState = WebSocket.CLOSED

        @_parser = JSONStream.parse '*'
        @_parser.on 'error', @_onParserError
        @_parser.on 'data',  @_onParserData

    connect: =>
        switch @_connectionState
            when WebSocket.CONNECTING
                return @_connectionPromise
            when WebSocket.OPEN
                return Promise.resolve()
            when WebSocket.CLOSING
                return @_connectionPromise = @_connectionPromise.then => @_doConnect()
            when WebSocket.CLOSED
                return @_connectionPromise = @_doConnect()

    disconnect: =>
        switch @_connectionState
            when WebSocket.CONNECTING
                return @_connectionPromise = @_connectionPromise.then => @_doDisconnect()
            when WebSocket.OPEN
                return @_connectionPromise = @_doDisconnect()
            when WebSocket.CLOSING
                return @_connectionPromise
            when WebSocket.CLOSED
                return Promise.resolve()

    send: (message) =>
        if message isnt Object message
            throw new TypeError 'Messages must be objects.'
        @connect().then =>
            @_socket.send JSON.stringify [message]

    _doConnect: =>
        @_connectionState = WebSocket.CONNECTING

        return new Promise (resolve, reject) =>
            @_socket = new WebSocket @url
            @_socket.onopen = =>
                @_onConnectionOpen()
                resolve()
            @_socket.onclose = =>
                @_connectionState = WebSocket.CLOSED
                @emit 'error'
                reject()

    _doDisconnect: =>
        return new Promise (resolve, reject) =>
            @_socket.close()

    _onConnectionOpen: =>
        @_socket.onclose   = @_onConnectionClose
        @_socket.onmessage = @_onConnectionMessage
        @_connectionState  = WebSocket.OPEN
        @emit 'connect'

    _onConnectionClose: (event) =>
        @_connectionState = WebSocket.CLOSED
        @emit 'disconnect', event.code, event.reason

    _onConnectionMessage: (event) =>
        @_parser.write event.data

    _onParserError: (error) =>
        @_socket.close 4001, 'Invalid message received.'
        @_connectionState = WebSocket.CLOSED
        @emit 'error', error

    _onParserData: (message) =>
        if message is Object message
            @emit message.type, message
        else
            @_onParserError "Invalid message received: #{JSON.stringify message}"
