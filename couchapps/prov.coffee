# prov.coffee

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/prov'
  views: {}
  lists: {}

module.exports = ddoc

ddoc.views.by_account =
  map: p_fun (doc) ->
    return unless doc.type?
    # Only these are accessible to provisioners
    return unless doc.type in ['number','endpoint','location']
    return unless doc.account?
    emit doc.account, null
