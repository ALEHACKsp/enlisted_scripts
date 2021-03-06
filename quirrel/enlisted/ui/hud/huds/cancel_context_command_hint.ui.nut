local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local {inVehicle} = require("ui/hud/state/vehicle_state.nut")
local {showBigMap} = require("enlisted/ui/hud/menus/big_map.nut")
local {heroSquadNumAliveMembers, heroSquadOrderType, hasPersonalOrder} = require("enlisted/ui/hud/state/hero_squad.nut")
local {ESO_FOLLOW_ME} = require("ai")

local showTip = ::Computed(@()
  !showBigMap.value && !inVehicle.value && heroSquadNumAliveMembers.value > 1
  && (heroSquadOrderType.value != ESO_FOLLOW_ME || hasPersonalOrder.value)
)

return function () {
  local tip = !showTip.value ? null : {
    tip = tipCmp({
      text = ::loc("squad_orders/cancel_all_orders"),
      inputId = "Human.CancelContextCommand"
      font = Fonts.small_text
    })
  }

  return {
    watch = showTip
    children = tip
  }
}
 