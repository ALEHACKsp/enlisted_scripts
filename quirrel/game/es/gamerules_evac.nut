local {CmdSpawnEntity} = require("gameevents")
local {EventTeamWon} = require("teamevents")
local {EventZoneCaptured, EventZoneIsAboutToBeCaptured} = require("zoneevents")
local {restore_ammo} = require("human_weap")
/*
  in short - we need to rework this
  it should be simpler - on capture zone we create some entity per player
  or components per player
  than es that listens to this entities - restore their health\ammo and to respawn if they dead
  onTimer or onUpdate - doesnt matter
*/

local playersQuery = ::ecs.SqQuery("playersQuery", {comps_ro=["team", "possessed", "player"]} )
local function onTimer(evt, eid, comp) {
//intention was to spawn players one be one, but it is not work since remove of components. Need to be remade completely
  local team_id = comp["team.id"]
  log("on timer", eid)
  playersQuery.perform(function(player_eid, player_comp){
    local possesed_eid = player_comp["possessed"]
    log("restoring player", eid)
    ::ecs.set_comp_val(possesed_eid, "isVanquished", false)
    if (::ecs.get_comp_val(possesed_eid, "isAlive", true)) {
      ::ecs.set_comp_val(possesed_eid, "hitpoints.hp", ::ecs.get_comp_val(possesed_eid, "hitpoints.maxHp", 1.0))
      restore_ammo(possesed_eid)
    }
    else
      ::ecs.g_entity_mgr.sendEvent(player_eid, CmdSpawnEntity())
  }, "eq(team, {0})".subst(team_id))
}


local onZoneCapturedQuery = ::ecs.SqQuery("onZoneCapturedQuery", {comps_ro = [["name", ::ecs.TYPE_STRING]], comps_rq=["capzone.evac_checkpoint"]})
local function onZoneCaptured(evt, eid, comp) {
  local teamId = evt[1]
  if (teamId != comp["team.id"])
    return
  local zoneEid = evt[0]
  if (!::ecs.get_comp_val(zoneEid, "capzone.evac_checkpoint"))
    return
  comp["team.roundScore"] = comp["team.roundScore"] + 1 // maybe ++ will do, need to look at it
  local nextCp = ::ecs.get_comp_val(zoneEid, "capzone.next_checkpoint")
  if (!nextCp) {
    ::ecs.g_entity_mgr.broadcastEvent(EventTeamWon(teamId))
    return
  }
  // query time!
  onZoneCapturedQuery.perform(function(nextZoneEid, comp) {
    if (comp["name"]==nextCp)
      ::ecs.g_entity_mgr.sendEvent(nextZoneEid, ::ecs.event.EventEntityActivate({activate=true}))
  })
  ::ecs.g_entity_mgr.sendEvent(zoneEid, ::ecs.event.EventEntityActivate({activate=false}))
  ::ecs.set_timer({eid=eid, id="respawn_timer", interval=0.5, repeat=false})
}

::ecs.register_es("on_evac_zone_es", {
    onInit = @(evt,eid,comp) ::ecs.clear_timer({eid=eid, id="respawn_timer"}),
    Timer = onTimer,
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = onZoneCaptured,
  },
  {
    comps_rw = [
      ["team.roundScore", ::ecs.TYPE_INT],
    ]
    comps_ro = [["team.id", ::ecs.TYPE_INT]]
  },
  {tags = "server"}
)

 