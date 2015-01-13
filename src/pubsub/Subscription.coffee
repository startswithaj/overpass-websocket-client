bluebird = require "bluebird"
EventEmitter = require "node-event-emitter"
regexEscape = require "escape-string-regexp"
{Promise} = require "bluebird"
{TimeoutError} = require "bluebird"
AsyncBinaryState = require "../AsyncBinaryState"

module.exports = class Subscription extends EventEmitter

    constructor: (@connection, @topic, @id, @timeout = 3) ->

        @_state = new AsyncBinaryState()

        atoms = for atom in topic.split "."
            switch atom
                when "*"
                    "(.+)"
                when "?"
                    "([^.]+)"
                else
                    regexEscape atom

        @_pattern = new RegExp "^#{atoms.join regexEscape "."}$"

    enable: ->
        @_state.setOn =>
            promise = new Promise (resolve) => @_resolve = resolve

            @connection.on "message.pubsub.subscribed", @_subscribed
            @connection.on "message.pubsub.publish", @_publish
            @connection.on "disconnect", @_disconnect

            @connection.send type: "pubsub.subscribe", id: @id, topic: @topic

            timeout = Math.round @timeout * 1000

            promise
            .timeout timeout, "Subscription request timed out."
            .catch TimeoutError, (error) =>
                @_removeListeners()

                throw error

    disable: ->
        @_state.setOff =>
            @connection.send type: "pubsub.unsubscribe", id: @id
            @_removeListeners()

    _subscribed: (message) => @_resolve() if message.id is @id

    _publish: (message) =>
        if @_pattern.test message.topic
            @emit "message", message.topic, message.payload

    _disconnect: => @_state.setOff @_removeListeners

    _removeListeners: =>
        @connection.removeListener "message.pubsub.subscribed", @_subscribed
        @connection.removeListener "message.pubsub.publish", @_publish
        @connection.removeListener "disconnect", @_disconnect

