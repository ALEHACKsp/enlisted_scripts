local squadState = require("enlist/squad/squadState.nut")
local { curArmy, curCampaign } = require("enlisted/enlist/soldiers/model/state.nut")
local { matchRandomTeam } = require("enlist/quickMatchQueue.nut")

squadState.bindSquadROVar("curArmy", curArmy)
squadState.bindSquadROVar("curCampaign", curCampaign)
squadState.bindSquadROVar("isTeamRandom", matchRandomTeam) 