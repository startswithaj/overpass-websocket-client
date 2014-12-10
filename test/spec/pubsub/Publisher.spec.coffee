requireHelper = require '../require-helper'
Publisher = requireHelper "pubsub/Publisher"

describe "pubsub.Publisher", ->

    beforeEach ->
        @connection = jasmine.createSpyObj 'connection', ['send']
        @subject = new Publisher @connection

    it "stores the supplied dependencies", ->
        expect(@subject.connection).toBe @connection

    describe "publish()", ->

        it "sends the correct message", ->
            @connection.send.andReturn 'result'
            topic = 'topic.name'
            payload = a: "b", c: "d"

            expect(@subject.publish topic, payload).toBe 'result'
            expect(@connection.send).toHaveBeenCalledWith
                type: "pubsub.publish"
                topic: topic
                payload: payload
