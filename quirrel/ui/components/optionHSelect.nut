local select = require("select.nut")

//return ::kwarg(function select(state, options, onClickCtor=null, isCurrent=null, textCtor=null, elem_style=null, root_style=null) {

return function(opt, group, xmbNode){
  local { available, var } = opt
  local items = available instanceof ::Watched
    ? available
    : Watched(available)
  return function(){
    return {
      size = [flex(), SIZE_TO_CONTENT]
      watch = items
      children = select({state = var, options = items.value, root_style = { group = group, xmbNode=xmbNode}})
    }
  }
} 