@ccnq3 ?= {}
@ccnq3.account_monitor = (hour,timezone) ->
  if hour?
    hour = new timezoneJS.Date hour, timezone
  else
    hour = new timezoneJS.Date timezone
  hour = hour.toString('yyyy-MM-dd HH')

  $('#table caption').html "#{hour} #{timezone}"

  # DataTables
  start = escape JSON.stringify [hour]
  end   = escape JSON.stringify [hour,{}]

  columns = [
    'Account'                 # 0
    'Inbound Attempts'        # 1
    'Inbound Attempts (cps)'
    'Inbound Success'
    'Inbound Success (cps)'
    'Inbound CSR'
    'Inbound Minutes'
    'Inbound ACD (s)'
    'Outbound Attempts'       # 8
    'Outbound Attempts (cps)'
    'Outbound Success'
    'Outbound Success (cps)'
    'Outbound CSR'
    'Outbound Minutes'
    'Outbound ACD (s)'
  ]
  $.getJSON "/cdrs/_design/stats/_view/account_monitor?group_level=3&start_key=#{start}&end_key=#{end}", (json) ->
    set = {}
    for row in json.rows
      [hour,direction,account] = row.key
      rec = set[account] ? []

      rec[0] = account ? ''
      for i in [0..columns.length]
        rec[i] ?= ''
      b = null
      if direction is 'ingress'
        b = 1
      if direction is 'egress'
        b = 8
      if b?
        rec[b++] = row.value.attempts
        rec[b++] = (row.value.attempts/3600).toFixed(3)
        rec[b++] = row.value.success
        rec[b++] = (row.value.success/3600).toFixed(3)
        if row.value.attempts > 0
          rec[b++] = (100*row.value.success/row.value.attempts).toFixed(1)
        else
          rec[b++] = ''
        rec[b++] = (row.value.duration/60).toFixed(1)
        if row.value.success > 0
          rec[b++] = (row.value.duration/row.value.success).toFixed(1)
        else
          rec[b++] = ''
      set[account] = rec

    data = []
    for k,v of set
      data.push v

    $('#table').dataTable
      aaData: data
      aoColumns: columns.map (v) -> { sTitle: v, sClass: 'right' }
      bDestroy: true
