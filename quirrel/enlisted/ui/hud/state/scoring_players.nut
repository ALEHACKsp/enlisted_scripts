local { TEAM_UNASSIGNED } = require("team")
local remap_nick = require("globals/remap_nick.nut")
local state = persist("players", @() Watched({}) )
local { get_time_msec } = require("dagor.time")


local calcScore = @(comp) 30 * comp["scoring_player.kills"]
  + 100 * comp["scoring_player.tankKills"]
  + 175 * comp["scoring_player.planeKills"]
  + 15 * comp["scoring_player.assists"]
  + 50 * comp["scoring_player.captures"]
  + 15 * comp["scoring_player.defenseKills"]

local trackComponents = @(evt, eid, comp)
  state(@(value) value[eid] <- comp.__merge({
    name = remap_nick(comp.name)
    score = calcScore(comp)
    lastUpdate = get_time_msec()
  }))

local function onInit(evt, eid, comp) {
  trackComponents(evt, eid, comp)
}


local function onDestroy(evt, eid, comp) {
  state.update(function(value) {
    delete value[eid]
  })
}



::ecs.register_es("scoring_players_ui_es",
  {
    onInit=onInit
    onDestroy=onDestroy
    onChange=trackComponents
  },
  {
    comps_ro = [
      ["name", ::ecs.TYPE_STRING],
    ]
    comps_track = [
      ["team", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["disconnected", ::ecs.TYPE_BOOL],
      ["scoring_player.kills", ::ecs.TYPE_INT],
      ["scoring_player.tankKills", ::ecs.TYPE_INT],
      ["scoring_player.planeKills", ::ecs.TYPE_INT],
      ["scoring_player.assists", ::ecs.TYPE_INT],
      ["scoring_player.captures", ::ecs.TYPE_INT],
      ["scoring_player.squadDeaths", ::ecs.TYPE_INT],
      ["scoring_player.defenseKills", ::ecs.TYPE_INT],
      ["possessed", ::ecs.TYPE_EID],
    ]
  }
)



return state
 