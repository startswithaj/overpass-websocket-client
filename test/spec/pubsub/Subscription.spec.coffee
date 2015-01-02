requireHelper = require "../require-helper"
Subscription = requireHelper "pubsub/Subscription"

describe "pubsub.Subscription", ->

    beforeEach ->
        @connection = jasmine.createSpyObj "connection", ["on", "removeListener", "send"]
        @topic = "a.*.b.?.c"
        @_id = 111
        @timeout = 222
        @subject = new Subscription @connection, @topic, @_id, @timeout

    it "stores the supplied dependencies", ->
        expect(@subject.connection).toBe @connection
        expect(@subject.topic).toBe @topic
        expect(@subject.id).toBe @_id
        expect(@subject.timeout).toBe @timeout

    it "creates sensible default dependencies", ->
        @subject = new Subscription @connection, @topic, @_id

        expect(@subject.timeout).toBe 10

    describe "enable()", ->

        it "subscribes to the appropriate topic", (done) ->
            @subject.enable().then =>
                expect(@connection.send).toHaveBeenCalledWith type: "pubsub.subscribe", id: @_id, topic: @topic
                done()

            setImmediate => @subject._subscribed id: @_id

        it "listens to the appropriate messages", (done) ->
            @subject.enable().then =>
                expect(@connection.on).toHaveBeenCalledWith "message.pubsub.subscribed", @subject._subscribed
                expect(@connection.on).toHaveBeenCalledWith "message.pubsub.publish", @subject._publish
                done()

            setImmediate => @subject._subscribed id: @_id

        it "honors the timeout", (done) ->
            @subject.timeout = .001
            @subject.enable().catch (error) =>
                expect(error.message).toBe "Subscription request timed out."
                done()

        it "ignores unrelated subscription confirmations", (done) ->
            @subject.enable().then => done()

            setImmediate =>
                @subject._subscribed id: 123
                @subject._subscribed id: @_id

        it "only subscribes once", (done) ->
            @subject.enable()
            .then =>
                @subject.enable()
            .then =>
                expect(@connection.send.calls.length).toBe 1
                done()

            setImmediate => @subject._subscribed id: @_id

    describe "disable()", ->

        it "unsubscribes from the appropriate ID", (done) ->
            @subject.enable()
            .then =>
                @subject.disable()
            .then =>
                expect(@connection.send).toHaveBeenCalledWith type: "pubsub.unsubscribe", id: @_id
                done()

            setImmediate => @subject._subscribed id: @_id

        it "removes the message event listeners", (done) ->
            @subject.enable()
            .then =>
                @subject.disable()
            .then =>
                expect(@connection.removeListener).toHaveBeenCalledWith \
                    "message.pubsub.subscribed",
                    @subject._subscribed
                expect(@connection.removeListener).toHaveBeenCalledWith "message.pubsub.publish", @subject._publish
                done()

            setImmediate => @subject._subscribed id: @_id

        it "only unsubscribes once", (done) ->
            @subject.enable()
            .then =>
                @subject.disable()
            .then =>
                @subject.disable()
            .then =>
                expect(@connection.send.calls.length).toBe 2
                done()

            setImmediate => @subject._subscribed id: @_id

    describe "_publish()", ->

        it "emits message events", (done) ->
            @subject.on "message", (topic, payload) =>
                expect(topic).toBe "a.x.y.b.z.c"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._publish
                topic: "a.x.y.b.z.c"
                payload: a: "b", c: "d"

        it "ignores unrelated messages", (done) ->
            @subject.on "message", (topic, payload) =>
                expect(topic).toBe "a.x.y.b.z.c"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._publish
                topic: "a.x.b.y.z.c"
                payload: "ignore"
            @subject._publish
                topic: "a.x.y.b.z.c"
                payload: a: "b", c: "d"
