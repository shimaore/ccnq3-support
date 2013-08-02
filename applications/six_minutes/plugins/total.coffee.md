    @plugin = ->

        @increment "calls"
        @increment "total", @duration.total
        @increment "billable", @duration.billable
        @increment "zero duration" if @duration.billable is 0

        @increment "calls #{@profile}"
        @increment "zero duration #{@profile}" if @duration.billable is 0
