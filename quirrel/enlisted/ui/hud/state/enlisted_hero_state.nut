local isRadioMode = persist("isRadioMode", @() Watched(false))

::ecs.register_es("hero_state_radio_mode_es",
  {
    [["onInit", "onChange"]] = @(evt, eid, comp) isRadioMode(comp["human_weap.radioMode"])
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["human_weap.radioMode", ::ecs.TYPE_BOOL]]
  }
)

return {
  isRadioMode = isRadioMode
} 