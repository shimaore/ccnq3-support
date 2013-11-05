    lists = require '../lib/lists'

    @plugin = ->

      for duration, pattern of lists
        if @duration.billable >= duration and pattern.exec @to
          @alert
            text: "Fraud detection: #{@account} call to #{@to} from #{@from}"
            type: 'fraud'
          @increment "fraud #{@account} #{@from}"
          return
