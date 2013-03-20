$ ->

  # Flot
  options =
    series:
      lines:
        show: true
      points:
        show: false
      bars:
        show: false
    xaxis:
      mode: 'time'
      timeformat: "%Y-%m-%d %H:--"
      minTickSize: [1,"hour"]
    yaxis:
      min: 0
    yaxes: [
      { }
      { max: 100 }
    ]
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
    yaxis: 1
    label: 'Inbound Attempts (cps)'
  data[1] =
    data: []
    yaxis: 1
    label: 'Inbound Success (cps)'
  data[2] =
    data: []
    yaxis: 1
    label: 'Outbound Attempts (cps)'
  data[3] =
    data: []
    yaxis: 1
    label: 'Outbound Success (cps)'
  ###
  data[4] =
    data: []
    lines:
      show: false
    points:
      show: true
    yaxis: 2
    label: 'Inbound CSR (%)'
  data[5] =
    data: []
    lines:
      show: false
    points:
      show: true
    yaxis: 2
    label: 'Outbound CSR (%)'
  ###

  $.getJSON "/cdrs/_design/stats/_view/account_monitor?group_level=2", (json) ->
    for row in json.rows
      [hour,direction] = row.key
      hour = hour.replace ' ', 'T'
      hour += ':00'
      hour = new Date hour
      if direction is 'ingress'
        data[0].data.push [hour,row.value.attempts/3600]
        data[1].data.push [hour,row.value.success/3600]
        ## data[4].data.push [hour,100*row.value.success/row.value.attempts] if row.value.attempts > 0
      if direction is 'egress'
        data[2].data.push [hour,row.value.attempts/3600]
        data[3].data.push [hour,row.value.success/3600]
        ## data[5].data.push [hour,100*row.value.success/row.value.attempts] if row.value.attempts > 0

    $('#flot').empty()
    $.plot '#flot', data, options
