local {ESO_FOLLOW_ME} = require("ai")
local {localPlayerTeam, localPlayerEid} = require("ui/hud/state/local_player.nut")
local orders = Watched({})
local persistentOrders = Watched({})

local function deleteEid(eid, state){
  if (eid in state.value && eid != INVALID_ENTITY_ID)
    state.update(@(v) delete v[eid])
}
::ecs.register_es("squad_orders_ui_es",
  {
    [["onInit", "onChange"]] = function(evt, eid, comp) {
      local playerEid = comp["squad.ownerPlayer"]
      if (playerEid != localPlayerEid.value) {
        deleteEid(playerEid, orders)
        return
      }
      orders.update(function(value) {
        value[playerEid] <- {
          team = localPlayerTeam.value
          leader = comp["squad.leader"]
          orderType = comp["squad.orderType"]
          orderPosition = comp["squad.orderPosition"]
          persistent = false
        }
      })
    },
    function onDestroy(evt, eid, comp) {
      deleteEid(comp["squad.ownerPlayer"], orders)
    }
  },
  {
    comps_track = [
      ["squad.ownerPlayer", ::ecs.TYPE_EID],
      ["squad.leader", ::ecs.TYPE_EID],
      ["squad.orderType", ::ecs.TYPE_INT],
      ["squad.orderPosition", ::ecs.TYPE_POINT3],
    ]
  }
)

::ecs.register_es("squad_persistent_orders_ui_es",
  {
    [["onInit", "onChange"]] = function(evt, eid, comp) {
      local orderType = comp["persistentSquadOrder.orderType"]
      if (orderType == ESO_FOLLOW_ME) {
        deleteEid(eid, persistentOrders)
        return
      }
      persistentOrders.update(function(value) {
        value[eid] <- {
          team = comp["team"]
          leader = comp["possessed"]
          orderType = orderType
          orderPosition = comp["persistentSquadOrder.orderPosition"]
          persistent = true
        }
      })
    }
  },
  {
    comps_track = [
      ["team", ::ecs.TYPE_INT],
      ["possessed", ::ecs.TYPE_EID],
      ["persistentSquadOrder.orderType", ::ecs.TYPE_INT],
      ["persistentSquadOrder.orderPosition", ::ecs.TYPE_POINT3],
    ]
  }
)

return {
  squadOrders = orders
  persistentSquadOrders = persistentOrders
  squad_orders = Computed(@() orders.value.__merge(persistentOrders.value))
}
 