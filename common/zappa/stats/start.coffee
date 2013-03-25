timezoneJS.timezone.zoneFileBasePath = 'assets/tz'
timezoneJS.timezone.init()
timezone = 'US/Central' # FIXME this should be provided somewhere else!!
$ =>
  graph_hourly = ->
    @ccnq3.graph_hourly timezone
  setInterval graph_hourly, 5*60*1000
  do graph_hourly
