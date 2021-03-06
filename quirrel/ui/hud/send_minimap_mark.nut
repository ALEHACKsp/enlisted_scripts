local {localPlayerEid} = require("ui/hud/state/local_player.nut")

local function command(event, minimapState){
  local rect = event.targetRect
  local elemW = rect.r - rect.l
  local elemH = rect.b - rect.t
  local relX = (event.screenX - rect.l - elemW*0.5) * 2 / elemW
  local relY = (event.screenY - rect.t - elemH*0.5) * 2 / elemH
  local worldPos = minimapState.mapToWorld(relY, relX) // take care of rotation
  ::ecs.g_entity_mgr.sendEvent(localPlayerEid.value, ::ecs.event.CmdCreateMapPoint({x = worldPos.x, z = worldPos.z}))
}

return command 