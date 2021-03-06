local fa = require("daRg/components/fontawesome.map.nut")
local speakingPlayers = require("ui/hud/state/voice_chat.nut")
local remap_nick = require("globals/remap_nick.nut")
local {horPadding, verPadding} = require("globals/safeArea.nut")

local speakingColor = Color(0, 255, 0)
local speakingIcon = {
  rendObj = ROBJ_STEXT
  font = Fonts.fontawesome
  text = fa["volume-up"]
  vplace = ALIGN_BOTTOM
  color = speakingColor
  fontSize = hdpx(12)
  transform = {}
  animations = [
    { prop=AnimProp.scale, from=[1.2, 1.2], duration=0.1, play=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=0, to=1, duration=0.1, play=true, easing=OutCubic }
    { prop=AnimProp.scale, to=[0, 0], duration=0.1, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
}

local function mkSpeaker(name) {
  return {
    flow = FLOW_HORIZONTAL
    valing = ALIGN_BOTTOM
    gap = sh(0.2)
    children = [
      speakingIcon
      {
        color = speakingColor
        fontSize = hdpx(12)
        font = Fonts.small_text
        text = name
        rendObj = ROBJ_DTEXT
      }
    ]
  }
}

local function mapTable(table, func= @(v) v){
  local ret = []
  foreach (k,v in table)
    ret.append(func(k))
  return ret
}

return @() {
  flow = FLOW_VERTICAL
  gap = sh(0.2)
  margin = [verPadding.value, hdpx(10) + horPadding.value]
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
  rendObj = ROBJ_WORLD_BLUR_PANEL
  zOrder = Layers.Tooltip
  size = SIZE_TO_CONTENT
  watch = [speakingPlayers, horPadding, verPadding]
  children = mapTable(speakingPlayers.value, @(name) mkSpeaker(remap_nick(name)))
}
 