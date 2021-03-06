local {localPlayerEid} = require("ui/hud/state/local_player.nut")
local {squad_orders} = require("enlisted/ui/hud/state/squad_orders.nut")
local {MY_SQUAD_TEXT_COLOR} = require("ui/hud/style.nut")
local {ESO_DEFEND_POINT} = require("ai")
local moveto = Picture("!ui/skin#moveto.svg")

local persistentColor = Color(64, 64, 255, 255)

local animations = [
  { prop=AnimProp.scale, from=[4,4], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.scale, from=[0.9, 0.9], to=[1.1, 1.1], duration=2, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.rotate, from=0, to=360, duration=20, play=true, loop=true }
  { prop=AnimProp.scale, from=[4,4], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true}
]

local minimapSquadOrders = Computed(function() {
  local orders = squad_orders.value
  local playerEid = localPlayerEid.value
  local components = []
  foreach (eid, orderData in orders) {
    if (eid != playerEid)
      continue
    local persistent = orderData?.persistent
    if (orderData.orderType == ESO_DEFEND_POINT) {
      local size = [sh(2.5), sh(2.5)]
      local orderIcon = {
        rendObj = ROBJ_IMAGE
        image = moveto
        size = size
        color = persistent ? persistentColor : MY_SQUAD_TEXT_COLOR
        transform = { pivot = [0.5, 0.5] }
        key = eid
        animations = persistent ? null : animations
      }
      components.append({
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        data = {
          worldPos = orderData.orderPosition
          clampToBorder = true
        }
        transform = {}
        children = orderIcon
      })
    }
  }
  return components
})


return ::Computed(function() {
  return { ctor = @(o) minimapSquadOrders.value }
})
 