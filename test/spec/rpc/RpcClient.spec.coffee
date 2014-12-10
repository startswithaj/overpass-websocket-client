requireHelper = require "../require-helper"
RpcClient = requireHelper "rpc/RpcClient"

describe "rpc.RpcClient", ->

    beforeEach ->
        @connection = jasmine.createSpyObj "connection", ["on", "send", "close"]
        @timeout = 111
        @subject = new RpcClient @connection, @timeout

    it "stores the supplied dependencies", ->
        expect(@subject.connection).toBe @connection
        expect(@subject.timeout).toBe @timeout

    it "creates sensible default dependencies", ->
        @subject = new RpcClient @connection

        expect(@subject.timeout).toBe 10

    describe "constructor()", ->

        it "listens for incoming responses", ->
            expect(@connection.on).toHaveBeenCalledWith "message.rpc.response", @subject._recv

    describe "invoke()", ->

        it "sends the correct message", (done) ->
            @subject.invoke("procedureName", "a", "b")
            .then (result) =>
                expect(@connection.send).toHaveBeenCalledWith
                    type: "rpc.request"
                    id: "1"
                    name: "procedureName"
                    arguments: ["a", "b"]
                expect(result).toBe "resultValue"
                done()

            setImmediate =>
                @subject._recv
                    type: "rpc.response"
                    id: "1"
                    code: "SUCCESS"
                    value: "resultValue"

        it "handles calls without arguments", (done) ->
            @subject.invoke("procedureName")
            .then (result) =>
                expect(@connection.send).toHaveBeenCalledWith
                    type: "rpc.request"
                    id: "1"
                    name: "procedureName"
                    arguments: []
                done()

            setImmediate =>
                @subject._recv
                    type: "rpc.response"
                    id: "1"
                    code: "SUCCESS"
                    value: "resultValue"

        it "propagates errors", (done) ->
            @subject.invoke("procedureName", "a", "b")
            .catch (error) =>
                expect(error.constructor.name).toBe "ExecutionError"
                expect(error.message).toBe "Error message."
                done()

            setImmediate =>
                @subject._recv
                    type: "rpc.response"
                    id: "1"
                    code: "ERROR"
                    value: "Error message."

        it "handles invalid response codes", (done) ->
            @subject.invoke("procedureName", "a", "b")
            .catch (error) =>
                expect(error.constructor.name).toBe "InvalidMessageError"
                expect(error.message).toBe "Response code is unrecognised."
                expect(@connection.close).toHaveBeenCalled()
                done()

            setImmediate =>
                @subject._recv
                    type: "rpc.response"
                    id: "1"
                    code: "NONEXISTENT"
                    value: "Error message."

        it "handles invalid response codes", (done) ->
            @subject.invoke("procedureName", "a", "b")
            .catch (error) =>
                expect(error.constructor.name).toBe "InvalidMessageError"
                expect(error.message).toBe "Response error message must be a string."
                expect(@connection.close).toHaveBeenCalled()
                done()

            setImmediate =>
                @subject._recv
                    type: "rpc.response"
                    id: "1"
                    code: "ERROR"
                    value: 111

        it "handles timeouts", (done) ->
            @subject.timeout = .001
            @subject.invoke("procedureName", "a", "b")
            .catch (error) =>
                expect(error.message).toBe "RPC request timed out."
                done()

    describe "invokeArray()", ->

        it "proxies arguments to invoke()", (done) ->
            @subject.invokeArray("procedureName", ["a", "b"])
            .then (result) =>
                expect(@connection.send).toHaveBeenCalledWith
                    type: "rpc.request"
                    id: "1"
                    name: "procedureName"
                    arguments: ["a", "b"]
                expect(result).toBe "resultValue"
                done()

            setImmediate =>
                @subject._recv
                    type: "rpc.response"
                    id: "1"
                    code: "SUCCESS"
                    value: "resultValue"

    describe "response handling", ->

        it "ignores responses with no ID", ->
            @subject._recv type: "bogus"

        it "ignores responses with unmatched IDs", ->
            @subject._recv id: "bogus", type: "bogus"
