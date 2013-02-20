@include = ->

  @get '/_ccnq3/support', ->
    @render 'support/index.coffee'

  fs = require 'fs'
  path = require 'path'
  root = path.join __dirname, 'support'

  @get '/_ccnq3/support/*', ->
    name = @params[0]
    @res.sendfile name, {root}

return
