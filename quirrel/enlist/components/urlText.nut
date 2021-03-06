local openUrl = require("enlist/openUrl.nut")
local colors = require("ui/style/colors.nut")

local function url(str, address, params = {}) {
  local group = ::ElemGroup()
  local stateFlags = Watched(0)

  return function() {
    local sf = stateFlags.value
    local color = (sf & S_ACTIVE) ? colors.Active
                  : (sf & S_HOVER) ? colors.ButtonHover
                  : colors.Inactive

    return {
      watch = stateFlags
      rendObj = ROBJ_DTEXT
      behavior = Behaviors.Button
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }
      font = Fonts.medium_text
      text = str
      color = color
      group = group
      children = {
        rendObj = ROBJ_FRAME
        borderWidth = [0,0,2,0]
        color = color
        group = group
        size = flex()
        pos = [0, 2]
      }.__update(params?.childParams ?? {})
      onClick = function() { openUrl(address) }
      onElemState = @(newSF) stateFlags.update(newSF)
    }.__update(params)
  }
}

return url
 