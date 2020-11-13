local { TEAM_UNASSIGNED } = require("team")
local {get_gun_stat_type_by_props_id, DM_MELEE, DM_PROJECTILE, DM_BACKSTAB} = require("dm")
local is_teams_friendly = require("globals/is_teams_friendly.nut")
local {userstatsSend} = require("game/utils/userstats.nut")
local regions = require("game.regions")
local {Point2, TMatrix} = require("dagor.math")
local {EventBotKilledEntity,EventPlayerKilledEntity} = require("deathevents")
local {find_local_player} = require("globals/common_queries.nut")
local {INVALID_CONNECTION_ID, has_network} = require("net")

local idCounter = persist("idCounter", @() { val = 0 })
local killSeqInfo = persist("killSeqInfo", @() {})
local {INVALID_USER_ID} = require("matching.errors")

local function cacheUserStat(statName, userstats_mode) {
  if (statName in userstats_mode.getAll())
    userstats_mode[statName] = userstats_mode[statName] + 1
  else
    userstats_mode[statName] <- 1
}

local function sendAward(awardType, params=null, userstats_mode = null) {
  if (params && "userid" in params && "mode" in params && params.userid != INVALID_USER_ID) {
    local stats = {}
    stats[awardType] <- 1
    userstatsSend(params.userid, stats, params.mode)
  }
  if (userstats_mode != null) {
    cacheUserStat(awardType, userstats_mode)
    if ((params?.mode ?? "") != "")
      cacheUserStat($"{awardType}_{params?.mode}", userstats_mode)
  }
}


local getConnectionsToSendQuery = ::ecs.SqQuery("getConnectionsToSendQuery", {comps_ro = [["connid", ::ecs.TYPE_INT, INVALID_CONNECTION_ID]]})
local getConnToSend = @(playerEid) has_network()
  ? (getConnectionsToSendQuery.perform(playerEid, @(_, comp) comp["connid"]) ?? INVALID_CONNECTION_ID)
  : find_local_player() == playerEid
    ? playerEid
    : INVALID_CONNECTION_ID

local function addAward(playerEid, awardType, params=null, userstats_mode = null) {
  sendAward(awardType, params, userstats_mode)

  local connectionsToSend = getConnToSend(playerEid)
  ::ecs.server_send_net_sqevent(playerEid, ::ecs.event.CmdSendAward({award=awardType}), [connectionsToSend])
}

local function checkSequentialKill(killer_player_eid, seq_kill_time, userstats_mode = null) {
  local rec = killSeqInfo?[killer_player_eid]
  if (rec) {
    ::ecs.clear_callback_timer(rec.timer)
    ++rec.n
  }
  else {
    rec = { n = 1, timer = null }
    killSeqInfo[killer_player_eid] <- rec
  }

  if (rec.n == 2) {
    addAward(killer_player_eid, "double_kill", userstats_mode)
  } else if (rec.n == 3) {
    addAward(killer_player_eid, "triple_kill", userstats_mode)
  } else if (rec.n >= 4) {
    addAward(killer_player_eid, "multi_kill", userstats_mode)
  }

  rec.timer = ::ecs.set_callback_timer(function() {
    killSeqInfo.rawdelete(killer_player_eid)
  }, seq_kill_time, false)
}

local defTransform = TMatrix()
local incSquadKillsQuery = ::ecs.SqQuery("incSquadKillsQuery",
  {comps_rw = [["scoring_player.squadKills", ::ecs.TYPE_INT]], comps_ro = [["team", ::ecs.TYPE_INT]]}
)
local function incSquadKillsQueryF(eid, comp) {
  comp["scoring_player.squadKills"] += 1
}
local function onPlayerKilledEntity(evt, eid, comp) {
  local victimEid = evt[0]
  if (!::ecs.get_comp_val(victimEid, "reportKill", true))
    return
  local killerEid = evt[1]
  local victimPlayerEid = evt[3]
  local killerPlayerEid = evt[4]

  local killerPlayerTeam  = comp.team
  local isVictimInSquad = ::ecs.get_comp_val(victimEid, "squad_member.squad", INVALID_ENTITY_ID) != INVALID_ENTITY_ID
  local victimTeam = ::ecs.get_comp_val(victimEid, "team", TEAM_UNASSIGNED)

  local isOpponent = !is_teams_friendly(killerPlayerTeam, victimTeam)
  if (victimTeam != TEAM_UNASSIGNED && isOpponent && (victimPlayerEid!=INVALID_ENTITY_ID || isVictimInSquad )) {
    comp["scoring_player.kills"] += 1
    if (victimEid != killerEid) {
      local deathDesc = evt[2]
      local nodeType  = ::ecs.get_comp_val(victimEid, "dm_parts.type")?[deathDesc.collNodeId]
      local gunStatName = get_gun_stat_type_by_props_id(deathDesc.gunPropsId)
      local isActiveMountedGun = ::ecs.get_comp_val(victimEid, "mounted_gun.active", false)
      local isActiveMachingGunner = ::ecs.get_comp_val(victimEid, "human_attached_gun.isAttached", false)
      local killerPos = ::ecs.get_comp_val(killerEid, "transform", defTransform).getcol(3)
      local victimPos = ::ecs.get_comp_val(victimEid, "transform", defTransform).getcol(3)
      local longRangeDist = ::ecs.get_comp_val(killerEid, "awards.longRangeDist", 100.0)
      local isVictimInCar = ::ecs.get_comp_val(victimEid, "isDriver", false) || ::ecs.get_comp_val(victimEid, "isPassenger", false)
      local userstats_mode = ::ecs.get_comp_val(killerPlayerEid, "userstats_mode")

      local regionName = regions.get_region_name_by_pos(Point2(victimPos.x, victimPos.z))

      local awardParams = !regionName ? null : {
        userid = comp.userid,
        mode = regionName // mode is region name in this case
      }
      if (awardParams)
        sendAward("kills", awardParams, userstats_mode)
      if (deathDesc.damageType == DM_PROJECTILE && nodeType == "head") {
        addAward(eid, "headshot", awardParams, userstats_mode)
        comp["scoring_player.headshots"]+=1
      } else if (deathDesc.damageType == DM_MELEE || deathDesc.damageType == DM_BACKSTAB) {
        addAward(eid, "melee_kill", awardParams, userstats_mode)
      }

      incSquadKillsQuery.perform(incSquadKillsQueryF, "eq(team,{0})".subst(killerPlayerTeam))
      if (isActiveMountedGun || isActiveMachingGunner)
        addAward(eid, "machinegunner_kill", awardParams, userstats_mode)

      if (isVictimInCar)
        addAward(eid, "car_driver_kills", awardParams, userstats_mode)

      if (deathDesc.damageType == DM_PROJECTILE && (killerPos - victimPos).lengthSq() > longRangeDist * longRangeDist)
        addAward(eid, "long_range_kill", awardParams, userstats_mode)

      if (gunStatName != null && gunStatName != "")
        addAward(eid, gunStatName == "grenade" ? "grenade_kill" : $"{gunStatName}_kills", awardParams, userstats_mode)

      checkSequentialKill(eid, comp.sequentialKillTime, userstats_mode)
      if (userstats_mode != null)
      ::ecs.set_comp_val(killerPlayerEid, "userstats_mode", userstats_mode)
    }
  }
}

local function onEventPlayerBotKilledEntity(evt, eid, comp) {
  local victimEid = evt.data.victim
  if (!::ecs.get_comp_val(victimEid, "reportKill", true))
    return
  local killerEid = evt.data.killer
  if (victimEid == killerEid)
    return
  comp["scoring_player.kills"] += 1
  local victimPos = ::ecs.get_comp_val(victimEid, "transform", defTransform).getcol(3)
  local regionName = regions.get_region_name_by_pos(Point2(victimPos.x, victimPos.z))
  local awardParams = !regionName ? null : {
    userid = comp.userid,
    mode = regionName // mode is region name in this case
  }

  if (awardParams)
    sendAward("kills", awardParams)
}

::ecs.register_es("kill_award_es",
  {
    [EventPlayerKilledEntity] = onPlayerKilledEntity,
    [::ecs.sqEvents.EventPlayerBotKilledEntity] = onEventPlayerBotKilledEntity
  },
  {
    comps_rw = [
      ["scoring_player.kills",  ::ecs.TYPE_INT],
      ["scoring_player.headshots", ::ecs.TYPE_INT],
      ["sequentialKillTime", ::ecs.TYPE_FLOAT],
    ]

    comps_ro = [
      ["userid", ::ecs.TYPE_INT64],
      ["team", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
    ]},
    {tags="server"})



local function onBotKilledEntity(evt, eid, comp) {
  local squadEid = comp["squad_member.squad"]
  if(squadEid != INVALID_ENTITY_ID){
    local plEid = ::ecs.get_comp_val(squadEid, "squad.ownerPlayer", INVALID_ENTITY_ID)
    if(plEid != INVALID_ENTITY_ID){
      ::ecs.g_entity_mgr.sendEvent(plEid, ::ecs.event.EventPlayerBotKilledEntity({victim=evt[0], killer = eid}))
    }
  }
}

::ecs.register_es("bot_kill_award_es", {
  [EventBotKilledEntity] = onBotKilledEntity,
}, {comps_ro = [["squad_member.squad", ::ecs.TYPE_EID]]}, {tags="server"})

::ecs.register_es("add_awards_es", {
  [::ecs.sqEvents.CmdAddAward] = function(evt, eid, comp) {
    addAward(eid, evt.data.award)
  },
}, {comps_rq = [["awards", ::ecs.TYPE_ARRAY]]}, {tags="server"})


::ecs.register_es("receive_awards_from_server_es", {
  [::ecs.sqEvents.CmdSendAward] = function(evt, eid, comp) {
    comp["awards"].append({id=++idCounter.val, type=evt.data.award})
  },
}, {comps_rw = [["awards", ::ecs.TYPE_ARRAY]]})


return {
  addAward = addAward
}
 