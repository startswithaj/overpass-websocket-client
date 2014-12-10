module.exports = class WebSocketFactory

    constructor: (@webSocketClass = WebSocket) ->

    create: (url, protocols) -> new @webSocketClass url, protocols
