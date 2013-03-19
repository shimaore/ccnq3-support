$ ->
  options =
    lines:
      show: true
    points:
      show: true
    xaxis:
      tickDecimals: 0
      tickSize: 1
      mode: 'time'
    grid:
      hoverable: true
    zoom:
      interactive: true
    pan:
      interactive: true

  data = []
  data[0] =
    data: []
    label: 'Attempts'
  data[1] =
    data: []
    label: 'Success'

  # hour = new Date().toJSON().substr(0,13).replace('T',' ')
  # start = escape JSON.stringify [hour,'egress']
  # end   = escape JSON.stringify [hour,'egress',{}]

  $.getJSON "/cdrs/_design/stats/_view/account_monitor?group_level=1", (json) ->
    for row in json.rows
      # [date,direction,account] = row.key
      [hour] = row.key
      hour = hour.replace ' ', 'T'
      hour += ':00'
      hour = new Date hour
      data[0].data.push [hour,row.value.attempts]
      data[1].data.push [hour,row.value.success]
    $.plot '#flot', data, options
