local debug = require("std/log.nut")().with_prefix("[SPAWN]")
local {logerr} = require("dagor.debug")
local {EventAnyEntityDied} = require("deathevents")
local {DM_PROJECTILE, DM_MELEE, DM_EXPLOSION, DM_ZONE, DM_COLLISION, DM_HOLD_BREATH, DM_FIRE, DM_BACKSTAB, DM_DISCONNECTED, DM_BARBWIRE} = require("dm")

local victimSquadQuery = ::ecs.SqQuery("victimSquadQuery", {
  comps_ro=[
    ["isAlive", ::ecs.TYPE_BOOL],
    ["squad_member.squad", ::ecs.TYPE_EID]
  ]
})

local damageTypeName = {
  [DM_PROJECTILE]  = "projectile",
  [DM_MELEE]       = "melee",
  [DM_EXPLOSION]   = "explosion",
  [DM_ZONE]        = "zone",
  [DM_COLLISION]   = "collision",
  [DM_HOLD_BREATH] = "asphyxia",
  [DM_FIRE]        = "fire",
  [DM_DISCONNECTED]= "disconnected",
  [DM_BACKSTAB]    = "backstab",
  [DM_BARBWIRE]    = "barbwire"
}

local function onSoldierDeath(evt, eid, comp) {
  local victimEid = evt[0]
  local victimSquadEid = evt[3]
  local victimPlayerEid = ::ecs.get_comp_val(victimSquadEid, "squad.ownerPlayer", INVALID_ENTITY_ID)
  local offenderEid = evt[1]
  local offenderPlayerEid = evt[4]
  local deathDesc = evt[6]

  if (eid != victimPlayerEid || !::ecs.g_entity_mgr.doesEntityExist(victimSquadEid))
    return

  if (!::ecs.get_comp_val(victimSquadEid, "squad.isAlive", false))
    return

  local aliveSquadMembers = 0
  victimSquadQuery.perform(function(eid, comp) {
    ++aliveSquadMembers
  }, "and(eq(isAlive,true),eq(squad_member.squad,{0}:eid))".subst(victimSquadEid))

  local damageName = damageTypeName?[deathDesc.damageType] ?? $"{deathDesc.damageType}"
  debug($"Soldier is dead {victimEid} player <{victimPlayerEid}>: Damage: {damageName} Squad: {victimSquadEid}; Offender: {offenderEid} <{offenderPlayerEid}>; Left: {aliveSquadMembers}")

  if (aliveSquadMembers == 0) {
    ::ecs.set_comp_val(victimSquadEid, "squad.isAlive", false)

    local revivePoints = comp["squads.revivePointsPerSquad"]

    local squadsCount = comp["squads.revivePointsList"].len()
    for (local i = 0; i < squadsCount; ++i)
      comp["squads.revivePointsList"][i] = min(comp["squads.revivePointsList"][i] + revivePoints, 100)

    debug("Heal all squads by {0}. Player: {1}".subst(revivePoints, victimPlayerEid))

    local squadIdx = ::ecs.get_comp_val(victimSquadEid, "squad.id")
    if (squadIdx >= 0 && squadIdx < squadsCount) {
      comp["squads.revivePointsList"][squadIdx] = comp["squads.revivePointsAfterDeath"]
      debug("Squad {0}({1}) is dead; Player: {2}".subst(squadIdx, victimSquadEid, victimPlayerEid))
    }
    else
      logerr($"Squad {squadIdx} does not exist. There are only {squadsCount} squads.")
  }
}

local function validateSoldierRevivePoints(playerEid, squadIdx, soldierIdx, points, heal, afterDeath) {
  if (squadIdx < 0 || squadIdx >= points.len())
    logerr($"Squad {squadIdx} does not exist in soldier_revive_points.points for player {playerEid}. There are only {points.len()} squads.")
  else if (squadIdx >= heal.len())
    logerr($"Squad {squadIdx} does not exist in soldier_revive_points.healPerSquadmate for player {playerEid}. There are only {heal.len()} squads.")
  else if (soldierIdx < 0 || soldierIdx >= points[squadIdx].len())
    logerr($"soldier_revive_points.points has no respawn points for soldier {soldierIdx} in squad {squadIdx} for player {playerEid}. Total: {points[squadIdx].len()}.")
  else if (squadIdx >= afterDeath.len())
    logerr($"Squad {squadIdx} does not exist in soldier_revive_points.afterDeath for player {playerEid}. There are only {afterDeath.len()} squads.")
  else
    return true
  return false
}

local function onSoldierDeathRevivePoints(evt, eid, comp) {
  local victimEid = evt[0]
  local victimSquadEid = evt[3]
  local victimPlayerEid = ::ecs.get_comp_val(victimSquadEid, "squad.ownerPlayer", INVALID_ENTITY_ID)
  local squadIdx = ::ecs.get_comp_val(victimSquadEid, "squad.id")
  local soldierIdx = ::ecs.get_comp_val(victimEid, "soldier.id")

  if (eid != victimPlayerEid)
    return

  local revivePointsBySquad = comp["soldier_revive_points.points"]
  local healBySquad = comp["soldier_revive_points.healPerSquadmate"]
  local pointsAfterDeath = comp["soldier_revive_points.afterDeath"]

  if (!validateSoldierRevivePoints(victimPlayerEid, squadIdx, soldierIdx, revivePointsBySquad, healBySquad, pointsAfterDeath))
    return

  local revivePoints = revivePointsBySquad[squadIdx]
  local heal = healBySquad[squadIdx]

  foreach (i, curPoints in revivePoints)
    revivePoints[i] = min(curPoints + heal, 100)
  debug("Heal all soldiers by {0}. Player: {1}".subst(heal, victimPlayerEid))

  revivePoints[soldierIdx] = pointsAfterDeath[squadIdx]

  comp["soldier_revive_points.points"][squadIdx] = revivePoints
}

::ecs.register_es("squad_revive_es",
  { [EventAnyEntityDied] = onSoldierDeath },
  {
    comps_rw = [
      ["squads.revivePointsAfterDeath", ::ecs.TYPE_INT],
      ["squads.revivePointsPerSquad", ::ecs.TYPE_INT],
      ["squads.revivePointsList", ::ecs.TYPE_ARRAY],
    ]
  },
  { tags="server" })

::ecs.register_es("soldier_revive_es",
  { [EventAnyEntityDied] = onSoldierDeathRevivePoints },
  {
    comps_ro = [
      ["soldier_revive_points.healPerSquadmate", ::ecs.TYPE_ARRAY],
      ["soldier_revive_points.afterDeath", ::ecs.TYPE_ARRAY],
    ]
    comps_rw = [
      ["soldier_revive_points.points", ::ecs.TYPE_ARRAY],
    ]
  },
  { tags="server" }) 