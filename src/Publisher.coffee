module.exports = class Publisher

    constructor: (@connection) ->

    publish: (topic, payload) =>
        @connection.send type: "pubsub.publish", topic: topic, payload: payload
