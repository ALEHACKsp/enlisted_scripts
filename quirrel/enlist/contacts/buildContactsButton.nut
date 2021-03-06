local colors = require("ui/style/colors.nut")
local fontIconButton = require("enlist/components/fontIconButton.nut")
local fa = require("daRg/components/fontawesome.map.nut")

local function buildContactsButton(params={selected=@() Watched(false) onClick=@() null children=null symbol = fa["users"] enabled=null}) {
  local selected = params?.selected ?? Watched(true)
  local onClick = params?.onClick ?? @() selected(!selected.value)
  local symbol = params?.symbol ?? fa["users"]
  local children = params?.children
  local enabled = params?.enabled ?? Watched(true)
  local function iconColor(sf){
    if (selected?.value)
      return colors.Active
    if (sf & S_ACTIVE) {
      return colors.TextActive
    }
    if (sf & S_HOVER) {
      return colors.TextHighlight
    }
    return colors.TextDefault
  }
  return function() {
    local iconParams = selected?.value ? {fontFx = FFT_GLOW, fontFxColor = colors.Active} : {}
    return {
      watch = [selected, enabled]
      size = SIZE_TO_CONTENT
      children = enabled.value ? [
        fontIconButton(symbol, {onClick = onClick, fontSize = hdpx(30), iconParams = iconParams, iconColor=iconColor})
        {pos = [hdpx(5), 0] size = flex() halign = ALIGN_RIGHT children = children}
      ] : null
    }
  }
}
return buildContactsButton 