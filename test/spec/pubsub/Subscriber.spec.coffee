requireHelper = require "../require-helper"
Subscriber = requireHelper "pubsub/Subscriber"
Subscription = requireHelper "pubsub/Subscription"

describe "pubsub.Subscriber", ->

    beforeEach ->
        @connection = jasmine.createSpyObj "connection", ["on"]
        @subject = new Subscriber @connection

    it "stores the supplied dependencies", ->
        expect(@subject.connection).toBe @connection

    describe "create()", ->

        it "creates subscriptions with the correct topic", ->
            @subscription = @subject.create "topic"

            expect(@subscription.topic).toBe "topic"

        it "passes the corret dependencies", ->
            @subscription = @subject.create "topic"

            expect(@subscription.connection).toBe @connection

        it "creates subscription objects with sequential IDs", ->
            @subscriptionA = @subject.create "topic"
            @subscriptionB = @subject.create "topic"

            expect(@subscriptionB.id).toBeGreaterThan @subscriptionA.id
