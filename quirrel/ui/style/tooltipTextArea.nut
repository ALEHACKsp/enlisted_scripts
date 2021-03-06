local tooltipBox = require("tooltipBox.nut")

return function(textParams, bgOverride = {}) {
  return tooltipBox({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = hdpx(500)
      color = Color(180, 180, 180, 120)
    }.__merge(textParams)
  ).__merge(bgOverride)
} 