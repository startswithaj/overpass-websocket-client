require "../src/WebSocket"
requireHelper = require './require-helper'
WebSocketFactory = requireHelper "WebSocketFactory"

describe "WebSocketFactory", ->

    beforeEach ->
        @webSocketClass = class
          constructor: -> @constructorArguments = arguments
        @subject = new WebSocketFactory @webSocketClass

    it "stores the supplied dependencies", ->
        expect(@subject.webSocketClass).toBe @webSocketClass

    it "creates sensible default dependencies", ->
        @subject = new WebSocketFactory()

        expect(@subject.webSocketClass).toBe WebSocket

    describe "create()", ->

      it "passes arguments to the web socket class constructor", ->
        actual = @subject.create "a", "b"

        expect(actual.constructorArguments).toEqual ["a", "b"]
