local {selfHealMedkits, selfReviveMedkits} = require("ui/hud/state/total_medkits.nut")
local {hp, maxHp, isAlive, isDowned} = require("ui/hud/state/hero_state_es.nut")
local {isBurning} = require("ui/hud/state/burning_state_es.nut")
local {canSelfReviveByHealing} = require("ui/hud/state/downed_state.nut")
local {get_time_msec} = require("dagor.time")
local {medkitEndTime} = require("ui/hud/state/entity_use_state.nut")
local timeState = require("ui/hud/state/time_state.nut")
local uiTime = require("ui/hud/state/ui_time.nut").curTimePerSec
local {tipCmp} = require("tipComponent.nut")

local color0 = Color(200,40,40,110)
local color1 = Color(200,200,40,180)
const stopAnimateAfter = 15
const hideAfter = 25

local needUseMed = ::Computed(function() {
  local ctime = timeState.curTime.value
  local needSelfHeal = selfHealMedkits.value > 0 && (hp.value > 0 && maxHp.value > 0 && (hp.value / maxHp.value < 0.85))
  local needSelfRevive = isDowned.value && canSelfReviveByHealing.value && selfReviveMedkits.value > 0
  return (needSelfHeal || needSelfRevive) && isAlive.value && (medkitEndTime.value < ctime) && !isBurning.value
})

local showedMedTipAtTime = persist("showedMedTipAtTime", @()::Watched(0))
needUseMed.subscribe(function(need) {
  if (need)
    showedMedTipAtTime((get_time_msec()/1000).tointeger())
  else
    showedMedTipAtTime(0)
})

local trigger = {}
local tip = tipCmp({
  inputId = "Inventory.UseMedkit"
  text = ::loc("tips/need_medkit")
  sound = {
    attach = {name="ui/need_reload", vol=0.1}
  }
  textColor = Color(200,40,40,110)
  transform = {pivot=[0,0.5]}
  animations = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack}]
  textAnims = [
    { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull, trigger = trigger}
    { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull, trigger = trigger}
  ]
})
local function htip(){
  return {
    size = SIZE_TO_CONTENT
    watch = [showedMedTipAtTime, uiTime]
    children = (showedMedTipAtTime.value > uiTime.value - hideAfter) ? tip : null
  }
}

local oldTotal = 0
selfHealMedkits.subscribe(function(v){
  if (v > oldTotal)
    ::anim_start(trigger)
  oldTotal = v
})
uiTime.subscribe(function(time){
  if (!needUseMed.value)
    return
  if (showedMedTipAtTime.value + stopAnimateAfter < time)
    ::anim_skip(trigger)
  else
    ::anim_start(trigger)
})

return function() {
  return {
    watch = [needUseMed]
    size = SIZE_TO_CONTENT
    children = !needUseMed.value ? null : htip
  }
}
 