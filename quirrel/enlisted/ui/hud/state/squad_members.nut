local { TEAM_UNASSIGNED } = require("team")
local { watchedHeroEid } = require("ui/hud/state/hero_state_es.nut")
local { localPlayerEid } = require("ui/hud/state/local_player.nut")
local { isEqual } = require("std/underscore.nut")
local { HIT_RES_NORMAL, HIT_RES_DOWNED, HIT_RES_KILLED } = require("dm")
local {frameUpdateCounter} = require("ui/scene_update.nut")
local squadsInfo = Watched({})
local hitTriggers = {}

const HEAL_RES_COMMON = "actHealCommon"
const HEAL_RES_REVIVE = "actHealRevive"

local function getHitTrigger(id) {
  local trigger = hitTriggers?[id]
  if (trigger)
    return trigger

  trigger = {
    [HIT_RES_NORMAL] = {}, [HIT_RES_DOWNED] = {}, [HIT_RES_KILLED] = {},
    [HEAL_RES_COMMON] = {}, [HEAL_RES_REVIVE] = {}
  }
  hitTriggers[id] <- trigger
  return trigger
}


local grenadeTypeQuery = ::ecs.SqQuery("get_grenade_type_query", {
  comps_ro = [["item.grenadeType", ::ecs.TYPE_STRING]]
})

local grenadesOrder = ["antitank", "fougasse", "flame", "flash", "smoke", "signal_flare" ]
local function grenadeWeight(gType) {
  local idx = grenadesOrder.indexof(gType)
  return idx != null ? idx : grenadesOrder.len()
}

local function getGrenadeType(items) {
  local grenades = []
  foreach (itemEid in items ?? []) {
    local gType = grenadeTypeQuery.perform(itemEid, @(eid, gcomp) gcomp["item.grenadeType"])
    if ([null, "shell"].indexof(gType) == null)
      grenades.append(gType)
  }
  return grenades.sort(@(a, b) grenadeWeight(a) <=> grenadeWeight(b))?[0]
}

local watchedHeroSquadEid = Computed(@() ::ecs.get_comp_val(watchedHeroEid.value, "squad_member.squad", INVALID_ENTITY_ID))

local squadMembersQuery = ::ecs.SqQuery("squadMembersQuery", {comps_ro = [
    ["squad_member.squad", ::ecs.TYPE_EID],
    ["squad_member.memberIdx", ::ecs.TYPE_INT, -1],
    ["isAlive", ::ecs.TYPE_BOOL],
    ["isDowned", ::ecs.TYPE_BOOL],
    ["hitpoints.hp", ::ecs.TYPE_FLOAT, 1.0],
    ["hitpoints.maxHp", ::ecs.TYPE_FLOAT, 1.0],
    ["walker_agent.currentAiAction", ::ecs.TYPE_INT, 0],
    ["beh_tree.enabled", ::ecs.TYPE_BOOL, false],
    ["guid", ::ecs.TYPE_STRING, ""],
    ["name", ::ecs.TYPE_STRING, ""],
    ["surname", ::ecs.TYPE_STRING, ""],
    ["weaponPreset", ::ecs.TYPE_STRING, "--"],
    ["human_weap.weapTemplates", ::ecs.TYPE_OBJECT],
    ["human_weap.primaryOpticsAttached", ::ecs.TYPE_BOOL, false],
    ["human_weap.secondaryOpticsAttached", ::ecs.TYPE_BOOL, false],
    ["itemContainer", ::ecs.TYPE_EID_LIST],
    ["team", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["squad_member.kills", ::ecs.TYPE_INT, 0],
    ["total_kits.targetHeal", ::ecs.TYPE_INT, 0],
    ["total_kits.targetRevive", ::ecs.TYPE_INT, 0],
  ],
//  comps_rq = ["watchedSquad"]
})

local sortMembers = @(a,b) a.memberIdx <=> b.memberIdx
local watchedHerSquadMembersRaw = Watched({})
local watchedHeroSquadMembers = Computed(@() (watchedHerSquadMembersRaw.value.values() ?? []).sort(sortMembers))

local function startMemberAnimations(curState, oldState) {
  local {isAlive, isDowned, hp, squad, memberIdx} = curState
  if (oldState==null || squad != oldState.squad || memberIdx != oldState.memberIdx)
    return
  if (oldState.isAlive && !isAlive)
    ::anim_start(curState.hitTriggers[HIT_RES_KILLED])
  else if (!oldState.isDowned && isDowned)
    ::anim_start(curState.hitTriggers[HIT_RES_DOWNED])
  else if (oldState.hp > hp)
    ::anim_start(curState.hitTriggers[HIT_RES_NORMAL])
  else if (oldState.hp < hp)
    ::anim_start(curState.hitTriggers[HEAL_RES_COMMON])
  else if (oldState.isDowned && !isDowned)
    ::anim_start(curState.hitTriggers[HEAL_RES_REVIVE])
}

local function setSquadMembers(playerSquadEid, state){
  local res = {}
  squadMembersQuery.perform(
    function(eid, comp){
      local squad = comp["squad_member.squad"]
//      if (squad != playerSquadEid)
//        return
      local memberIdx = comp["squad_member.memberIdx"]
      res[memberIdx] <- {
        eid = eid
        guid = comp.guid
        name = " ".join([comp.name, comp.surname])
        isAlive = comp.isAlive
        isDowned = comp.isDowned
        hp = comp["hitpoints.hp"]
        maxHp = comp["hitpoints.maxHp"]
        weaponPreset = comp.weaponPreset
        weapTemplates = comp["human_weap.weapTemplates"]?.getAll()
        primaryOpticsAttached = comp["human_weap.primaryOpticsAttached"]
        secondaryOpticsAttached = comp["human_weap.secondaryOpticsAttached"]
        memberIdx = memberIdx
        currentAiAction = comp["walker_agent.currentAiAction"]
        hasAI = comp["beh_tree.enabled"]
        team = comp.team
        kills = comp["squad_member.kills"]
        targetHealCount = comp["total_kits.targetHeal"]
        targetReviveCount = comp["total_kits.targetRevive"]
        squad = squad

        hitTriggers = getHitTrigger(eid)
        grenadeType = getGrenadeType(comp["itemContainer"]?.getAll())
      }
    }
    $"eq(squad_member.squad, {playerSquadEid}:eid)"
  )
  local oldState = state.value
  if (playerSquadEid != oldState?[0].squad){
    state(res)
  }
  else if (!isEqual(res, oldState)){
    res.each(@(v, idx) startMemberAnimations(v, oldState?[idx]))
    state(oldState.__merge(res))
  }
}

local localPlayerSquadEid = keepref(Computed(function(){
  foreach (eid, squad in squadsInfo.value){
    if (squad.ownerPlayer == localPlayerEid.value && squad.isAlive)
      return eid
  }
  return INVALID_ENTITY_ID
}))


local localPlayerSquadMembersRaw = Watched({})
local localPlayerSquadMembers = Computed(@() (localPlayerSquadMembersRaw.value.values() ?? []).sort(sortMembers))

local setLocalPlayerSquadMember = @(curPlayerSquadEid) setSquadMembers(curPlayerSquadEid, localPlayerSquadMembersRaw)

local setWatchedPlayerSquadMember = @(curPlayerSquadEid) setSquadMembers(curPlayerSquadEid, watchedHerSquadMembersRaw)

watchedHeroSquadEid.subscribe(setWatchedPlayerSquadMember)
localPlayerSquadEid.subscribe(setLocalPlayerSquadMember)

frameUpdateCounter.subscribe(function(frame) {
  const framePeriodToUpdate = 2
  if ((frame%framePeriodToUpdate) != 0)
    setWatchedPlayerSquadMember(watchedHeroSquadEid.value)
  if (((frame+1)%framePeriodToUpdate) != 0)
    setLocalPlayerSquadMember(localPlayerSquadEid.value)
})


::ecs.register_es("player_squads_ui_es",
  {
    [["onChange", "onInit"]] = function trackSquad(eid, comp) {
      squadsInfo(function(val) {
        local isAlive = comp["squad.isAlive"]
        if (isAlive)
          val[eid]<- { isAlive = isAlive, ownerPlayer = comp["squad.ownerPlayer"] }
        else
          if (eid in val)
            delete val[eid]
      })
    },
    function onDestroy(eid, comp) {
      if (eid in squadsInfo.value)
        squadsInfo(@(v) delete v[eid])
    }
  },
  {
    comps_track = [
      ["squad.isAlive", ::ecs.TYPE_BOOL],
      ["squad.ownerPlayer", ::ecs.TYPE_EID],
    ]
  }
)

return {
  watchedHeroSquadMembers
  localPlayerSquadMembers

  HEAL_RES_COMMON
  HEAL_RES_REVIVE
}
 