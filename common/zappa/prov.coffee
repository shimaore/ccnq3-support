@include = ->

  @get '/_ccnq3/prov', ->
    @render 'prov/index.coffee'

  fs = require 'fs'
  path = require 'path'
  root = path.join __dirname, 'prov'

  @get '/_ccnq3/prov/*', ->
    name = @params[0]
    @res.sendfile name, {root}

return
