Overview
========

`6minutes` is an application that listen to the CDRs (aggregation) changes and generates per-6-minutes (deci-hour) reports of what happened during that timespan.

It focuses on troubleshooting:
- report call issues with carriers (zero-duration call ratio, unexpected SIP error reports, etc.)
- report per-account issues

Data is generated via plugins; plugins can be added in the plugins directory to create new statistics.

There are two inter-twined processes. One is the web service

    service = ->

      year = 365*24*3600*1000
      @use 'logger', 'cookieParser', session:{secret:'a'+Math.random(), cookie: { maxAge: year }}

while the other one is the data gathering (and plugins). Since that one can be controlled by the web service, it is actually started from within the web service.

      plugins = require './plugins'

      gather = ->

        source_uri = config.aggregate?.cdrs_uri
        source = ccnq3.db.couch source_uri
        changes source_uri, source, plugins.gather

Actually the plugins might gather statistics, trigger alerts, etc.

      plugin_directory = './plugins'

The data is pushed out once a six-minutes interval has gone.
Alerts are pushed immediately.

It is up to other processes (e.g. listening on the AMQP bus) to collect the data (if historical record is desired), etc.

      send = (it) ->
        if amqp_send?
          amqp_send it
        else
          console.dir it


      plugins.load_plugins
        realtime: true
        on_alert: send
        on_stats: send

      @post '/6minutes/restart', ->
        do load_plugins
        @json ok:true

Load the plugins.

      do load_plugins

Start the monitoring service.

      do gather

Tools
=====

Load Dependencies
-----------------

    ccnq3 = require 'ccnq3'

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

Send alerts or stats messages.

    amqp_send = ccnq3.log

Retrieve configuration.

    config = null
    ccnq3.config (cfg) ->
      config = cfg
      (require 'zappajs') config.six_minutes, service
