local {wallPosterPreview} = require("enlisted/ui/hud/state/wallposter.nut")
local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local { DEFAULT_TEXT_COLOR } = require("ui/hud/style.nut")

local function wallposterTips() {
  local res = { watch = [wallPosterPreview] }
  if (!wallPosterPreview.value)
    return res
  return res.__update({
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = [
      tipCmp({
        text = loc("wallposter/place")
        inputId = "Wallposter.Place"
        textColor = DEFAULT_TEXT_COLOR
      }),
      tipCmp({
        text = loc("wallposter/cancel")
        inputId = "Wallposter.Cancel"
        textColor = DEFAULT_TEXT_COLOR
      }),
      {
        hooks = HOOK_ATTACH
        actionSet = "Wallposter"
      }
    ]
  })
}

return [
  wallposterTips
]
 