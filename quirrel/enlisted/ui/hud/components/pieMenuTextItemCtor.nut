local fa = require("daRg/components/fontawesome.map.nut")

local curTextColor = Color(250,250,200,200)
local defTextColor = Color(150,150,150,50)
local disabledTextColor = Color(50, 50, 50, 50)
local blockedColor = 0xFFFF6060


local mkDisableIcon = @(isBlocked) {
  vplace = ALIGN_CENTER
  rendObj = ROBJ_STEXT
  font = Fonts.fontawesome
  text = fa["times-circle-o"]
  pos = [-::hdpx(30), 0]
  color = isBlocked ? blockedColor : disabledTextColor
  fontSize = ::hdpx(20)
}

local function pieMenuTextItemCtor(text, available = ::Watched(true), isBlocked = ::Watched(false)) {
  if (!(text instanceof ::Watched))
    text = ::Watched(text)
  return @(curIdx, idx)
    ::watchElemState(@(sf) {
      watch = [text, available, isBlocked]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = text.value
      color = !available.value ? disabledTextColor
        : (sf & S_HOVER) || curIdx.value == idx ? curTextColor
        : defTextColor
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      maxWidth = ::hdpx(140)
      valign = ALIGN_CENTER

      children = available.value ? null : mkDisableIcon(isBlocked.value)
    })
}

return ::kwarg(pieMenuTextItemCtor) 