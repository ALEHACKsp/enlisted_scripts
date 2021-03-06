local respawnState = require("enlisted/ui/hud/state/respawnState.nut")
local respawn_member = require("respawn_member.ui.nut")
local respawn_squad = require("respawn_squad.ui.nut")
local needSpawnMenu = respawnState.needSpawnMenu
local {setMenuVisibility} = require("ui/hud/hud_menus.nut")

local actualShowSpawnMenu = ::Computed(@() needSpawnMenu.value)
needSpawnMenu.subscribe(@(v) setMenuVisibility("Respawn", v))
actualShowSpawnMenu.subscribe(function(v) {
  if (v)
    respawnState.updateSpawnSquadId()
})

local function respawnBlock() {
  local children = !actualShowSpawnMenu.value ? null
    : !respawnState.canChangeRespawnParams.value ? null
    : respawnState.respawnsInBot.value ? respawn_member
    : respawn_squad
  return {
    size = flex()
    watch = [
      respawnState.canChangeRespawnParams
      actualShowSpawnMenu
      respawnState.respawnsInBot
    ]
    children = children
  }
}

return respawnBlock
 