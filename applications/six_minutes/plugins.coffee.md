Overview
========

`6minutes` is an application that listen to the CDRs (aggregation) changes and generates per-6-minutes (deci-hour) reports of what happened during that hour.

It focuses on troubleshooting:
- report call issues with carriers (zero-duration call ratio, unexpected SIP error reports, etc.)
- report per-account issues

Data is generated via plugins; plugins can be added in the plugins directory to create new statistics.

    plugins = []

    @gather = (doc) ->

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

    @load_plugins = (o)=>

      o.realtime ?= false

      current_data = {}
      current_timestamp = null

      manifest = (type,timestamp,name,rec) ->
        id = name.replace /[^a-zA-Z]+/g, '_'
        stats =
          type: type
          timestamp: timestamp
          name: id
          label: name
          data: rec
        o.on_stats stats

      accumulate = (timestamp,name,value) ->
        unless timestamp is current_timestamp
          last_data = current_data
          last_timestamp = current_timestamp
          current_data = {}
          current_timestamp = timestamp
          for n,r of last_data
            do (n,r) ->
              manifest 'stats', last_timestamp, n, r

        rec = current_data[name]
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
          current_data[name] = rec

        return rec

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
- `@alert(msg)` -- send and return an alert; `msg` is an object with at least `text` and `type` arguments.
- `@increment(name,number)` -- add the value and returns the statistical data
- `@retrieve(name)` -- retrieve the statistical data for a name

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
                    type: 'alert'
                    msg:msg
                    doc:doc
                    timestamp:timestamp
                    profile: ctx.profile
                    direction: ctx.direction
                    account: ctx.account
                    duration: ctx.duration
                    from: ctx.from
                    to: ctx.to
                  o.on_alert alert
                  alert
                increment: (name,value = 1) =>
                  rec = accumulate timestamp, name, value
                  if o.realtime
                    manifest 'intermediate_stats', timestamp, name, rec
                  rec
                retrieve: (name) =>
                  current_data[name]

              src.plugin.apply ctx

Update the plugins list at once

        plugins = new_plugins
        return

    fs = require 'fs'
