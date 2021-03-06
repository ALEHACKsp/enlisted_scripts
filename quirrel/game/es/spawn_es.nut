local { TEAM_UNASSIGNED } = require("team")
local debug = require("std/log.nut")().with_prefix("[SPAWN]")
local {CmdSpawnSquad} = require("respawnevents")
local {get_sync_time} = require("net")
local {get_team_eid} = require("globals/common_queries.nut")
local {spawnSoldier,rebalance} = require("game/utils/spawn.nut")

local function onSpawn(evt, eid, comp) {
  local team = evt[0]
  local possessed = evt[1]

  if (possessed != INVALID_ENTITY_ID)
    team = rebalance(team, eid)

  if (team == TEAM_UNASSIGNED) {
    debug($"onSpawnSquad: Cannot create player possessed entity for team {team}")
    return
  }

  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  debug($"onSpawn: Team = {team}")

  if (teamEid == INVALID_ENTITY_ID) {
    debug($"onSpawnSquad: Cannot create player possessed entity for team {team} because of teamEid is invalid")
    return
  }

  spawnSoldier({team = team, playerEid = eid, possessed = possessed})

  if (comp["scoring_player.firstSpawnTime"] <= 0.0)
    comp["scoring_player.firstSpawnTime"] = get_sync_time()
}

::ecs.register_es("spawn_es", {
    [CmdSpawnSquad] = onSpawn,
  },
  { comps_rw = [["scoring_player.firstSpawnTime", ::ecs.TYPE_FLOAT]],
    comps_no = ["customSpawn"]
  })
 