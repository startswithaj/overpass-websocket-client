module.exports = class RpcClient

    constructor: (@connection) ->

    invoke: (name, args...) =>
        return @invokeArray name, args

    invokeArray: (name, args) =>
        @connection.send \
            type: "rpc.request",
            name: name,
            arguments: arguments,
