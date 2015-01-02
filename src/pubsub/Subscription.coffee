bluebird = require "bluebird"
EventEmitter = require "node-event-emitter"
regexEscape = require "escape-string-regexp"
{Promise} = require "bluebird"
{TimeoutError} = require "bluebird"

module.exports = class Subscription extends EventEmitter

    constructor: (@connection, @topic, @id, @timeout = 10) ->
        @_subscriber = bluebird.resolve()
        @_isSubscribed = false

        atoms = for atom in topic.split "."
            switch atom
                when "*"
                    "(.+)"
                when "?"
                    "([^.]+)"
                else
                    regexEscape atom

        @_pattern = new RegExp "^#{atoms.join regexEscape "."}$"

    enable: -> @_subscriber = @_subscriber.then @_subscribe, @_subscribe

    disable: -> @_subscriber = @_subscriber.then @_unsubscribe, @_unsubscribe

    _subscribe: =>
        return bluebird.resolve() if @_isSubscribed

        @_isSubscribed = true

        promise = new Promise (resolve) => @_resolve = resolve

        @connection.on "message.pubsub.subscribed", @_subscribed
        @connection.on "message.pubsub.publish", @_publish
        @connection.send type: "pubsub.subscribe", id: @id, topic: @topic

        timeout = Math.round @timeout * 1000

        promise
        .timeout timeout, "Subscription request timed out."
        .catch TimeoutError, (error) =>
            @connection.removeListener "message.pubsub.subscribed", @_subscribed
            @connection.removeListener "message.pubsub.publish", @_publish

            throw error

    _subscribed: (message) => @_resolve() if message.id is @id

    _unsubscribe: =>
        return bluebird.resolve() unless @_isSubscribed

        @_isSubscribed = false

        @connection.send type: "pubsub.unsubscribe", id: @id
        @connection.removeListener "message.pubsub.subscribed", @_subscribed
        @connection.removeListener "message.pubsub.publish", @_publish

    _publish: (message) =>
        if @_pattern.test message.topic
            @emit "message", message.topic, message.payload
