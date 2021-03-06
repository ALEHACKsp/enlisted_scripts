local state = make_persists(persist, {
  downedEndTime = Watched(-1.0)
  alwaysAllowRevive = Watched(false)
  canBeRevivedByTeammates = Watched(false)
  canSelfReviveByHealing = Watched(false)
})

local function trackDownedState(evt,eid,comp){
  foreach(k,v in state)
    v(comp["hitpoints.{0}".subst(k)])
}
::ecs.register_es("downedTracker",{
  onInit = trackDownedState,
  onChange = trackDownedState,
  onDestroy = function(evt,eid,comp) {
    state.downedEndTime(-1.0)
    state.alwaysAllowRevive(false)
    state.canBeRevivedByTeammates(false)
    state.alwaysAllowRevive(false)
  }
},
{
  comps_track = [
    ["hitpoints.downedEndTime",::ecs.TYPE_FLOAT, -1],
    ["hitpoints.canSelfReviveByHealing", ::ecs.TYPE_BOOL, false],
    ["hitpoints.canBeRevivedByTeammates", ::ecs.TYPE_BOOL, false],
    ["hitpoints.alwaysAllowRevive", ::ecs.TYPE_BOOL, false],
  ],
  comps_rq=["watchedByPlr","isDowned"]
})

return state

 