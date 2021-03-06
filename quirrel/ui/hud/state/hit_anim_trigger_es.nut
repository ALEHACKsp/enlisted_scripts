local {EventOnEntityHit} = require("dm")
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local hitAnimTrigger = persist("hitAnimTrigger", @() {})

::ecs.register_es("hit_trigger_ui_es", {
  [EventOnEntityHit] = function onEntityHit(evt, eid, comp) {
      local victim_eid = evt[0]
      if (victim_eid == watchedHeroEid.value) {
        ::anim_start(hitAnimTrigger)
      }
  },
})

return {hitAnimTrigger} 