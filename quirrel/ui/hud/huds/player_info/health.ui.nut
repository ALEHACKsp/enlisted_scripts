local healthBar = require("mk_health_bar.nut")
local {hp, maxHp, scaleHp} = require("ui/hud/state/hero_state_es.nut")
local {hitAnimTrigger} = require("ui/hud/state/hit_anim_trigger_es.nut")
local {barHeight, barWidth} = require("style.nut")

local prevMaxHp = maxHp.value
maxHp.subscribe(function(maxHpValue) {
  if (maxHpValue > 0 && hp.value > 0)
    ::anim_start("hero_max_hp_changed")
  prevMaxHp = maxHpValue
})

local health = @() {
  watch = [hp, maxHp, scaleHp]
  size = [barWidth, barHeight]
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  children = healthBar({ hp = hp.value, maxHp = maxHp.value,
    scaleHp = scaleHp.value, hitTrigger = hitAnimTrigger, maxHpTrigger = "hero_max_hp_changed" })
}
return health 