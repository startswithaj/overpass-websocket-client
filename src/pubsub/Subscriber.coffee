Subscription = require "./Subscription"

module.exports = class Subscriber

    constructor: (@connection, @timeout = 3) -> @_id = 0

    subscribe: (topic) => new Subscription @connection, topic, ++@_id, @timeout
