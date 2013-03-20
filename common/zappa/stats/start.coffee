timezoneJS.timezone.zoneFileBasePath = 'assets/tz'
timezoneJS.timezone.init()
timezone = 'US/Central' # FIXME this should be provided somewhere else!!
$ =>
  @ccnq3.graph_hourly timezone
