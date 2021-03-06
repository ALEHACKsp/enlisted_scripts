local textButton = require("enlist/components/textButton.nut")

return function(opt, group, xmbNode){
  return {
    size = [flex(), SIZE_TO_CONTENT]
    children = textButton(opt.var.value?.text, @() opt.var.value?.handler(), {
      group = group
      xmbNode=xmbNode
    })
  }
} 