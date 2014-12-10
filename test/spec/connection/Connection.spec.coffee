bluebird = require "bluebird"
require "../../src/WebSocket"
requireHelper = require '../require-helper'
Connection = requireHelper "connection/Connection"
WebSocketFactory = requireHelper "connection/WebSocketFactory"

describe "connection.Connection", ->

    beforeEach ->
        @url = "http://example.org/"
        @webSocketFactory = jasmine.createSpyObj 'webSocketFactory', ['create']
        @subject = new Connection @url, @webSocketFactory

        @webSocket = jasmine.createSpyObj 'webSocket', ['send', 'close']
        @webSocketFactory.create.andReturn @webSocket

        @emittedErrors = []
        @subject.on "error", (error) => @emittedErrors.push error

        @emittedDisconnects = []
        @subject.on "disconnect", => @emittedDisconnects.push arguments

        @request = a: 'b', c: 'd'

    it "stores the supplied dependencies", ->
        expect(@subject.url).toBe @url
        expect(@subject.webSocketFactory).toBe @webSocketFactory

    it "creates sensible default dependencies", ->
        @subject = new Connection @url

        expect(@subject.webSocketFactory).toEqual new WebSocketFactory()

    describe "connect()", ->

        describe "on success", ->

            beforeEach (done) ->
                @connectPromise = @subject.connect @request
                @webSocket.onopen()
                @connectPromise.then done

            it "creates a new websocket", ->
                expect(@webSocketFactory.create).toHaveBeenCalledWith @url
                expect(@subject._connectionState).toBe WebSocket.OPEN

            it "registers socket event handlers", ->
                expect(@webSocket.onclose).toBe @subject._close
                expect(@webSocket.onmessage).toBe @subject._message

            it "sends a handshake message", ->
                expect(@webSocket.send).toHaveBeenCalledWith \
                  '[{"type":"handshake.request","version":"1.0.0","request":{"a":"b","c":"d"}}]'

        describe "on failure", ->

            beforeEach ->
                @connectPromise = @subject.connect @request
                @webSocket.onclose code: 111, reason: 'reason'

            it "rejects the promise", (done) ->
                @connectPromise.catch (error) =>
                    expect(error.message).toBe "Unable to connect to server."
                    expect(@subject._connectionState).toBe WebSocket.CLOSED
                    done()

        it "defaults to an empty request", (done) ->
            @connectPromise = @subject.connect()
            @webSocket.onopen()

            @connectPromise.then =>
                expect(@webSocket.send).toHaveBeenCalledWith \
                  '[{"type":"handshake.request","version":"1.0.0","request":{}}]'
                done()

        it "can connect concurrently", (done) ->
            @subject.connect @request
            @connectPromise = @subject.connect @request
            @webSocket.onopen()

            @connectPromise.then =>
                expect(@subject._connectionState).toBe WebSocket.OPEN
                done()

        it "can connect sequentially", (done) ->
            @connectPromise = @subject.connect @request
            @webSocket.onopen()

            @connectPromise.then =>
                @subject.connect @request
            .then =>
                expect(@subject._connectionState).toBe WebSocket.OPEN
                done()

        it "can connect while closing", (done) ->
            @connectPromise = @subject.connect @request
            @webSocket.onopen()

            @connectPromise.then =>
                @subject.disconnect()
                @connectPromise = @subject.connect @request
                @webSocket.onclose code: 111, reason: 'reason'
                setImmediate =>
                    @webSocket.onopen()
                    @connectPromise.then =>
                        expect(@subject._connectionState).toBe WebSocket.OPEN
                        done()

    describe "disconnect()", ->

        it "does nothing when already disconnected", (done) ->
            @subject.disconnect().then =>
                expect(@subject._connectionState).toBe WebSocket.CLOSED
                done()

        describe "after connecting", ->

            beforeEach (done) ->
                @connectPromise = @subject.connect @request
                @webSocket.onopen()
                @connectPromise.then done

            it "can disconnect", (done) ->
                @disconnectPromise = @subject.disconnect()
                @webSocket.onclose code: 111, reason: 'reason'

                @disconnectPromise.then =>
                    expect(@subject._connectionState).toBe WebSocket.CLOSED
                    expect(@emittedDisconnects).toEqual [[111, 'reason']]
                    done()

            it "can disconnect concurrently", (done) ->
                @subject.disconnect()
                @disconnectPromise = @subject.disconnect()
                @webSocket.onclose code: 111, reason: 'reason'

                @disconnectPromise.then =>
                    expect(@subject._connectionState).toBe WebSocket.CLOSED
                    expect(@emittedDisconnects).toEqual [[111, 'reason']]
                    done()

            it "can disconnect sequentially", (done) ->
                @disconnectPromise = @subject.disconnect()
                @webSocket.onclose code: 111, reason: 'reason'

                @disconnectPromise.then =>
                    @subject.disconnect()
                .then =>
                    expect(@subject._connectionState).toBe WebSocket.CLOSED
                    expect(@emittedDisconnects).toEqual [[111, 'reason']]
                    done()

        it "can disconnect while connecting", (done) ->
            @subject.connect @request
            @disconnectPromise = @subject.disconnect()
            @webSocket.onopen()
            setImmediate =>
                @webSocket.onclose code: 111, reason: 'reason'

                @disconnectPromise.then =>
                    expect(@subject._connectionState).toBe WebSocket.CLOSED
                    done()

    describe "after successfully connecting", ->

        beforeEach (done) ->
            @connectPromise = @subject.connect @request
            @webSocket.onopen()
            @connectPromise.then done

        it "handles handshake approvals", (done) ->
            @subject.on "connect", (response) ->
                expect(response).toBe "responseValue"
                done()

            @webSocket.onmessage data: '[{"type":"handshake.approve","response":"responseValue"}]'

        it "handles handshake rejections", (done) ->
            @subject.on "error", (reason) ->
                expect(reason).toBe "reasonValue"
                done()

            @webSocket.onmessage data: '[{"type":"handshake.reject","reason":"reasonValue"}]'

        it "handles valid messages", (done) ->
            @subject.on "message.a", (message) ->
                expect(message).toEqual type: "a", b: ["c", "d"]
                done()

            @webSocket.onmessage data: '[{"type":"a","b":["c","d"]}]'

        it "handles invalid messages", (done) ->
            @subject.on "error", (error) =>
                expect(error.message).toEqual 'Unexpected RIGHT_BRACKET("]") in state KEY'
                expect(@subject._connectionState).toBe WebSocket.CLOSED
                expect(@webSocket.close).toHaveBeenCalledWith 4001, "Invalid message received."
                done()

            @webSocket.onmessage data: '[{]'

