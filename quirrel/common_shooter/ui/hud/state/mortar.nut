local isMortarMode = Watched(false)

::ecs.register_es("mortar_mode_ui_es",
  {
    [["onInit", "onChange"]] = @(evt, eid, comp) isMortarMode(comp["human_weap.mortarMode"])
    function onDestroy(evt, eid, comp) {
      isMortarMode(false)
    }
  },
  {
  comps_track = [
    ["human_weap.mortarMode", ::ecs.TYPE_BOOL],
  ]
  comps_rq = ["hero","watchedByPlr"]
})

return {
  isMortarMode = isMortarMode
} 