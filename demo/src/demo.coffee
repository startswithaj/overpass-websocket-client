overpass = require "../../src"
Connection = overpass.connection.Connection
Publisher = overpass.pubsub.Publisher
Subscriber = overpass.pubsub.Subscriber

$ ->
    form   = $ "#inputForm"
    input  = $ "#input"
    output = $ "#output"

    url = "ws://#{window.location.hostname}:8080"
    connection = new Connection url

    publisher  = new Publisher  connection
    subscriber = new Subscriber connection

    print = (text) ->
        div = $ "<div>"
        div.text text
        output.append div
        output.scrollTop output[0].scrollHeight

        if output.find("*").length > 50
            output.find(":first-child").remove()

    connect = ->
        print "* connecting"
        connection
            .connect foo: "bar"
            .catch (error) ->
                print "* unable to connect to #{url} (#{error})"
                reconnect()

    reconnect = ->
        print "* reconnecting in 5 seconds"
        setTimeout connect, 5000

    input.focus()

    connection.on "connect", ->
        print "* connected"

        subscription = subscriber.subscribe "*"
        subscription.on "message", (topic, payload) ->
            print "<#{topic}> #{JSON.stringify payload}"
        subscription.enable()

    connection.on "error", (message) ->
        print "* error: #{message}"
        reconnect()

    connection.on "disconnect", (code, reason)->
        print "* disconnected: #{code} #{reason}"
        reconnect()

    form.submit (e) ->
        e.preventDefault()
        publisher.publish "websocket", text: input.val()
        input.val ""

    connect()
