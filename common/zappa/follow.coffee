ccnq3 = require 'ccnq3'
url = require 'url'
pico = require 'pico'

@include = ->

  mw = [
    @express.cookieParser()
    @express.cookieSession secret: 'a'+Math.random()
  ]

  @get '/_ccnq3/follow', mw, ->
    ccnq3.config (config) =>
      # Stolen from pico
      parsed = url.parse config.provisioning.couchdb_uri
      parsed.auth = [@req.user, @req.pass].join(':')
      # Normally not needed in recent Node.js
      delete parsed.href
      delete parsed.host
      # Automagically shared with Socket.IO as long
      # as the client uses zappa.js
      @session.uri = url.format parsed
    @render 'follow'

  @client '/_ccnq3/follow/main.js', ->
    @connect()

    $ =>
      @on cdrs: (doc) ->
        $('#output').append "New cdr: #{@data.doc}"

      @on provisioning: (doc) ->
        $('#output').append "New provisioing: #{@data.doc}"

      @emit follow: 'cdrs'

  @view follow: ->
    doctype 5
    html ->
      head ->
        meta charset: 'utf-8'
        title 'Follow'
        link rel:'stylesheet', href:'/_ccnq3/follow/index.css', type:'text/css'
        script type:'text/javascript', src:'/_ccnq3/zappa/Zappa-simple.js'
        # and our stuff:
        script type:'text/javascript', src:'/_ccnq3/follow/main.js'

      body ->

        div ->
          input id:'follow_numbers', type:'checkbox', checked:true
          label for:'follow_numbers', 'Numbers'
          input id:'follow_endpoints', type:'checkbox', checked:true
          label for:'follow_endpoints', 'Endpoints'
          input id:'follow_locations', type:'checkbox', checked:true
          label for:'follow_locations', 'Locations'

        div id:'output'

  pool = {}

  @helper follow: (name) ->
    if pool[name]
      return pool[name]

    @session (error,session) ->

      db = pico session.uri + '/' + name

      pool[name] = db

      # Retrieve the last_seq number to start there.
      qs =
        descending: true
        limit: 1
        style: 'main_only'
        feed: normal
      db.get '/_changes', {qs}, (e,r,b) ->
        if e? then return @json error:e
        last_seq = b.results.last_seq

        # Start monitoring changes.
        db.monitor since:last_seq, (doc) ->
          @broadcast_to name, doc

      return

  @on 'follow', (name) ->
    @follow name
    @join name
