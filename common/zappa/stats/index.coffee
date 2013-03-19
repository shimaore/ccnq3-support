doctype 5
html ->
  head ->
    meta charset: 'utf-8'
    title 'Statistics'
    link rel:'stylesheet', href:'index.css', type:'text/css'
    script type:'text/javascript', src:'assets/coffee-script.js'
    script type:'text/javascript', src:'assets/coffeecup.js'
    script type:'text/javascript', src:'assets/jquery-1.9.1.min.js'
    script type:'text/javascript', src:'assets/jquery.flot.js'
    script type:'text/javascript', src:'assets/jquery.flot.time.js'
    script type:'text/coffeescript', src:'stats.coffee'
  body ->
    div id:"main", ->
      div id:"flot"
