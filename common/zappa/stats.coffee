@include = ->

  @get '/_ccnq3/stats', ->
    @render 'stats/index.coffee'

  fs = require 'fs'
  path = require 'path'
  root = path.join __dirname, 'stats'

  @get '/_ccnq3/stats/*', ->
    name = @params[0]
    @res.sendfile name, {root}

return
