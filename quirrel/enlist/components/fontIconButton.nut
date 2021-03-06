local colors = require("ui/style/colors.nut")
local {buttonSound} = require("ui/style/sounds.nut")
local getGamepadHotkeys = require("ui/components/getGamepadHotkeys.nut")
local gamepadImgByKey = require("ui/components/gamepadImgByKey.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local fa = require("daRg/components/fontawesome.map.nut")

local function defIconColor(sf) {
  if (sf & S_ACTIVE) {
    return colors.TextActive
  }
  if (sf & S_HOVER) {
    return colors.TextHighlight
  }
  return colors.TextDefault
}

local function fontIconButton(icon, params = {}) {
  local stateFlags = Watched(0)
  local gamepadHotkey = getGamepadHotkeys(params?.hotkeys, true)
  local skipDirPadNav = params?.skipDirPadNav ?? ((gamepadHotkey ?? "") != "")
  local iconColor = params?.iconColor ?? defIconColor
  local img = (gamepadHotkey == "") ? null : gamepadImgByKey.mkImageCompByDargKey(gamepadHotkey)
  if (fa?[icon]!=null)
    icon = fa[icon]
  return function() {
    local gamepadImg = isGamepad.value && img!=null
    local p = params
    if (p?.byStateFlags)
      p = p.__merge(p.byStateFlags(stateFlags.value))
    return {
      watch = [stateFlags, isGamepad]
      skipDirPadNav = skipDirPadNav
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER

      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags.update(sf)
      children = gamepadImg ? img : {
        rendObj = ROBJ_STEXT
        font = Fonts.fontawesome
        validateStaticText = false
        text = gamepadImg ? null : icon
        fontSize = hdpx(20)
        color = iconColor(stateFlags.value)
      }.__update(params?.iconParams ?? {})

      sound = buttonSound
    }.__merge(p)
  }
}

return fontIconButton
 