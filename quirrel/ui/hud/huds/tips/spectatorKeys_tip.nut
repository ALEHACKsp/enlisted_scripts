local {tipCmp} = require("tipComponent.nut")
local {hasSpectatorKeys} = require("ui/hud/state/spectator_state.nut")

local tipNext = tipCmp({
  inputId = "Spectator.Next"
})

local tipPrev = tipCmp({
  inputId = "Spectator.Prev"
})

local spectatorKeys_tip = @() {
  flow = FLOW_HORIZONTAL
  gap = ::hdpx(20)
  watch = hasSpectatorKeys
  children = hasSpectatorKeys.value ? [
    {rendObj  = ROBJ_DTEXT text = loc("hud/spectator_change_target")}
    tipPrev
    tipNext
  ] : null
}

return spectatorKeys_tip
 