local ipc_hub = require("ui/ipc_hub.nut")
local { reward_single_player_mission } = require("enlisted/enlist/meta/clientApi.nut")

local function chargeExp(data) {
  local { singleMissionRewardId, armyId, squadsExp, soldiersExp } = data
  reward_single_player_mission(singleMissionRewardId, armyId, squadsExp.keys(), soldiersExp.keys())
}

ipc_hub.subscribe("charge_battle_exp_rewards", @(msg) chargeExp(msg.data))
 