p_fun = (f) -> '('+f+')'

reduce_monitor = p_fun (key,values,rereduce) ->
  result =
    attempts: 0
    success: 0
    duration: 0
  if not rereduce
    for v in values
      result.attempts += 1
      result.success += 1 if v > 0
      result.duration += v
  else
    for v in values
      result.attempts += v.attempts
      result.success += v.success
      result.duration += v.duration
  return result

ddoc =
  _id: '_design/support-stats'
  filters: {}
  language: 'javascript'
  views:
    account_monitor:
      map: p_fun (doc) ->
        return unless doc.variables?
        account = doc.variables.ccnq_account
        direction = doc.variables.ccnq_direction
        hour = doc.variables.start_stamp.substr 0, 13
        emit [hour,direction,account], parseInt doc.variables.billsec ? 0
        return
      reduce: reduce_monitor

    profile_monitor:
      map: p_fun (doc) ->
        return unless doc.variables?
        profile = doc.variables.ccnq_profile
        direction = doc.variables.ccnq_direction
        hour = doc.variables.start_stamp.substr 0, 13
        emit [hour,direction,profile], parseInt doc.variables.billsec ? 0
        return
      reduce: reduce_monitor

module.exports = ddoc
