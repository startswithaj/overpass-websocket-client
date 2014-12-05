bluebird = require "bluebird"
require "../src/WebSocket"
Connection = require "../../src/Connection"
WebSocketFactory = require "../../src/WebSocketFactory"

describe "Connection", ->

    beforeEach ->
        @url = "http://example.org/"
        @webSocketFactory = jasmine.createSpyObj 'webSocketFactory', ['create']
        @subject = new Connection @url, @webSocketFactory

        @webSocket = jasmine.createSpyObj 'webSocket', ['send', 'close']
        @webSocketFactory.create.andReturn @webSocket

        @emittedErrors = []
        @subject.on "error", (error) => @emittedErrors.push error

        @request = a: 'b', c: 'd'

    it "stores the supplied dependencies", ->
        expect(@subject.url).toBe @url
        expect(@subject.webSocketFactory).toBe @webSocketFactory

    it "creates sensible default dependencies", ->
        @subject = new Connection @url

        expect(@subject.webSocketFactory).toEqual new WebSocketFactory()

    describe "connect()", ->

        describe "on success", ->

            beforeEach ->
                @connectPromise = @subject.connect @request
                @webSocket.onopen()

            it "creates a new websocket", (done) ->
                @connectPromise.then =>
                    expect(@webSocketFactory.create).toHaveBeenCalledWith @url
                    expect(@subject.connectionState).toBe WebSocket.OPEN
                    done()

            it "registers socket event handlers", (done) ->
                @connectPromise.then =>
                    expect(@webSocket.onclose).toBe @subject._close
                    expect(@webSocket.onmessage).toBe @subject._message
                    done()

            it "sends a handshake message", (done) ->
                @connectPromise.then =>
                    expect(@webSocket.send).toHaveBeenCalledWith \
                      '[{"type":"handshake.request","version":"1.0.0","request":{"a":"b","c":"d"}}]'
                    done()

        describe "on failure", ->

            beforeEach ->
                @connectPromise = @subject.connect @request
                @webSocket.onclose()

            it "rejects the promise", (done) ->
                @connectPromise.catch (error) =>
                    expect(error.message).toBe "Unable to connect to server."
                    expect(@subject.connectionState).toBe WebSocket.CLOSED
                    done()

        it "can connect concurrently", (done) ->
            @subject.connect @request
            @connectPromise = @subject.connect @request
            @webSocket.onopen()

            @connectPromise.then =>
                expect(@subject.connectionState).toBe WebSocket.OPEN
                done()
