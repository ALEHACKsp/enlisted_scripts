local {EventHeroChanged} = require("gameevents")
local {debug} = require("dagor.debug")
local {get_controlled_hero, get_watched_hero} = require("globals/common_queries.nut")

/*!!!!!ATTENTION!!!!
  player != avatar(hero)
  player can change heros and avatars (by respawn or something). Avatar can be dead and than ressurrect. Player is USER. Avatar is game changeable entity.
  One avatar\hero is controlled by one player (most likely), but player can have NO Avatars for example at all.
*/

/// =====hero_eid ====
local watchedHeroEid = persist("watchedHeroEid" @() Watched(INVALID_ENTITY_ID))
local controlledHeroEid = persist("controlledHeroEid" @() Watched(INVALID_ENTITY_ID))
local watchedHeroPlayerEid = persist("watchedHeroPlayerEid" @() Watched(INVALID_ENTITY_ID))
local watchedHeroPos = persist("watchedHeroPos" @() Watched(null))

::ecs.register_es("controlled_hero_eid_init_es", {
  onInit = function(evt,eid,comp){
    if (comp.is_local)
      controlledHeroEid.update(get_controlled_hero())
  }
}, {comps_ro=[["possessed", ::ecs.TYPE_EID],["is_local", ::ecs.TYPE_BOOL]], comps_rq=["player"]})

::ecs.register_es("controlled_hero_eid_es", {//this is special es, which doesn't require any components. However, we don't need any components! we work on evt.get[0] only
  [EventHeroChanged] = function(evt,eid,comp){ local e = evt[0]; debug("controlledHeroEid = {0}".subst(e)); controlledHeroEid.update(e); }
}, {})

::ecs.register_es("watched_hero_player_eid_es", {
  onInit = function(evt,eid,comp){ watchedHeroPlayerEid.update(comp["possessedByPlr"] ?? INVALID_ENTITY_ID); }
  onChange = function(evt,eid,comp){ watchedHeroPlayerEid.update(comp["possessedByPlr"] ?? INVALID_ENTITY_ID);}
}, {comps_track=[["possessedByPlr", ::ecs.TYPE_EID]],comps_rq=[["watchedByPlr", ::ecs.TYPE_EID]]})


::ecs.register_es("watched_hero_eid_es", {
  onInit = function(evt,eid,comp){ watchedHeroEid.update(eid); }
  onDestroy = function(evt,eid,comp){ watchedHeroEid.update(get_watched_hero()); }
}, {comps_rq=[["watchedByPlr", ::ecs.TYPE_EID]]})

::ecs.register_es("watched_hero_pos_es", {
  onChange = function(evt,eid,comp){ watchedHeroPos.update(comp["transform"][3]); }
  onDestroy = function(evt,eid,comp){ watchedHeroPos.update(null); }
}, {comps_track=[["transform", ::ecs.TYPE_MATRIX]], comps_rq=[["watchedByPlr", ::ecs.TYPE_EID]]})

//=============hp_es=======
local hp = persist("hp" @() Watched(null))
local maxHp = persist("maxHp" @() Watched(0))
local scaleHp = persist("scaleHp", @() Watched(0))
local scaleStamina = persist("scaleStamina", @() Watched(0))
local isAliveState = persist("isAliveState" @() Watched(true))
local isDownedState = persist("isDownedState" @() Watched(false))

local function trackComponentsHero(evt,eid,comp) {
  local isAlive = comp["isAlive"]
  local isDowned = comp["isDowned"]
  hp(isAlive ? comp["hitpoints.hp"] : null)
  maxHp(!isDowned ? comp["hitpoints.maxHp"] : -comp["hitpoints.deathHpThreshold"])
  scaleHp(comp["hitpoints.scaleHp"])
  isAliveState(isAlive)
  isDownedState(isDowned)
  scaleStamina(comp["entity_mods.staminaBoostMult"])
}

::ecs.register_es("hero_comps_ui_es", {
  onChange=trackComponentsHero
  onInit=trackComponentsHero
}, {
  comps_track = [
    ["hitpoints.hp", ::ecs.TYPE_FLOAT],
    ["hitpoints.maxHp", ::ecs.TYPE_FLOAT],
    ["hitpoints.scaleHp", ::ecs.TYPE_FLOAT],
    ["hitpoints.deathHpThreshold", ::ecs.TYPE_FLOAT, 0.0],
    ["isAlive", ::ecs.TYPE_BOOL, true],
    ["isDowned", ::ecs.TYPE_BOOL, false],
    ["entity_mods.staminaBoostMult", ::ecs.TYPE_FLOAT, 1.0],
  ]
  comps_rq=["watchedByPlr"]
})

//=============breath_es=======
local breath_shortness = persist("breath_shortness" @() Watched(null))
local isHoldBreath = persist("isHoldBreath" @() Watched(false))
local breath_low_anim_trigger = {}
local breath_low_threshold = 0.3
local function trackComponentsBreath(evt,eid,comp){
  local isAlive = comp["isAlive"]
  if (!isAlive) {
    breath_shortness(null)
    isHoldBreath(false)
    ::anim_request_stop(breath_low_anim_trigger)
    return
  }
  isHoldBreath(comp["human_breath_sound.isHoldBreath"])
  local timer = comp["human_breath.timer"]
  local max_hold_breath_time = comp["human_breath.maxHoldBreathTime"]
  local ratio = (timer>max_hold_breath_time || (max_hold_breath_time==0)) ? 0.0 : ((max_hold_breath_time - timer) / max_hold_breath_time)

  if (max_hold_breath_time == 0)
    breath_shortness(null)
  else
    breath_shortness(ratio)

  if (!(ratio > breath_low_threshold)) {
    ::anim_start(breath_low_anim_trigger)
  } else {
    ::anim_request_stop(breath_low_anim_trigger)
  }
}

::ecs.register_es("hero_breath_ui_es",
  {
    onChange = trackComponentsBreath
    onInit = trackComponentsBreath
    onDestroy = function(evt, eid, comp) {breath_shortness(null); isHoldBreath(false)}
  },
  {
    comps_track = [
      ["human_breath.timer", ::ecs.TYPE_FLOAT, 0],
      ["isAlive", ::ecs.TYPE_BOOL, true],
      ["human_breath.maxHoldBreathTime", ::ecs.TYPE_FLOAT, 20.0],
      ["human_breath.recoverBreathMult", ::ecs.TYPE_FLOAT, 2.0],
      ["human_breath.asphyxiationTimer", ::ecs.TYPE_FLOAT, 0.0],
      ["human_breath_sound.isHoldBreath", ::ecs.TYPE_BOOL, false],
    ]
    comps_rq = ["watchedByPlr"]
  }
)

//=====export====
return {
  isAlive = isAliveState
  isDowned = isDownedState
  breath_shortness = breath_shortness
  breath_low_anim_trigger = breath_low_anim_trigger
  breath_low_threshold = breath_low_threshold
  hp = hp
  maxHp = maxHp
  scaleHp = scaleHp
  scaleStamina = scaleStamina
  watchedHeroEid = watchedHeroEid
  controlledHeroEid = controlledHeroEid
  watchedHeroPlayerEid = watchedHeroPlayerEid
  watchedHeroPos = watchedHeroPos
  isHoldBreath = isHoldBreath
}
 