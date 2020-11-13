
return function(opt, group, xmbNode){
  return {
    size = [flex(50), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children =  @() {
      text = opt.var.value?.text
      size = [flex(), SIZE_TO_CONTENT]
      watch = opt.var
      rendObj = ROBJ_TEXTAREA
      group = group
      behavior = Behaviors.TextArea
      font = Fonts.small_text
      color = Color(160,160,160)
      //maxContentWidth = pw(100)
    }.__merge(::type(opt.var?.value)=="table" ? opt.var.value : {})
  }
} 