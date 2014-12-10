EventEmitter = require "node-event-emitter"
regexEscape = require "escape-string-regexp"

module.exports = class Subscriber extends EventEmitter

    constructor: (@connection) ->
        @_wildcardListeners = {}

        @on "newListener", @_onNewListener
        @on "removeListener", @_onRemoveListener
        @connection.on "message.pubsub.publish", @_publish

    subscribe: (topic) =>
        @connection.send type: "pubsub.subscribe", topic: topic

    unsubscribe: (topic) =>
        @connection.send type: "pubsub.unsubscribe", topic: topic

    _publish: (message) =>
        @emit "message", message.topic, message.payload
        @emit "message.#{message.topic}", message.topic, message.payload

        for event, regex of @_wildcardListeners
            if regex.test message.topic
                @emit event, message.topic, message.payload

    _onNewListener: (event, listener) =>
        return if event of @_wildcardListeners

        atoms = event.split "."

        return unless atoms.shift() is "message"

        isPattern = false
        atoms = for atom in atoms
            switch atom
                when "*"
                    isPattern = true
                    "(.+)"
                when "?"
                    isPattern = true
                    "([^.]+)"
                else
                    regexEscape atom

        if isPattern
            @_wildcardListeners[event] =
                new RegExp "^#{atoms.join regexEscape "."}$"

    _onRemoveListener: (event, listener) =>
        unless EventEmitter.listenerCount @, event
            delete @_wildcardListeners[event]
