Overview
========

`6minutes` is an application that listen to the CDRs (aggregation) changes and generates per-6-minutes (deci-hour) reports of what happened during that hour. Data is kept in memory (for the past 24 hours) and can be retrieved using the Web API.

It focuses on troubleshooting:
- report call issues with carriers (zero-duration call ratio, unexpected SIP error reports, etc.)
- report per-account issues

Data is generated via plugins; plugins can be added in the plugins directory to create new statistics.

There are two inter-twined processes. One is the web service

    service = ->

while the other one is the data gathering (and plugins). Since that one can be controlled by the web service, it is actually started from within the web service.

      plugins = []

      gather = ->

        source = ccnq3.db.couch config.aggregate?.cdrs_uri
        changes(source).on 'change', (changeset) ->

Using the end-of-call timestamp, determine which 6-minutes window is concerned.
(Expressed as seconds.)

          end_epoch = changeset.doc.variables.end_epoch
          timestamp = end_epoch - end_epoch % 6*60

Each plugin is actually a standalone callback for a CDR document.

          for plugin in plugins
            plugin changeset.doc, timestamp

          return

Actually the plugins might gather statistics, trigger alerts, etc.

      plugin_directory = './plugins'

      data = {}
      alerts = []

      load_plugins = ->

        new_plugins = []

        fs.readdir plugin_directory, (err,files) =>
          if err
            console.error "Could not read #{plugin_directory}"
            process.exit 1
          for name in files when f.match /\.coffee\.md$/
            src = require(path.join plugin_directory, name)
            new_plugins.push (doc,timestamp) =>

Plugins consist of a `@plugin` function which is evaluated in the context of:
- `@doc` the original document
- `@timestamp` the timestamp
- `@alert(msg)` -- socket.io alert in the `alert_room`
- `@add(name,number)`

              ctx =
                doc: doc
                profile: doc.variables?.ccnq_profile
                direction: doc.variables?.ccnq_direction
                account: doc.variables?.ccnq_account
                duration:
                  billable: doc.variables?.billsec
                  total: doc.variables?.duration
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
                  @io.socket.in(alert_room).emit alert
                  alerts.push alert
                increment: (name,value = 1) =>
                  data[timestamp] ?= {}
                  rec = data[timestamp][name]
                  if rec?
                    rec.value += value
                    rec.count++
                    rec.squares += value*value
                    rec.max = value if value > rec.max
                    rec.min = value if value < rec.min
                  else
                    rec =
                      value: value
                      max: value
                      min: value
                      count: 1
                      squares: value*value
                    data[timestamp][name] = rec

              src.plugin.apply ctx, doc, timestamp

Update the plugins list at once

          plugins = new_plugins

      @enable 'minify'
      @set 'zappa_prefix', '/_ccnq3/support/6minutes/zappa'

      @post '/_ccnq3/support/6minutes/restart', ->
        do load_plugins
        @json ok:true

      @get '/_ccnq3/support/6minutes', ->
        @render 'default'

      @get '/_ccnq3/support/6minutes/alerts', ->
        @json alerts

      @get '/_ccnq3/support/6minutes/data', ->
        @json data

      @del '/_ccnq3/support/6minutes/alerts', ->
        # FIXME instead of erasing, purge based on timestamp
        alerts = []
        @json ok:true

      @del '/_ccnq3/support/6minutes/data', ->
        # FIXME instead of erasing, purge based on timestamp
        data = {}
        @json ok:true

      @view default: ->
        doctype 5
        html ->
          head ->
            script src:'zappa/zappa.js'
            script src:'default.js'
          body ->
            div id:'alerts'
            div id:'stats', ->
              table ->

      @client '/ccnq3/support/6minutes/default.js', ->
        alert_room = 'alert'

        @connect()
        @join alert_room

        $ =>
          # FIXME use the historical data to pre-populate
          @on 'alert', (alert) ->
            # FIXME do something with the metadata
            # (ideally alerts pop up in a datatable)
            ($ 'alerts').append alert.msg

Load the plugins.

      do load_plugins

Start the monitoring service.

      do gather

Tools
=====

The alert room used by socket.io to notify clients.

    alert_room = 'alert'

Load Dependencies
-----------------

    ccnq3 = require 'ccnq3'
    supercouch = require 'supercouch'
    byline = require 'byline'
    fs = require 'fs'

Monitor CouchDB changes
-----------------------

A `source` SuperCouch database instance is monitored for changes.

    changes = (source) ->
      params =
        since: last_time
        heartbeat: 10000
        include_docs: true
      gatherer = byline source.action('changes').send params
      gatherer.on 'data', (line) ->
        try
          changeset = JSON.parse line
        catch error
          gatherer.emit 'error', error
          return
        gatherer.emit 'change', changeset
      gatherer


Retrieve configuration.

    config = null
    ccnq3.config (cfg) ->
      config = cfg
      (require 'zappajs') config.six_minutes.port, service

