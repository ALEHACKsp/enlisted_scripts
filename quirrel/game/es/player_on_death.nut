local { TEAM_UNASSIGNED } = require("team")
local { EventPlayerPossessedEntityDied } = require("deathevents")
local { get_sync_time } = require("net")

local function onPlayerEntityDied(evt, eid, comp) {
  comp["scoring_player.deathTime"] = get_sync_time()
  if (comp.team != TEAM_UNASSIGNED)
    comp["scoring_player.deaths"] += 1
}


::ecs.register_es("scoring_player", {
    [EventPlayerPossessedEntityDied] = onPlayerEntityDied
  },
  {
    comps_rw = [
      ["scoring_player.deathTime", ::ecs.TYPE_FLOAT],
      ["scoring_player.deaths", ::ecs.TYPE_INT],
    ]

    comps_ro = [
      ["possessed", ::ecs.TYPE_EID],
      ["team", ::ecs.TYPE_INT]
    ]
  },
  {tags = "server"}
)
 