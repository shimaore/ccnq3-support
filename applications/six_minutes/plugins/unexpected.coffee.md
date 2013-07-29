This 6minutes plugin reports unexpected carrier error codes.

    @plugin = ->

Typically a CDR might contain:

      expected_codes =
        200: 'Call went through'
        404: 'Phone number is not assigned'
        486: 'Recipient busy'
        487: 'Caller canceled the call before it was connected'

If a call ends with a different error code we report it.

      sip_cause = @doc.variables?.last_bridge_proto_specific_hangup_cause
      if sip_cause? and m = sip_cause.match /^sip:(\d)$/
        cause = parseInt m[1]
        if expected_codes[cause]
          return

        @alert "Unexpected SIP code #{cause} for #{@profile} (#{@direction})"
        @increment "unexpected #{@direction} #{@profile} #{cause}"
