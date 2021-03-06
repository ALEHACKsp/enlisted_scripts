local frp = require("std/frp.nut")
local ipc_hub = require("ui/ipc_hub.nut")
local { localPlayerTeamArmy } = require("enlisted/ui/hud/state/teams.nut")
local { localPlayerEid } = require("ui/hud/state/local_player.nut")
local { get_setting_by_blk_path } = require("settings")

local defaultArmiesData = require("enlisted/game/data/default_client_profile.nut")

local armiesData = persist("armiesData", @() Watched(null))

ipc_hub.subscribe("updateArmiesData", @(msg) armiesData(msg.data))

local requestArmiesData = (get_setting_by_blk_path("disableMenu") ?? false)
  ? @(army, playerEid) ::ecs.client_send_event(playerEid, ::ecs.event.CmdSquadsData({jwt=""})) // Non empty event payload table as otherwise 'fromconnid' won't be added
  : @(army, playerEid) ipc_hub.send({ msg = "requestArmiesData", army = army, playerEid = playerEid })

frp.subscribe([localPlayerTeamArmy, localPlayerEid], function(_) {
  local teamArmy = localPlayerTeamArmy.value
  local playerEid = localPlayerEid.value
  if (teamArmy != "" && playerEid != INVALID_ENTITY_ID)
    requestArmiesData(teamArmy, playerEid)
})

local armyData = Computed(function() {
  local teamArmy = localPlayerTeamArmy.value
  return armiesData.value?[teamArmy] ?? defaultArmiesData?[teamArmy]
})

return armyData
 