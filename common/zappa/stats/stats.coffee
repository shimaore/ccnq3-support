$ ->
  options =
    lines:
      show: true
    points:
      show: true
    xaxis:
      tickDecimals: 0
      tickSize: 1

  data = []
  data[0] =
    data: []
    label: 'Attempts'
    hoverable: true
    xaxis:
      mode: 'time'
  data[1] =
    data: []
    label: 'Success'
    hoverable: true
    xaxis:
      mode: 'time'

  # hour = new Date().toJSON().substr(0,13).replace('T',' ')
  # start = escape JSON.stringify [hour,'egress']
  # end   = escape JSON.stringify [hour,'egress',{}]

  $.getJSON "/cdrs/_design/stats/_view/account_monitor?group_level=1", (data) ->
    for row in data.rows
      # [date,direction,account] = row.key
      [hour] = row.key
      hour += ':00'
      data[0].data.push [hour,row.value.attempts]
      data[1].data.push [hour,row.value.success]
    $.plot '#flot', data, options

  $.plot '#flot', data, options
