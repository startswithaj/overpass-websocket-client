requireHelper = require "./require-helper"
Subscriber = requireHelper "Subscriber"

describe "Subscriber", ->

    beforeEach ->
        @connection = jasmine.createSpyObj "connection", ["on", "send"]
        @subject = new Subscriber @connection

    it "stores the supplied dependencies", ->
        expect(@subject.connection).toBe @connection

    describe "constructor()", ->

        it "listens for published messages", ->
            expect(@connection.on).toHaveBeenCalledWith "message.pubsub.publish", @subject._publish

    describe "subscribe()", ->

        beforeEach ->
            @subject.subscribe "topic.name"

        it "sends the correct message", ->
            expect(@connection.send).toHaveBeenCalledWith type: "pubsub.subscribe", topic: "topic.name"

    describe "unsubscribe()", ->

        beforeEach ->
            @subject.unsubscribe "topic.name"

        it "sends the correct message", ->
            expect(@connection.send).toHaveBeenCalledWith type: "pubsub.unsubscribe", topic: "topic.name"

    describe "publish message handling", ->

        it "emits generic message events", (done) ->
            @subject.on "message", (type, payload) ->
                expect(type).toBe "topic.name"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._publish
                type: "pubsub.publish"
                topic: "topic.name"
                payload: a: "b", c: "d"

        it "emits message events by topic", (done) ->
            @subject.on "message.topic.name", (type, payload) ->
                expect(type).toBe "topic.name"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._publish
                type: "pubsub.publish"
                topic: "topic.name"
                payload: a: "b", c: "d"

        it 'emits message events to "?" wildcard handler', (done) ->
            @subject.on "message.foo.?", (type, payload) ->
                expect(type).toBe "foo.bar"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._publish
                type: "pubsub.publish"
                topic: "foo.bar"
                payload: a: "b", c: "d"

        it 'does not emit message events to non-matching "?" wildcard handler', ->
            handler = jasmine.createSpy()
            @subject.on 'message.foo.?', handler
            @subject._publish
                type: "pubsub.publish"
                topic: "foo"
                payload: a: "b", c: "d"

            expect(handler).not.toHaveBeenCalled()

        it 'emits message events to "*" wildcard handler', (done) ->
            @subject.on "message.foo.*", (type, payload) ->
                expect(type).toBe "foo.bar.baz"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._publish
                type: "pubsub.publish"
                topic: "foo.bar.baz"
                payload: a: "b", c: "d"

        it 'does not emit message events to non-matching "*" wildcard handler', ->
            handler = jasmine.createSpy()
            @subject.on 'message.*.spam', handler
            @subject._publish
                type: "pubsub.publish"
                topic: "foo.bar.baz"
                payload: a: "b", c: "d"

            expect(handler).not.toHaveBeenCalled()

        it 'can still emit wildcard messages after handler is removed', ->
            pattern = 'message.foo.?'
            handler1 = jasmine.createSpy()
            handler2 = jasmine.createSpy()

            @subject.on pattern, handler1
            @subject.on pattern, handler2
            @subject.removeListener pattern, handler1

            @subject._publish
                type: "pubsub.publish"
                topic: "foo.bar"
                payload: a: "b", c: "d"

            expect(handler1.calls.length).toBe 0
            expect(handler2.calls.length).toBe 1

        it 'removes regexes when there are no wildcard handlers', (done) ->
            pattern = 'message.foo.?'
            handler1 = ->
            handler2 = ->

            @subject.on pattern, handler1
            @subject.on pattern, handler2

            expect(@subject._wildcardListeners[pattern]).toBeDefined()

            @subject.removeListener pattern, handler1
            @subject.removeListener pattern, handler2

            expect(@subject._wildcardListeners[pattern]).toBeUndefined()
            done()
