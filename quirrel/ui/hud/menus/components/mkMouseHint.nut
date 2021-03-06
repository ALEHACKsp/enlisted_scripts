local isGamepad = require("ui/control/active_controls.nut").isGamepad
local gamepadImgByKey = require("ui/components/gamepadImgByKey.nut")
local mkImageComp = gamepadImgByKey.mkImageComp
local style = require("ui/hud/style.nut")
local dtext = require("daRg/components/text.nut").dtext

local mouseBtn = @(btn) mkImageComp(gamepadImgByKey.keysImagesMap?[btn], {height = ::hdpx(20) color = style.HUD_TIPS_HOTKEY_FG})

local text = @(txt) dtext({text=txt font=Fonts.small_text color = style.HUD_TIPS_HOTKEY_FG localize=false}) //fixme color
local gap = text(",").__merge({vplace=ALIGN_BOTTOM})
local function mouseBtns(btns) {
  if (::type(btns) != "array")
    btns = [btns]
  return {
    flow = FLOW_HORIZONTAL
    gap = gap
    size = SIZE_TO_CONTENT
    children = btns.map(mouseBtn)
  }
}

local function mkMouseButtonHint(btext, btns){
  local clickText = text(::loc(btext))
  return @(){
    watch = isGamepad
    flow = FLOW_VERTICAL
    size = SIZE_TO_CONTENT
    children = (btext!=null && !isGamepad.value) ? [
      { size = SIZE_TO_CONTENT flow = FLOW_HORIZONTAL valign = ALIGN_CENTER gap = ::hdpx(5)
        children = [
          mouseBtns(btns)
          clickText
        ]
      }
    ] : null
  }
}

return mkMouseButtonHint 