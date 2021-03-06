local colors = require("ui/style/colors.nut")

local function tabCtor(tab, is_current, handler) {
  local grp = ::ElemGroup()
  local stateFlags = ::Watched(0)

  return function() {
    local isHover = (stateFlags.value & S_HOVER)
    local isFocus = (stateFlags.value & S_KB_FOCUS)
    local fillColor, textColor, borderColor
    if (is_current || isFocus) {
      textColor = isHover ? colors.BtnTextHover : colors.BtnTextActive
      fillColor = isHover ? colors.BtnBgHover : colors.BtnBgActive
    } else {
      textColor = isHover ? colors.BtnTextHilite : colors.BtnTextNormal
      fillColor = colors.BtnBgNormal
    }
    borderColor = isHover ? colors.BtnTextHilite : colors.BtnTextNormal

    return {
      key = tab
      rendObj = ROBJ_BOX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      watch = stateFlags
      group = grp

      behavior = Behaviors.Button
      skipDirPadNav = true

      sound = {
        click  = "ui/button_click"
        hover  = "ui/menu_highlight"
        active = "ui/button_action"
      }

      fillColor = fillColor
      borderColor = borderColor
      borderWidth = [0, 0, 1, 0]

      onClick = handler
      onElemState = @(sf) stateFlags.update(sf)

      children = {
        rendObj = ROBJ_DTEXT
        font = Fonts.medium_text
        margin = [sh(1), sh(2)]
        color = textColor

        text = tab.text
        group = grp
      }
    }
  }
}
return tabCtor 