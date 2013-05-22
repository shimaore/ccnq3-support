#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

ccnq3 = require 'ccnq3'
ccnq3.config (config)->

  provisioning_uri = config.provisioning?.couchdb_uri
  if provisioning_uri
    push_script provisioning_uri, 'prov'

  cdrs_uri = config.aggregate?.cdrs_uri
  if cdrs_uri
    push_script cdrs_uri, 'stats'

  return
