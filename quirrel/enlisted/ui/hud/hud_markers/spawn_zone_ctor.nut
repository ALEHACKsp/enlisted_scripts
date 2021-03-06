local { respawnsInBot, canUseRespawnbaseByType, needSpawnMenu, respawnGroupId, isFirstSpawn } = require("enlisted/ui/hud/state/respawnState.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")

local spawnIconColor = Color(86,131,212,250)

local spawn_point = ::Picture("!ui/skin#spawn_point.svg")
local selected_spawn_point = ::Picture("!ui/skin#spawn_point_active.svg")

local custom_spawn_point = ::Picture("!ui/skin#custom_spawn_point.svg")
local selected_custom_spawn_point = ::Picture("!ui/skin#custom_spawn_point_active.svg")

//Temporarily same icons as spawn points icons for soldiers
local mkSpawnPointInfo = @() {
  icon = @(isSelected) isSelected ? selected_spawn_point : spawn_point
  size = @(isSelected) isSelected ? [sh(12), sh(12)] : [sh(9), sh(9)]
}

local spawnPointsTypesInfo = {
  vehicle = mkSpawnPointInfo()
  human = mkSpawnPointInfo()
}

local mkCustomSpawnPointInfo =  {
  icon = @(isSelected) isSelected ? selected_custom_spawn_point : custom_spawn_point
  size = @(isSelected) isSelected ? [sh(9), sh(9)] : [sh(6), sh(6)]
}

local mkRespawnPoint = @(isSelected, spawnIconInfo, selectedGroup, isCustom) {
  rendObj = ROBJ_IMAGE
  size = isCustom ? mkCustomSpawnPointInfo.size(isSelected) : spawnIconInfo.size(isSelected)
  pos = [0, sh(3)]
  color = spawnIconColor
  image = isCustom ? mkCustomSpawnPointInfo.icon(isSelected) : spawnIconInfo.icon(isSelected)
  behavior = [Behaviors.Projection, Behaviors.Button]
  onClick = @() isSelected ? respawnGroupId(-1) : respawnGroupId(selectedGroup)
}

local function respawn_point(eid, marker) {
  local {selectedGroup, iconType, forTeam, isCustom} = marker
  local spawnIconInfo = spawnPointsTypesInfo?[iconType] ?? spawnPointsTypesInfo.human
  return @() {
    data = {
      eid = eid
      minDistance = 0.7
      maxDistance = 15000
      distScaleFactor = 0.5
      clampToBorder = true
    }
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    transform = {}
    key = eid
    watch = [respawnGroupId, needSpawnMenu, canUseRespawnbaseByType]
    sortOrder = eid
    children = isFirstSpawn.value || respawnsInBot.value || !needSpawnMenu.value || forTeam != localPlayerTeam.value || iconType != canUseRespawnbaseByType.value ? null
                 : mkRespawnPoint(respawnGroupId.value == selectedGroup, spawnIconInfo, selectedGroup, isCustom)
  }
}

return respawn_point 