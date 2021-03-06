local { tipCmp } = require("ui/hud/huds/tips/tipComponent.nut")
local { DEFAULT_TEXT_COLOR } = require("ui/hud/style.nut")
local { useActionAvailable } = require("ui/hud/state/actions_state.nut")
local { requestAmmoTimeout } = require("enlisted/ui/hud/state/requestAmmoState.nut")
local { secondsToString } = require("utils/time.nut")
local { ACTION_REQUEST_AMMO } = require("hud_actions")

local actions = {
  [ACTION_REQUEST_AMMO] = { hintText = @(time) ::loc("hud/ammo_requst_cooldown", "Ammo requst cooldown: {time} left", {time = time}) },
}

return function () {
  local tip = null

  local action = actions?[useActionAvailable.value]
  if (requestAmmoTimeout.value > 0 && action != null) {
    tip = tipCmp({
      text = action.hintText(secondsToString(requestAmmoTimeout.value))
      textColor =  DEFAULT_TEXT_COLOR
    })
  }

  return {
    watch = [
      requestAmmoTimeout
    ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = tip
  }
} 