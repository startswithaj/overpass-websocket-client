bluebird = require "bluebird"
EventEmitter = require "node-event-emitter"
regexEscape = require "escape-string-regexp"
{Promise} = require "bluebird"

module.exports = class Subscription extends EventEmitter

    constructor: (@connection, @topic, @id, @timeout = 10) ->
        @_subscriber = bluebird.resolve()

        atoms = for atom in topic.split "."
            switch atom
                when "*"
                    "(.+)"
                when "?"
                    "([^.]+)"
                else
                    regexEscape atom

        @_pattern = new RegExp "^#{atoms.join regexEscape "."}$"

        @connection.on "message.pubsub.subscribed", @_subscribed
        @connection.on "message.pubsub.publish", @_publish

    enable: -> @_subscriber = @_subscriber.then @_subscribe, @_subscribe

    disable: -> @_subscriber = @_subscriber.then @_unsubscribe, @_unsubscribe

    _subscribe: =>
        promise = new Promise (resolve) => @_resolve = resolve

        @connection.send type: "pubsub.subscribe", id: @id, topic: @topic

        timeout = Math.round @timeout * 1000

        promise.timeout timeout, "Subscription request timed out."

    _subscribed: (message) => @_resolve() if message.id is @id

    _unsubscribe: => @connection.send type: "pubsub.unsubscribe", id: @id

    _publish: (message) =>
        if @_pattern.test message.topic
            @emit "message", message.topic, message.payload
