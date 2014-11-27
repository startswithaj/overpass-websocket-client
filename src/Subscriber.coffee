EventEmitter = require 'node-event-emitter'

module.exports = class Subscriber extends EventEmitter

    constructor: (@connection) ->
        @connection.on 'pubsub.publish', @_onPublish

    subscribe: (topic) =>
        @connection.send \
            type: 'pubsub.subscribe',
            topic: topic,

    unsubscribe: (topic) =>
        @connection.send \
            type: 'pubsub.unsubscribe',
            topic: topic,

    _onPublish: (message) =>
        @emit "message", message.topic, message.payload
        @emit "message.#{message.topic}", message.topic, message.payload
