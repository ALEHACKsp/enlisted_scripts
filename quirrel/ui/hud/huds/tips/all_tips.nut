local tips = require("ui/hud/state/tips.nut")

local tipsBlock = {
  gap = sh(1)
  flow = FLOW_VERTICAL
  size = [SIZE_TO_CONTENT,SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

return @() {
  watch = tips
  size = flex()
  children = (tips.value ?? []).map(@(tipGroup) tipsBlock.__merge(tipGroup))
}
 