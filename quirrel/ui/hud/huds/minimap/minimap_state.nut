local minimapDefaultVisibleRadius = Watched(150)

::ecs.register_es("set_minimap_default_visible_radius_es", {
    function onInit(eid, comp) {
      minimapDefaultVisibleRadius.update(comp["level.minimapDefaultVisibleRadius"])
    }
  },
  {
    comps_rq = ["level"]
    comps_ro = [["level.minimapDefaultVisibleRadius", ::ecs.TYPE_INT]]
  })

return {
  mmChildrensCtors = Watched([])
  minimapDefaultVisibleRadius = minimapDefaultVisibleRadius
}
 