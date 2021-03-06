local isBurning = Watched(false)

::ecs.register_es("hero_state_burning_es",
  {
    [["onInit", "onChange"]] = @(eid, comp) isBurning(comp["burning.isBurning"]),
    onDestroy = @(eid, comp) isBurning(false)
  },
  {
    comps_rq = ["watchedByPlr"]
    comps_track = [["burning.isBurning", ::ecs.TYPE_BOOL]]
  }
)

return {isBurning} 