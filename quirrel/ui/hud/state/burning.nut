local burningState = persist("putOutFireState", @() Watched({
  isPuttingOut = false
  force = 0.0
  maxForce = 0.0
}))

local function resetState() {
  burningState({
    isPuttingOut = false
    force = 0.0
    maxForce = 0.0
  })
}

local function trackComponents(evt, eid, comp) {
  burningState({
    force = comp["burning.force"]
    isPuttingOut = comp["burning.isPuttingOut"]
    maxForce = comp["burning.maxForce"]
  })
}

::ecs.register_es("burning_state_ui_es",
  {
    onInit = trackComponents,
    onChange = trackComponents,
    onDestroy = @(...) resetState(),
  },
  {
    comps_ro = [
      ["burning.maxForce", ::ecs.TYPE_FLOAT],
    ]
    comps_track = [
      ["burning.force", ::ecs.TYPE_FLOAT],
      ["burning.isPuttingOut", ::ecs.TYPE_BOOL]
    ]
    comps_rq = ["hero"]
  }
)

return burningState 