local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local contextCommandState = require("enlisted/ui/hud/state/contextCommandState.nut")
local {ECC_DEFEND_POINT, ECC_CANCEL, ECC_REVIVE, ECC_BRING_AMMO, ECC_ATTACK_TARGET} = require("ai")

return function () {
  local tip = null
  local orderType = contextCommandState.orderType.value
  local orderUseEntity = contextCommandState.orderUseEntity.value
  local text = null;
  switch (orderType) {
    case ECC_DEFEND_POINT:
      if (orderUseEntity != INVALID_ENTITY_ID) {
        local capZoneTag = ::ecs.get_comp_val(orderUseEntity, "capzone")
        if (capZoneTag != null) {
          local zoneName = ::loc(::ecs.get_comp_val(orderUseEntity, "capzone.caption", ""), "")
          if (zoneName.len() != 0) {
            local zoneTitle = ::ecs.get_comp_val(orderUseEntity, "capzone.title", "")
            text = ::loc("hud/control_zone_name", {tag = zoneTitle, name = zoneName})
          } else
            text = ::loc("hud/control_zone")
        } else // vehicle
          text = ::loc("squad_orders/control_vehicle")
      } else {
        text = ::loc("squad_orders/defend_point")
      }
      break
    case ECC_CANCEL:
      text = ::loc("squad_orders/cancel_order")
      break
    case ECC_REVIVE:
      text = ::loc("squad_orders/revive_me")
      break
    case ECC_BRING_AMMO:
      text=::loc("squad_orders/bring_ammo")
      break
    case ECC_ATTACK_TARGET:
      text=::loc("squad_orders/attack_target")
      break
  }

  if (text != null) {
    tip = tipCmp({
      text = text,
      inputId = "Human.ContextCommand"
      font = Fonts.small_text
    })
  }

  return {
    watch = [
      contextCommandState.orderType
      contextCommandState.orderUseEntity
    ]

    children = tip
  }
}
 