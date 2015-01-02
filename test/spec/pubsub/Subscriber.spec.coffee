requireHelper = require "../require-helper"
Subscriber = requireHelper "pubsub/Subscriber"
Subscription = requireHelper "pubsub/Subscription"

describe "pubsub.Subscriber", ->

    beforeEach ->
        @connection = jasmine.createSpyObj "connection", ["on"]
        @subject = new Subscriber @connection

    it "stores the supplied dependencies", ->
        expect(@subject.connection).toBe @connection

    describe "subscribe()", ->

        it "creates subscriptions with the correct topic", ->
            @subscription = @subject.subscribe "topic"

            expect(@subscription.topic).toBe "topic"

        it "passes the corret dependencies", ->
            @subscription = @subject.subscribe "topic"

            expect(@subscription.connection).toBe @connection

        it "creates subscription objects with sequential IDs", ->
            @subscriptionA = @subject.subscribe "topic"
            @subscriptionB = @subject.subscribe "topic"

            expect(@subscriptionB.id).toBeGreaterThan @subscriptionA.id
