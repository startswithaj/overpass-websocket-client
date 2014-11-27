Connection = require '../../src/Connection'
Publisher = require '../../src/Publisher'
Subscriber = require '../../src/Subscriber'

$ ->
    form   = $ '#inputForm'
    input  = $ '#input'
    output = $ '#output'

    connection = new Connection 'ws://192.168.60.36:8765'

    publisher  = new Publisher  connection
    subscriber = new Subscriber connection

    subscriber.on 'message', (topic, payload) ->
        print "<#{topic}> #{JSON.stringify payload}"

    print = (text) ->
        div = $ '<div>'
        div.text text
        output.append div
        output.scrollTop output[0].scrollHeight

        if output.find('*').length > 50
            output.find(':first-child').remove()

    connect = ->
        print '* connecting'
        connection.connect()

    reconnect = ->
        print "* reconnecting in 5 seconds"
        setTimeout connect, 5000

    input.focus()

    connection.on 'connect', ->
        print '* connected'
        subscriber.subscribe '*'

    connection.on 'error', ->
        print "* unable to connect"
        reconnect()

    connection.on 'disconnect', (code, reason)->
        print "* disconnected: #{code} #{reason}"
        reconnect()

    form.submit (e) ->
        e.preventDefault()
        publisher.publish 'websocket', text: input.val()
        input.val ''

    connect()