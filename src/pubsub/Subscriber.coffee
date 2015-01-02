Subscription = require "./Subscription"

module.exports = class Subscriber

    constructor: (@connection) -> @_id = 0

    subscribe: (topic) => new Subscription @connection, topic, ++@_id
