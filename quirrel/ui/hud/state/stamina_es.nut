local stamina = Watched(null)
local lowStamina  = Watched(false)
::ecs.register_es("hud_stamina_state_es",
  {
    [["onInit","onChange"]] = function(eid, comp){
      stamina(comp["view_stamina"])
      lowStamina(comp["view_lowStamina"])
    },
    function onDestroy(eid, comp){
      stamina(null)
      lowStamina(null)
    }
  },
  {
    comps_track = [
      ["view_stamina", ::ecs.TYPE_INT],
      ["view_lowStamina", ::ecs.TYPE_BOOL]
    ]
    comps_rq = ["watchedByPlr"]
  }
)

local staminaAnimTrigger = persist("staminaAnimTrigger", @() {})
lowStamina.subscribe(function(is_low) {
  if (is_low) {
    ::anim_start(staminaAnimTrigger)
  } else {
    ::anim_request_stop(staminaAnimTrigger)
  }
})

::console.register_command(@(value) stamina(value), $"hud.stamina")


return {
  stamina, lowStamina, staminaAnimTrigger
} 