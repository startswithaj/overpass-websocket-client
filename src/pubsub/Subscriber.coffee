Subscription = require "./Subscription"

module.exports = class Subscriber

    constructor: (@connection) -> @_id = 0

    create: (topic) => new Subscription @connection, topic, ++@_id
