doctype 5
html ->
  head ->
    meta charset: 'utf-8'
    title 'Statistics'
    link rel:'stylesheet', href:'index.css', type:'text/css'
    script type:'text/javascript', src:'assets/coffee-script.js'
    script type:'text/javascript', src:'assets/coffeecup.js'
    script type:'text/javascript', src:'assets/jquery-1.9.1.min.js'
    # Flot:
    script type:'text/javascript', src:'assets/jquery.flot.js'
    script type:'text/javascript', src:'assets/jquery.flot.time.js'
    script type:'text/javascript', src:'assets/jquery.flot.navigate.js'
    script type:'text/javascript', src:'assets/jquery.flot.tooltip.js'
    # Datatables:
    script type:'text/javascript', src:'assets/dt/js/jquery.dataTables.js'
    link rel:'stylesheet', href:'assets/dt/css/jquery.dataTables.css', type:'text/css'
    # and our stuff:
    script type:'text/coffeescript', src:'stats.coffee'
  body ->
    div id:"main", ->
      div id:"flot", 'Please wait, retrieving data...'
      div id:"table"
