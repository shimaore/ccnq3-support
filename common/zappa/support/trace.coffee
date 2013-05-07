qs =
  escape: encodeURIComponent

log = -> console.log arguments...

# Process response (callback)
send_request = (request) ->
  sip_request = coffeecup.compile ->
    div class:"packet request split-#{@is_new}", ->
      span class:"time",  -> @['frame.time']
      span class:"callid", -> @['sip.Call-ID']
      span class:"src",   -> @['ip.src']+':'+ (@['udp.srcport'] ? @['tcp.srcport'])
      span '→'
      span class:"dst",   -> @['ip.dst']+':'+ (@['udp.dstport'] ? @['tcp.dstport'])
      span class:"method", title:h(@['sip.Request-Line']), -> @['sip.Method']
      span class:"ruri",  -> @['sip.r-uri.user']+'@'+@['sip.r-uri.host']
      span class:"from", title: h(@['sip.From']), -> @['sip.from.user']
      span '→'
      span class:"to", title:h(@['sip.To']), -> @['sip.to.user']

  sip_response = coffeecup.compile ->
    div class:"packet response split-#{@is_new}", ->
      span class:"time",  -> @['frame.time']
      span class:"callid", -> @['sip.Call-ID']
      span class:"dst",   -> @['ip.dst']+':'+ (@['udp.dstport'] ? @['tcp.dstport'])
      span '←'
      span class:"src",   -> @['ip.src']+':'+ (@['udp.srcport'] ? @['tcp.srcport'])
      span class:"status", title:h(@['sip.Status-Line']), -> @['sip.Status-Code']
      span class:"from", title:h(@['sip.From']), -> @['sip.from.user']
      span '←'
      span class:"to", title:h(@['sip.To']), -> @['sip.to.user']

  pcap_link = coffeecup.compile ->
    a href: "/logging/trace:#{@reference}:#{@host}/packets.pcap", ->
      'Download (PCAP)'

  format_host_link = (h) ->
    """
      <a href="##{h}">#{h}</a>
    """

  display_packets = (root,packets) ->
    for packet in packets
      if packet["sip.Method"]
        el = $ sip_request packet
      else
        el = $ sip_response packet
      el.data 'packet', packet
      root.append el

  processed_host = {}
  check_response = ->
    $.ajax
      type: 'GET'
      url: '/logging/_all_docs'
      dataType: 'json'
      data:
        startkey: JSON.stringify "trace:#{request.reference}:"
        endkey: JSON.stringify "trace:#{request.reference};"
        include_docs: true
      error: ->
        log 'Failed'
        log arguments
      success: (data) ->
        return unless data?.rows?
        for row in data.rows
          do (row) ->
            doc = row.doc

            # Only show the response from each host once!
            return if processed_host[doc.host]
            processed_host[doc.host] = true

            $('#hosts').html 'Hosts: '+(Object.keys processed_host).sort().map(format_host_link).join(' | ')

            el_host = $ """
              <div>
                <h2 class="host"><a name="#{doc.host}">#{doc.host}</a></h2>
              </div>
            """
            el_host.data 'doc', doc
            $('#traces').append el_host

            if doc.packets? and doc.packets.length > 0

              # Compute Call-ID transitions
              last_callid = ''
              for packet in doc.packets
                callid = packet['sip.Call-ID']
                packet.is_new = callid isnt last_callid
                last_callid = callid

              # Content
              len = doc.packets.length

              el_link = $ pcap_link doc
              el_host.append el_link

              el_packets = $ "<div><button>Show all #{len} packets</button></div>"

              limit = 50
              if len > limit
                el_packets.children('button').click ->
                  el_packets.empty()
                  display_packets el_packets, doc.packets
                display_packets el_packets, doc.packets[(len-limit)..]
              else
                el_packets.children('button').remove()
                display_packets el_packets, doc.packets

              el_host.append el_packets

            else

              el_host.append 'No packets'



  $.ajax
    type: 'PUT'
    url: '/_ccnq3/traces'
    dataType: 'json'
    data: request
    error: ->
      log 'Failed'
      log arguments...
    success: (data) ->
      log data
      return unless data?
      $('#traces').empty()
      if t? then clearInterval t
      t = setInterval check_response, 1000
      log "Sent request reference #{request.reference}."

  $('#results').html '''
    <div id="hosts"></div>
    <div id="traces">Please wait...</div>
  '''

  return

$ ->

  # Add HTML form for query
  $('#entry').append '''
    <form id="trace">
      <label>Trace
      <label>From
        <input type="text" name="from_user" id="from_user" size="16" />
      </label>
      →
      <label>To
        <input type="text" name="to_user" id="to_user" size="16" />
      </label>
      <label>Call-ID
        <input type="text" name="call_id" id="call_id" />
      </label>
      <label>
        <input type="text" name="days_ago" id="days_ago" value="" size="2" />
        days ago
      </label>
      <input type="submit" />
    </form>
    <div class="calls"></div>
  '''

  t = null
  $('body').on 'keyup', '#from_user', ->
    # Throttle
    if t? then clearTimeout t
    t = setTimeout run, 250

  run = ->

    t = null
    limit = $('#limit').val()

    # Cleanup parameters
    from_user = $('#from_user').val()
    if from_user? and from_user isnt ''
      from_user = from_user.replace /[^\d]+/g, ''
      from_user = entry_to_local from_user
    if not from_user? or from_user is ''
      from_user = null

    return unless from_user?

    last_calls $('#trace'), from_user

  # Handle form submission
  t = null
  $('body').on 'submit', '#trace', (e) ->

    $('#traces').spin()

    reference = 'r'+Math.random()

    # Cleanup parameters
    from_user = $('#from_user').val()
    if from_user? and from_user isnt ''
      from_user = from_user.replace /[^\d]+/g, ''
      from_user = entry_to_local from_user
    if not from_user? or from_user is ''
      from_user = null

    to_user = $('#to_user').val()
    if to_user
      to_user = to_user.replace /[^\d]+/g, ''
      to_user = entry_to_local to_user
    if not to_user or to_user is ''
      to_user = null

    call_id = $('#call_id').val()
    if call_id? and call_id isnt ''
      call_id = call_id.replace /^\s+|\s+$/g, ''
    if not call_id? or call_id is ''
      call_id = null

    days_ago = $('#days_ago').val()
    if days_ago? and days_ago isnt ''
      days_ago = parseInt days_ago
    if not days_ago or days_ago is ''
      days_ago = null

    # Send request
    request = {reference}
    request.from_user = from_user if from_user?
    request.to_user   = to_user   if to_user?
    request.call_id   = call_id   if call_id?
    request.days_ago  = days_ago  if days_ago?
    send_request request

    # No default
    e.preventDefault()
    return false

  # Links for callids
  $('body').on 'click', '.callid', (e) ->
    doc = $(@).parent().data 'doc'
    reference = 'r'+Math.random()
    request = {reference}
    request.call_id   = call_id   if doc.call_id?
    send_request request

  return

return
