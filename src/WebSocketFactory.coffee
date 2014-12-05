module.exports = class WebSocketFactory

    constructor: (@webSocketClass = WebSocket) ->

    create: -> new @webSocketClass arguments...
