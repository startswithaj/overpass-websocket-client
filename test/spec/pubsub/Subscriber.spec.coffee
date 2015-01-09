requireHelper = require "../require-helper"
Subscriber = requireHelper "pubsub/Subscriber"
Subscription = requireHelper "pubsub/Subscription"

describe "pubsub.Subscriber", ->

    beforeEach ->
        @connection = jasmine.createSpyObj "connection", ["on"]
        @timeout = 111
        @subject = new Subscriber @connection, @timeout

    it "stores the supplied dependencies", ->
        expect(@subject.connection).toBe @connection
        expect(@subject.timeout).toBe @timeout

    describe "subscribe()", ->

        it "creates subscriptions with the correct topic", ->
            @subscription = @subject.subscribe "topic"

            expect(@subscription.topic).toBe "topic"

        it "passes the correct dependencies", ->
            @subscription = @subject.subscribe "topic"

            expect(@subscription.connection).toBe @connection
            expect(@subscription.timeout).toBe @timeout

        it "creates subscription objects with sequential IDs", ->
            @subscriptionA = @subject.subscribe "topic"
            @subscriptionB = @subject.subscribe "topic"

            expect(@subscriptionB.id).toBeGreaterThan @subscriptionA.id
