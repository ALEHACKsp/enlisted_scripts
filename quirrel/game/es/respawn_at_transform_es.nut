local respawnevents = require("respawnevents")
local get_sync_time = require("net").get_sync_time
local spawnSoldier = require("game/utils/spawn.nut").spawnSoldier

local function onSpawn(evt, eid, comp) {
  spawnSoldier({team = evt[0], playerEid = eid, spawnParams = {transform = evt[1], team = evt[0]}})

  if (comp["scoring_player.firstSpawnTime"] <= 0.0)
    comp["scoring_player.firstSpawnTime"] = get_sync_time()
}

::ecs.register_es("respawn_at_transform_es", {
    [respawnevents.CmdRespawnEntity] = onSpawn,
  },
  { comps_rw = [["scoring_player.firstSpawnTime", ::ecs.TYPE_FLOAT]],
    comps_no = ["customSpawn"]
  })

 