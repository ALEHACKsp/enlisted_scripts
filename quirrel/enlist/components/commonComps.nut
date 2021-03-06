local {TextDefault, statusIconBg} = require("ui/style/colors.nut")
local fa = require("daRg/components/fontawesome.map.nut")

local emptyGap = {
  size = [sh(1), sh(1)]
}

local horGap = {
  size = [sh(3), flex()], halign = ALIGN_CENTER, valign = ALIGN_CENTER
  children = { rendObj = ROBJ_SOLID, size = [hdpx(1),flex()], color = TextDefault, margin = [hdpx(4),0], opacity = 0.5 }
}

local ICON_IN_CIRCLE_DEFAULTS = { fontSize = hdpx(20) }
local function iconInCircle(iconParams = ICON_IN_CIRCLE_DEFAULTS) {
  iconParams = ICON_IN_CIRCLE_DEFAULTS.__merge(iconParams)
  return {
    rendObj = ROBJ_STEXT
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    font = Fonts.fontawesome
    fontSize = iconParams.fontSize * 1.3
    validateStaticText = false
    text = fa["circle"]
    color = statusIconBg
    children = {
      size = SIZE_TO_CONTENT
      rendObj = ROBJ_STEXT
      validateStaticText = false
      font = Fonts.fontawesome
    }.__update(iconParams)
  }
}

return {
  horGap = horGap
  emptyGap = emptyGap
  iconInCircle = iconInCircle
}
 