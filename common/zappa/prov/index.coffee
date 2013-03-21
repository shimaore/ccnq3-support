doctype 5
html ->
  head ->
    meta charset: 'utf-8'
    title 'Statistics'
    link rel:'stylesheet', href:'index.css', type:'text/css'
    script type:'text/javascript', src:'assets/coffee-script.js'
    script type:'text/javascript', src:'assets/coffeecup.js'
    script type:'text/javascript', src:'assets/jquery-1.9.1.min.js'
    # and our stuff:
    script type:'text/coffeescript', src:'selectors.coffee'
    script type:'text/coffeescript', src:'start.coffee'

  body ->

    # Left pane contains selectors and items to add to working set.
    div id:"left", ->
      div class:"head", "Selectors"
      # Left column contains at the top a set of selectors
      div id:"selectors"
      # there will be a "Select All" checkbox at the top
      div ->
        input type:'checkbox', id:"select_all"
        label for:"select_all", "Select All"
        button id:"add_to_working_set", "Add to My Working Set"
      # The selectors' output is shown in a list below
      ul id:"input"
      # Entries in the list will have checkboxes

    # Middle pane is the current working set
    div id:"middle", ->
      div class:"head", "Your Working Set"
      ul id:"working_set"

    # Right pane is a list of operations to apply to the current working set
    div id:"right", ->

