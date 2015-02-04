bluebird = require "bluebird"
require "../../src/WebSocket"
requireHelper = require '../require-helper'
Connection = requireHelper "connection/Connection"
WebSocketFactory = requireHelper "connection/WebSocketFactory"

describe "connection.Connection", ->

    beforeEach ->
        @url = "http://example.org/"
        @connectTimeout = 111
        @webSocketFactory = jasmine.createSpyObj 'webSocketFactory', ['create']
        @subject = new Connection @url, @connectTimeout, @webSocketFactory

        @webSocket = jasmine.createSpyObj 'webSocket', ['send', 'close']
        @webSocketFactory.create.andReturn @webSocket

        @emittedDisconnects = []
        @subject.on "disconnect", => @emittedDisconnects.push arguments

        @request = a: 'b', c: 'd'

    it "stores the supplied dependencies", ->
        expect(@subject.url).toBe @url
        expect(@subject.connectTimeout).toBe @connectTimeout
        expect(@subject.webSocketFactory).toBe @webSocketFactory

    it "creates sensible default dependencies", ->
        @subject = new Connection @url

        expect(@subject.connectTimeout).toBe 3
        expect(@subject.webSocketFactory).toEqual new WebSocketFactory()

    describe "connect()", ->

        describe "on success", ->

            beforeEach (done) ->
                @connectPromise = @subject.connect @request
                setImmediate =>
                    @webSocket.onopen()
                    @webSocket.onmessage data: '{"type":"handshake.approve","response":"responseValue"}'
                    @connectPromise.then -> done()

            it "creates a new websocket", ->
                expect(@webSocketFactory.create).toHaveBeenCalledWith @url
                expect(@subject._state.isOn).toBe true

            it "registers socket event handlers", ->
                expect(@webSocket.onclose).toBe @subject._close
                expect(@webSocket.onmessage).toBe @subject._message

            it "sends a handshake message", ->
                expect(@webSocket.send).toHaveBeenCalledWith \
                  '{"type":"handshake.request","version":"1.0.0","request":{"a":"b","c":"d"}}'

        describe "on failure", ->

            it "rejects the promise", (done) ->
                @subject.connect(@request)
                .catch (error) =>
                    expect(error.message).toBe "Unable to connect to server."
                    expect(@subject._state.isOn).toBe false
                    done()

                setImmediate =>
                    @webSocket.onclose code: 111, reason: 'reason'
                    done()

        it "defaults to an empty request", (done) ->
            @connectPromise = @subject.connect()

            setImmediate =>
                @webSocket.onopen()

                expect(@webSocket.send).toHaveBeenCalledWith \
                  '{"type":"handshake.request","version":"1.0.0","request":{}}'
                done()

        it "can connect concurrently", (done) ->
            @subject.connect @request
            @connectPromise = @subject.connect @request

            setImmediate =>
                @webSocket.onopen()
                @webSocket.onmessage data: '{"type":"handshake.approve","response":"responseValue"}'

            @connectPromise.then =>
                expect(@subject._state.isOn).toBe true
                done()

        it "can connect sequentially", (done) ->
            @connectPromise = @subject.connect @request

            setImmediate =>
                @webSocket.onopen()
                @webSocket.onmessage data: '{"type":"handshake.approve","response":"responseValue"}'

            @connectPromise.then =>
                @subject.connect @request
            .then =>
                expect(@subject._state.isOn).toBe true
                done()

        it "handles handshake rejections", (done) ->
            @subject.connect(@request).catch (error) ->
                expect(error.message).toBe "reasonValue"
                done()

            setImmediate =>
                @webSocket.onopen()
                @webSocket.onmessage data: '{"type":"handshake.reject","reason":"reasonValue"}'

        it "handles handshake timouts", (done) ->
            @subject.connectTimeout = .001
            @subject.connect(@request).catch (error) =>
                expect(error.message).toBe "Connection timed out."
                expect(@webSocket.close).toHaveBeenCalledWith 4001, "Connection handshake timed out."
                done()

        it "handles handshake disonnects", (done) ->
            @subject.connect(@request).catch (error) =>
                expect(error.message).toBe "Unable to connect to server."
                done()

            setImmediate =>
                @webSocket.onopen()

                setImmediate =>
                    @webSocket.onclose()

    describe "disconnect()", ->

        it "does nothing when already disconnected", (done) ->
            @subject.disconnect().then =>
                expect(@subject._state.isOn).toBe false
                done()

        describe "after connecting", ->

            beforeEach (done) ->
                @connectPromise = @subject.connect @request
                @connectPromise.then -> done()

                setImmediate =>
                    @webSocket.onopen()
                    @webSocket.onmessage data: '{"type":"handshake.approve","response":"responseValue"}'

            it "can disconnect", (done) ->
                @disconnectPromise = @subject.disconnect()
                @disconnectPromise.then =>
                    setImmediate =>
                        expect(@subject._state.isOn).toBe false
                        expect(@emittedDisconnects).toEqual [[1000, "Connection terminated by client."]]
                        done()

            it "can disconnect concurrently", (done) ->
                @subject.disconnect()
                @disconnectPromise = @subject.disconnect()
                @disconnectPromise.then =>
                    setImmediate =>
                        expect(@emittedDisconnects).toEqual [[1000, "Connection terminated by client."]]
                        done()

            it "can disconnect sequentially", (done) ->
                @disconnectPromise = @subject.disconnect()
                @disconnectPromise.then => @subject.disconnect()
                .then =>
                    setImmediate =>
                        expect(@emittedDisconnects).toEqual [[1000, "Connection terminated by client."]]
                        done()

    describe "after successfully connecting", ->

        beforeEach (done) ->
            @connectPromise = @subject.connect @request
            @connectPromise.then -> done()

            setImmediate =>
                @webSocket.onopen()
                @webSocket.onmessage data: '{"type":"handshake.approve","response":"responseValue"}'

        it "emits generic messages", (done) ->
            @subject.on "message", (message) ->
                expect(message).toEqual type: "a", b: ["c", "d"]
                done()

            @webSocket.onmessage data: '{"type":"a","b":["c","d"]}'

        it "emits messages with type", (done) ->
            @subject.on "message.a", (message) ->
                expect(message).toEqual type: "a", b: ["c", "d"]
                done()

            @webSocket.onmessage data: '{"type":"a","b":["c","d"]}'
