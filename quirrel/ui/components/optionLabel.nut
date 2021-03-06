local style = require("ui/hud/style.nut")


local function optionLabel(opt, group) {
  local stateFlags = ::Watched(0)

  return function() {
    local color = (stateFlags.value & S_HOVER) ? style.HIGHLIGHT_COLOR : Color(160, 160, 160)
    local text = opt?.restart ? $"{opt.name}*" : opt.name
    return {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      //group = group //< for some reason this works only for checkboxes but not for sliders and comboboxes, so disable it for now
      watch = stateFlags
      onElemState = @(sf) stateFlags.update(sf)
      clipChildren = true
      rendObj = ROBJ_DTEXT //do not made this stext as it can eat all atlas
      font = Fonts.medium_text

      //stopMouse = true
      text = text
      color = color
      sound = {
        hover = "ui/menu_highlight_settings"
      }
    }
  }
}

return optionLabel
 