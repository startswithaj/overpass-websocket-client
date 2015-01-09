bluebird = require 'bluebird'
{Promise} = require 'bluebird'
InvalidMessageError = require './error/InvalidMessageError'
Request = require './message/Request'
Response = require './message/Response'
ResponseCode = require './message/ResponseCode'

module.exports = class RpcClient
    constructor: (@connection, @timeout = 3) ->
        @_requests = {}
        @_id = 0

        @connection.on "message.rpc.response", @_recv

    invoke: (name, args...) =>
        id = (++@_id).toString()
        request = new Request name, args

        @_send(request, id).then (response) => response.extract()

    invokeArray: (name, args) => @invoke name, args...

    _send: (request, id) =>
        promise = new Promise (resolve, reject) =>
            @_requests[id] = {resolve, reject}

            @connection.send
                type: "rpc.request"
                id: id
                name: request.name
                arguments: request.arguments

        timeout = Math.round @timeout * 1000

        promise
            .timeout timeout, 'RPC request timed out.'
            .finally => delete @_requests[id]

    _recv: (message) =>
        return if not message.id?

        return if not @_requests[message.id]?

        if not code = ResponseCode.get message.code
            error = new InvalidMessageError 'Response code is unrecognised.'
            @connection.close 4001, error.message

            return @_requests[message.id].reject error

        if code isnt ResponseCode.SUCCESS and typeof message.value isnt 'string'
            error = new InvalidMessageError 'Response error message must be a string.'
            @connection.close 4001, error.message

            return @_requests[message.id].reject error

        @_requests[message.id].resolve new Response code, message.value
