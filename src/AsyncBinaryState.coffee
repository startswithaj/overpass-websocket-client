Promise = require "bluebird"

module.exports = class AsyncBinaryState

    constructor: (@isOn = false) ->
        @_targetState = @isOn
        @_promise = Promise.resolve()

    setOn: (handler) => @set true, handler

    setOff: (handler) => @set false, handler

    set: (isOn, handler) =>
        callback = => @_set isOn, handler
        @_promise = @_promise.then callback, callback

    _set: (isOn, handler) =>
        return Promise.resolve() if isOn is @_targetState

        @_targetState = isOn

        if handler?
            method = Promise.method -> handler()
        else
            method = -> Promise.resolve()

        method()
        .tap => @isOn = isOn
        .catch (error) =>
            @_targetState = not isOn

            throw error
