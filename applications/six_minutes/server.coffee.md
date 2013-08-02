Overview
========

`6minutes` is an application that listen to the CDRs (aggregation) changes and generates per-6-minutes (deci-hour) reports of what happened during that hour. Data is kept in memory (for the past 24 hours) and can be retrieved using the Web API.

It focuses on troubleshooting:
- report call issues with carriers (zero-duration call ratio, unexpected SIP error reports, etc.)
- report per-account issues

Data is generated via plugins; plugins can be added in the plugins directory to create new statistics.

There are two inter-twined processes. One is the web service

    service = ->

      year = 365*24*3600*1000
      @use 'logger', 'cookieParser', session:{secret:'a'+Math.random(), cookie: { maxAge: year }}

while the other one is the data gathering (and plugins). Since that one can be controlled by the web service, it is actually started from within the web service.

      plugins = []

      gather = ->

        source_uri = config.aggregate?.cdrs_uri
        source = ccnq3.db.couch source_uri
        changes source_uri, source, (doc) ->

Using the end-of-call timestamp, determine which 6-minutes window is concerned.
(Expressed as seconds.)

          end_epoch = parseInt doc.variables.end_epoch
          timestamp = end_epoch - end_epoch % 360

Each plugin is actually a standalone callback for a CDR document.

          for plugin in plugins
            plugin doc, timestamp

          return

Actually the plugins might gather statistics, trigger alerts, etc.

      plugin_directory = './plugins'

      data = {}
      alerts = []

      load_plugins = =>

        new_plugins = []

        fs.readdir plugin_directory, (err,files) =>
          if err
            console.error "Could not read #{plugin_directory}"
            process.exit 1
          for filename in files when filename.match /\.js$/
            do (filename) =>
              src = require('./' + path.join plugin_directory, filename)
              new_plugins.push (doc,timestamp) =>

Plugins consist of a `@plugin` function which is evaluated in the context of:
- `@doc` the original document
- `@timestamp` the timestamp
- `@alert(msg)` -- socket.io alert in the `alert_room`
- `@increment(name,number)`

                ctx =
                  doc: doc
                  profile: doc.variables?.ccnq_profile
                  direction: doc.variables?.ccnq_direction
                  account: doc.variables?.ccnq_account
                  duration:
                    billable: parseInt doc.variables?.billsec
                    total: parseInt doc.variables?.duration
                  from: doc.variables?.ccnq_from_e164
                  to: doc.variables?.ccnq_to_e164
                  timestamp: timestamp
                  alert: (msg) =>
                    alert =
                      msg:msg
                      doc:doc
                      timestamp:timestamp
                      profile: ctx.profile
                      direction: ctx.direction
                      account: ctx.account
                      duration: ctx.duration
                    # @io.sockets.in(alert_room).emit 'alert', alert
                    @io.sockets.emit 'alert', alert
                    alerts.push alert
                  increment: (name,value = 1) =>
                    data[timestamp] ?= {}
                    rec = data[timestamp][name]
                    if rec?
                      rec.sum += value
                      rec.count++
                      rec.squares += value*value
                      rec.max = value if value > rec.max
                      rec.min = value if value < rec.min
                    else
                      rec =
                        sum: value
                        max: value
                        min: value
                        count: 1
                        squares: value*value
                      data[timestamp][name] = rec
                    id = name.replace /[^a-zA-Z]+/g, '_'
                    stats =
                      timestamp: timestamp
                      name: id
                      label: name
                      data: rec
                    # @io.sockets.in(stats_room).emit 'stats', stats
                    @io.sockets.emit 'stats', stats

                src.plugin.apply ctx

Update the plugins list at once

          plugins = new_plugins

      # @enable 'minify'

      @post '/6minutes/restart', ->
        do load_plugins
        @json ok:true

      @get '/6minutes', ->
        @render 'default'

      @get '/6minutes/alerts', ->
        @json alerts

      @get '/6minutes/data', ->
        @json data

      @del '/6minutes/alerts', ->
        # FIXME instead of erasing, purge based on timestamp
        alerts = []
        @json ok:true

      @del '/6minutes/data', ->
        # FIXME instead of erasing, purge based on timestamp
        data = {}
        @json ok:true

      @view default: ->
        doctype 5
        html ->
          head ->
            script src:'/zappa/Zappa-simple.js'
            script src:'/6minutes/default.js'
          body ->
            div id:'alerts'
            div id:'stats'

      @client '/6minutes/default.js': ->
        @connect()

        # FIXME use the historical data to pre-populate
        @on 'alert': ->
          # FIXME do something with the metadata
          # (ideally alerts pop up in a datatable)
          ($ '#alerts').prepend """
            <p>#{@data.msg}</p>
          """
          return

        @on 'stats': ->
          {timestamp,name} = @data
          n = $ "#stats_#{timestamp}"
          if not n.length
            n = $ """
              <div id="stats_#{timestamp}">#{new Date(timestamp*1000).toISOString()}: </div>
            """
            ($ '#stats').prepend n
          m = $ "#stats_#{timestamp}_#{name}"
          if not m.length
            m = $ """
              <span id="stats_#{timestamp}_#{name}">#{@data.label}: <span>#{@data.data.sum}</span> </span>
            """
            n.append m
          m.children('span').html @data.data.sum
          return

        @on 'ready': ->
          ($ 'alerts').html '<p>Ready</p>'

        return

      @on 'connection': ->
        @join alert_room
        @join stats_room
        @emit 'ready'

Load the plugins.

      do load_plugins

Start the monitoring service.

      do gather

Tools
=====

The alert room used by socket.io to notify clients.

    alert_room = 'alert'
    stats_room = 'stats'

Load Dependencies
-----------------

    ccnq3 = require 'ccnq3'
    pico = require 'pico'
    fs = require 'fs'
    path = require 'path'

Monitor CouchDB changes
-----------------------

A `source` SuperCouch database instance is monitored for changes.

    last_seq = null

    changes = (source_uri,source,cb) ->

If the sequence number of the last changeset is known, re-use it.

      if last_seq?
        do_changes source_uri, cb
      else

Otherwise, retrieve it.

        params =
          descending: true
          limit: 1
        source.action('changes').query(params).end (err,res) ->
          if err
            console.dir error:err
            return
          last_seq = res.last_seq
          do_changes source_uri, cb

TODO: save `last_seq` and retrieve it at next start.

    do_changes = (source_uri,cb) ->
      opts =
        # since_name: 'six_minutes'
        since: last_seq
      pico(source_uri).monitor opts, cb

Retrieve configuration.

    config = null
    ccnq3.config (cfg) ->
      config = cfg
      (require 'zappajs') config.six_minutes, service
