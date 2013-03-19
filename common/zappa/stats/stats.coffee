$ ->
  options =
    series:
      lines:
        show: true
      points:
        show: false
      bars:
        show: false
    xaxis:
      tickDecimals: 0
      tickSize: 1
      mode: 'time'
      timeformat: "%Y-%m-%d %H:--"
      minTickSize: [1,"hour"]
    yaxis:
      tickDecimals: 0
      min: 0
    grid:
      hoverable: true
    zoom:
      interactive: true
    pan:
      interactive: true
    tooltip: true

  data = []
  data[0] =
    data: []
    label: 'Attempts cps (inbound)'
  data[1] =
    data: []
    label: 'Success cps (inbound)'
  data[2] =
    data: []
    label: 'Attempts cps (outbound)'
  data[3] =
    data: []
    label: 'Success cps (outbound)'

  # hour = new Date().toJSON().substr(0,13).replace('T',' ')
  # start = escape JSON.stringify [hour,'egress']
  # end   = escape JSON.stringify [hour,'egress',{}]

  $.getJSON "/cdrs/_design/stats/_view/account_monitor?group_level=2", (json) ->
    for row in json.rows
      # [date,direction,account] = row.key
      [hour,direction] = row.key
      hour = hour.replace ' ', 'T'
      hour += ':00'
      hour = new Date hour
      if direction is 'ingress'
        data[0].data.push [hour,row.value.attempts/3600]
        data[1].data.push [hour,row.value.success/3600]
      if direction is 'egress'
        data[2].data.push [hour,row.value.attempts/3600]
        data[3].data.push [hour,row.value.success/3600]

    $('#flot').empty()
    $.plot '#flot', data, options
