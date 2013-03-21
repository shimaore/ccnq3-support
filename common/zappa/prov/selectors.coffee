@ccnq3 ?= {}
@ccnq3.q = (v) -> escape JSON.stringify v
input = '#input'

build_item = (row) ->
  e = $ """
    <li>
      <checkbox class="input_item">
      <span class="input_type">#{row.doc.type}</span>
      <span class="input_id">#{row.doc[row.doc.type]}</span>
    </li>
  """
  e.data 'row', row
  $(input).append e

build_rows = (rows) ->
  $(input).empty
  for row in rows
    build_item row

@ccnq3.get = (uri) ->
  $.getJSON uri, (json) ->
    unless json?.rows?
      $(input).html 'Nothing found'
      return
    build_rows json.rows

# Selectors are tidbits of coffecup.
selectors =
  account: ->
    label 'Account'
    input title:'Account', alt:'Account'
    coffeescript ->
      $('#account_selector input').bind 'change', ->
        ccnq3.get "/provisioning/_design/prov/_view/by_account?include_docs=true&key=#{ccnq3.q $(@).val()}"

  endpoint: ->
    label 'Endpoint'
    input title:'Endpoint', alt:'Endpoint'
    coffeescript ->
      $('#endpoint_selector input').bind 'change', ->
        ccnq3.get "/provisioning/_all_docs?include_docs=true&key=#{ccnq3.q 'endpoint:'+$(@).val()}"

  number: ->
    label 'Number'
    input title:'Number', alt:'Number'
    coffeescript ->
      $('#number_selector input').bind 'change', ->
        ccnq3.get "/provisioning/_all_docs?include_docs=true&key=#{ccnq3.q 'number:'+$(@).val()}"

for name in Object.keys(selectors).sort()
  def = selectors[name]
  content = coffeecup.render def
  e = $ """
    <div id="#{name}_selector"></div>
  """
  e.html content
  $('#selectors').append e
