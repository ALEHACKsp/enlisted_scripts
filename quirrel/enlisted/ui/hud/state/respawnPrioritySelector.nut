local {needSpawnMenu, respawnGroupId, canUseRespawnbaseByType} = require("enlisted/ui/hud/state/respawnState.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local groupRespawnsGroupsQuery = ::ecs.SqQuery("groupRespawnGroupsQuery", {comps_ro=["selectedGroup", "team", "respawnIconType"]})

local function getRespawnGroups(forTeam) {
  local respawnGroups = {}
  groupRespawnsGroupsQuery(function(eid, comps) {
    if (comps.team == forTeam && comps.respawnIconType == canUseRespawnbaseByType.value)
      respawnGroups[comps.selectedGroup] <- true
  })
  return respawnGroups
}

local function updateSelectedRespawnGroup() {
  if (!needSpawnMenu.value)
    return
  local respawnGroups = getRespawnGroups(localPlayerTeam.value)
  local playerSelectedGroupExist = (respawnGroups?[respawnGroupId.value] != null)
  if (!playerSelectedGroupExist)
    respawnGroupId(-1)
}

needSpawnMenu.subscribe(@(v) updateSelectedRespawnGroup())
canUseRespawnbaseByType.subscribe(@(v) updateSelectedRespawnGroup())

::ecs.register_es("respawn_priority_es", {
  [["onInit","onDestroy","onChange"]] = @(...) updateSelectedRespawnGroup()
}, {
  comps_track = [
    ["capzone.capTeam", ::ecs.TYPE_INT],
    ["active", ::ecs.TYPE_BOOL]
  ]
})

::ecs.register_es("respawn_selector_reset_es", {
  [["onInit","onDestroy"]] = @(...) updateSelectedRespawnGroup()
}, {
  comps_rq = ["selectedGroup"]
})
 