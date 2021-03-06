local localPlayerEid = persist("eid", @() ::Watched(INVALID_ENTITY_ID))
local wallPostersMaxCount = persist("wallPostersMaxCount", @() ::Watched(0))
local wallPostersCurCount = persist("wallPostersCurCount", @() ::Watched(0))
local wallPosterPreview = persist("wallPosterPreview", @() ::Watched(false))
local wallPosters = persist("wallPosters", @() :: Watched([]))

local state = {
  wallPostersMaxCount = wallPostersMaxCount
  wallPostersCurCount = wallPostersCurCount
  wallPosterPreview = wallPosterPreview
  wallPosters = wallPosters
}

local function resetData() {
  localPlayerEid.update(INVALID_ENTITY_ID)
  wallPostersMaxCount(0)
  wallPostersCurCount(0)
  wallPosterPreview(false)
  wallPosters([])
}

local function trackComponents(evt, eid, comp) {
  if (comp.is_local) {
    localPlayerEid.update(eid)
    wallPostersMaxCount.update(comp["wallPosters.maxCount"])
    wallPostersCurCount.update(comp["wallPosters.curCount"])
    wallPosterPreview.update(comp["wallPoster.preview"])
    wallPosters.update(comp["wallPosters"].getAll())
  } else if (localPlayerEid.value == eid) {
    resetData()
  }
}

local function onDestroy(evt, eid, comp) {
  if (localPlayerEid.value == eid)
    resetData()
}

::ecs.register_es("wallposter_state_es", {
    onChange = trackComponents
    onInit = trackComponents
    onDestroy = onDestroy
  },
  {
    comps_track = [
      ["is_local", ::ecs.TYPE_BOOL],
      ["wallPosters.maxCount", ::ecs.TYPE_INT],
      ["wallPosters.curCount", ::ecs.TYPE_INT],
      ["wallPoster.preview", ::ecs.TYPE_BOOL],
      ["wallPosters", ::ecs.TYPE_ARRAY]
    ]
    comps_rq = ["player"]
  }
)

return state 