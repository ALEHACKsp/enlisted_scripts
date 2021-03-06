local { TEAM_UNASSIGNED } = require("team")
local {EventOnEntityHit, DmProjectileHitNotification,
  DM_PROJECTILE, DM_MELEE, DM_BACKSTAB, HIT_RES_DOWNED, HIT_RES_KILLED, HIT_RES_NONE, HIT_RES_NORMAL} = require("dm")
local {get_time_msec} = require("dagor.time")
local {EventHeroChanged} = require("gameevents")
local {EventAnyEntityDied} = require("deathevents")
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local frp = require("std/frp.nut")

local hitTtl = ::Watched(1.2)//animation is tripple less in duration
local killTtl = ::Watched(1.8)//animation is tripple less in duration
local worldKillTtl = ::Watched(4.0)
local showWorldKillMark = ::Watched(true)
/*
 TODO:
   EventOnEntityHit should be split to several other events
     EventOnKilledHit - means this hit killed (for killMarks)
     EventOnAliveHit - means this hit wasn't on dead.
       currently we can skip hits on if event will be received later than replication of isAlive of victim
*/
local hitMarks = persist("hits", @() ::Watched([]))
local killMarks = persist("killMarks", @() ::Watched([]))
local function mkCleanMarks(state){
  return @() state.update(state.value.filter(@(mark) (mark.time + mark.ttl*1000) > get_time_msec()))
}
{[killMarks, hitMarks].each(@(state) ::gui_scene.setInterval(5, mkCleanMarks(state)))}

local function mkRemoveHitMarkById(state, id){
  return function(){
    state.update(state.value.filter((@(mark) mark.id!=id)))
  }
}

local function addMark(hitMark, state, ttl){
  state.update(function(v){
    return v.append(hitMark.__merge({ttl=ttl}))
  })
  ::gui_scene.setTimeout(ttl, mkRemoveHitMarkById(state, hitMark.id))
}

local counter = 0

local cachedHitTtl = ::max(hitTtl.value, killTtl.value)
frp.subscribe([hitTtl,killTtl], @(_) ::max(hitTtl.value, killTtl.value))
local cachedWorldKillTtl = worldKillTtl.value
worldKillTtl.subscribe(@(v) cachedWorldKillTtl = v)
local cachedShowWorldKillMark = showWorldKillMark.value
showWorldKillMark.subscribe(@(v) cachedShowWorldKillMark = v)

local function addHitMark(hitMark){
  addMark(hitMark, hitMarks, cachedHitTtl)
}

local function addKillMark(hitMark){
  local victim = hitMark?.victimEid
  if (hitMark?.killPos == null || victim == null)
    return
  killMarks(killMarks.value.filter(@(v) v.victimEid != victim))
  addMark(hitMark, killMarks, cachedWorldKillTtl)
}
const DM_DIED = "DM_DIED"
local function onHit(victimEid, offender, extHitPos, damageType, hitRes) {
  counter++
  local time = get_time_msec()

  local hitPos = null
  local isDownedHit = hitRes == HIT_RES_DOWNED
  local isKillHit = hitRes == HIT_RES_KILLED
  local independentKill = damageType == DM_DIED
  local isMelee = [DM_BACKSTAB, DM_MELEE].indexof(damageType)!=null
  if (isMelee)
    hitPos = [extHitPos.x, extHitPos.y, extHitPos.z]
  local killPos = null
  if (isKillHit || isDownedHit || independentKill) {
    killPos = ::ecs.get_comp_val(victimEid, "transform", null)
    killPos = killPos!=null ? killPos.getcol(3) : hitPos
    hitPos = [extHitPos.x, extHitPos.y, extHitPos.z]
    killPos = [killPos.x, killPos.y+0.6, killPos.z]
  }
  local hitMark = {id=counter, victimEid = victimEid, time = time, hitPos = hitPos, hitRes = hitRes, killPos = cachedShowWorldKillMark ? killPos : null, isKillHit=isKillHit, isDownedHit=isDownedHit, isMelee = isMelee}
  if (!independentKill)
    addHitMark(hitMark)
  if (cachedShowWorldKillMark && (isKillHit || isDownedHit))
    addKillMark(hitMark)
}

local function onProjectileHit(evt, eid, comp) {
  local victimEid = evt[0]
  local hitPos = evt[1]
  local shouldShowHitMarks = ::ecs.get_comp_val(comp["human_anim.vehicleSelected"], "hitmarks.showUserHits", false)

  if (!shouldShowHitMarks || victimEid == eid)
    return

  onHit(victimEid, eid, hitPos, DM_PROJECTILE, HIT_RES_NORMAL)
}

local function onEntityHit(evt, eid, comp) {
  local victimEid = evt[0]
  local offender = evt[1]
  local dmgDesc = evt[2]
  local victimTeam = ::ecs.get_comp_val(victimEid, "team", TEAM_UNASSIGNED)

  if (offender != watchedHeroEid.value || victimEid == offender ||
      victimTeam == TEAM_UNASSIGNED || dmgDesc.deltaHp <= 0)
    return

  local hitRes = evt[3]
  if (hitRes != HIT_RES_NONE)
    onHit(victimEid, offender, dmgDesc.hitPos, dmgDesc.damageType, hitRes)
}

local function onEntityDied(evt, eid, comp) {
  local victimEid = evt[0]
  local offender = evt[1]
  local victimTeam = ::ecs.get_comp_val(victimEid, "team", TEAM_UNASSIGNED)

  if (offender != watchedHeroEid.value || victimEid == offender || victimTeam == TEAM_UNASSIGNED)
    return

  local tm = ::ecs.get_comp_val(victimEid, "transform", null)
  onHit(victimEid, offender, tm.getcol(3), DM_DIED, HIT_RES_KILLED)
}


::ecs.register_es("script_hit_marks_es", {
    [EventOnEntityHit] = onEntityHit,
    [EventAnyEntityDied] = onEntityDied,
    [EventHeroChanged] = @(evt,eid, comp) hitMarks.update([])
  }, {}
)

::ecs.register_es("script_hit_marks_dm_es", {
    [DmProjectileHitNotification] = onProjectileHit,
  },
  { comps_ro = [["human_anim.vehicleSelected", ::ecs.TYPE_EID]],
    comps_rq = ["watchedByPlr"]
  }
)

return {
  hitMarks = hitMarks
  killMarks = killMarks
  //settings
  hitColor = ::Watched(Color(200, 200, 200, 200))
  downedColor = ::Watched(Color(200, 20, 0, 200))
  killColor = ::Watched(Color(200, 0, 0, 200))
  worldKillMarkColor = ::Watched(Color(180, 20, 20, 170))
  worldDownedMarkColor = ::Watched(Color(230, 120, 30, 170))
  hitSize = ::Watched([sh(3),sh(3)])
  killSize = ::Watched([sh(3.5),sh(3.5)])
  worldKillMarkSize = ::Watched([sh(2.5),sh(2.5)])
  showWorldKillMark = showWorldKillMark
  hitTtl = hitTtl
  killTtl = killTtl
  worldKillTtl = worldKillTtl
}
 