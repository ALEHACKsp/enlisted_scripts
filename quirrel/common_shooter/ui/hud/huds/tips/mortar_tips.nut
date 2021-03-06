local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")


local fireTip = tipCmp({inputId = "Human.Shoot", text = ::loc("controls/Human.Shoot"), font = Fonts.small_text, style={rendObj=null}})
local exitTip = tipCmp({inputId = "Mortar.Cancel", text = ::loc("controls/cancelMortarAiming"), font = Fonts.small_text, style={rendObj=null}})

return {
  flow     = FLOW_VERTICAL
  children = [fireTip, exitTip]
  gap      = hdpx(5)
}
 