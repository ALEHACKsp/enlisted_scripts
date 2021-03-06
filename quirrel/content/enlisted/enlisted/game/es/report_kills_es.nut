local {TEAM_UNASSIGNED} = require("team")
local dm = require_optional("dm")
if (dm == null)
  return
local {get_gun_template_by_props_id} = dm
local {find_connected_player_that_possess} = require("globals/common_queries.nut")
local {TMatrix} = require("dagor.math")

local {EventAnyEntityDied} =  require("deathevents")
/*
todo:
  - remove killerPlayerEid, victimPlayerEid, killerSquad, victimSquad from native message as they are not needed anywhere except here and we can take them here manually
*/

local function name(player, eid){
  return player
    ? ::ecs.get_comp_val(player, "name", null)
    : (eid)
      ? ::ecs.get_comp_val(eid, "killLogName")
      : null
}

local function playerTable(eid, team, squad, player_eid, isDowned=null, isLastInSquad=null, vehicle = false){
  local res = {
    eid = eid
    team = team
    squad = squad
    player_eid = player_eid
    name = name(player_eid, eid)
    vehicle = vehicle
  }
  if (isDowned)
    res.isDowned <- true
  if (isLastInSquad)
    res.lastInSquad <- true
  return res
}


local function findSquadPlayer(player_eid, squad_eid) {
  if (player_eid != INVALID_ENTITY_ID)
    return player_eid
  if (squad_eid != INVALID_ENTITY_ID) {
    local sqLeader = ::ecs.get_comp_val(squad_eid, "squad.leader", INVALID_ENTITY_ID)
    return find_connected_player_that_possess(sqLeader)
  }
  return INVALID_ENTITY_ID
}

local squadQuery = ::ecs.SqQuery("squadQuery", {comps_ro=["squad.isAlive", "squad.numAliveMembers","squad.numMembers"]})

local function onEntityDied(evt, eid, comp) {
  local victim_eid = evt[0]
  if (!::ecs.get_comp_val(victim_eid, "reportKill", true))
    return
  local killer_eid = evt[1]
  local killerSquad = evt[2]
  local victimSquad = evt[3]
  local killerPlayerEid = findSquadPlayer(evt[4], killerSquad)
  local victimPlayerEid = findSquadPlayer(evt[5], victimSquad)
  local death_desc = evt[6]

  local victimTeam  = death_desc.victimTeam

  if (victimTeam == null || victimTeam == TEAM_UNASSIGNED)
    return

  local killerTeam  = death_desc.offenderTeam

  local nodeType    = ::ecs.get_comp_val(victim_eid, "dm_parts.type")?[death_desc.collNodeId]
  local gunTplName  = get_gun_template_by_props_id(death_desc.gunPropsId)
  local gunTpl      = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(gunTplName ?? "")
  local gunName     = gunTpl?.getCompValNullable("item.name")
  local damageType  = death_desc.damageType
  local victimSquadEid = ::ecs.get_comp_val(victim_eid, "squad_member.squad", INVALID_ENTITY_ID)
  local lastInSquad = squadQuery.perform(victimSquadEid, @(eid, comp) comp["squad.numAliveMembers"]) < 2
  //FIXME! just died sodliers are still Alive. We need to store data in squad of list of alive soldiers or avoid semantic coupling other way

  ::ecs.server_msg_sink(::ecs.event.EventKillReport({
    victim = playerTable(victim_eid, victimTeam, victimSquad, victimPlayerEid,
                         ::ecs.get_comp_val(victim_eid, "isDowned", null),
                         lastInSquad, ::ecs.get_comp_val(victim_eid, "vehicle", null) ? true : false)
    killer = playerTable(killer_eid, killerTeam, killerSquad, killerPlayerEid, null, null,
                         ::ecs.get_comp_val(killer_eid, "vehicle", null) ? true : false)
    nodeType=nodeType
    damageType=damageType
    gunName=gunName
  }))

  local defTransform = TMatrix()
  local killerPos = ::ecs.get_comp_val(killer_eid, "transform", defTransform).getcol(3)
  local victimPos = ::ecs.get_comp_val(victim_eid, "transform", defTransform).getcol(3)
  log("player '{0}' ({1},{2},{3}) killed '{4}' ({5}, {6}, {7}) by '{8}' to node '{9}'".subst(name(killerPlayerEid, killer_eid),
                                                                                             killerPos.x, killerPos.y, killerPos.z,
                                                                                             name(victimPlayerEid, victim_eid),
                                                                                             victimPos.x, victimPos.y, victimPos.z,
                                                                                             gunName,
                                                                                             nodeType))
}

::ecs.register_es("report_kill_es", {
  [EventAnyEntityDied] = onEntityDied,
}, {comps_rq = [ "msg_sink" ]}, {tags="server"})
 