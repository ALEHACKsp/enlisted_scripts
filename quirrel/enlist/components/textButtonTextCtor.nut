local getGamepadHotkeys = require("ui/components/getGamepadHotkeys.nut")
local {mkImageCompByDargKey} = require("ui/components/gamepadImgByKey.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local JB = require("ui/control/gui_buttons.nut")

local cache_heights = {}
local function get_height_by_font(font){
  if (!(font in cache_heights)) {
    cache_heights[font] <- ::calc_comp_size({font=font rendObj=ROBJ_DTEXT text="A"})[1]
  }
  return cache_heights[font]
}

return function(textComp, params, handler, group, sf){
  local gamepadHotkey = getGamepadHotkeys(params?.hotkeys)
  local activeKB = ((sf & S_KB_FOCUS) != 0)
  local hoverKB = ((sf  & S_HOVER) != 0 && (params?.isEnabled ?? true))
  local font = params?.font ?? Fonts.medium_text
  local height = get_height_by_font(font)
  if ((hoverKB || activeKB) && (params?.isEnabled ?? true))
    gamepadHotkey = JB.A
  if (gamepadHotkey == "")
    return textComp
  local src_margin = textComp?.margin
  local margin = (typeof(src_margin) == "array") ? clone src_margin : src_margin ?? 0
  if (typeof(margin) != "array")
    margin = [margin, margin, margin, margin]
  else if (margin.len()==2)
    margin = [margin[0], margin[1], margin[0], margin[1]]
  else if (margin.len()==1)
    margin = [margin[0], margin[0], margin[0], margin[0]]

  local gamepadBtn = mkImageCompByDargKey(gamepadHotkey, { height = height })
  local gap = height/4
  local w = height
  margin[3] = margin[3] - w/2.0 - gap
  margin[1] = margin[1] - w/2.0
  return function() {
    local ac = isGamepad.value
    return ac ? {
      size = SIZE_TO_CONTENT
      gap = gap
      flow = FLOW_HORIZONTAL
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      margin = margin
      watch = [isGamepad]
      children = [
        gamepadBtn
        textComp.__merge({margin = 0})
        activeKB ? {
            hotkeys = [["^{0}".subst(JB.A),{action=handler}]]
            group = group
          } : null
      ]
    }
    : textComp.__merge({watch=[isGamepad] margin = src_margin})
  }
} 