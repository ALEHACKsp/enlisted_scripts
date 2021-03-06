local canChangeCockpitView = ::Watched(false)

::ecs.register_es("cockpit_ui_es", {
  onInit    = @(evt, eid, comp) canChangeCockpitView(comp["cockpit.slitNodes"].len() > 1)
  onChange  = @(evt, eid, comp) canChangeCockpitView(comp["cockpit.slitNodes"].len() > 1)
  onDestroy = @(evt, eid, comp) canChangeCockpitView(false)
},
{
  comps_track = [
    ["cockpit.slitNodes", ::ecs.TYPE_INT_LIST],
    ["cockpit.isAttached", ::ecs.TYPE_BOOL],
  ]
},
{ after = "vehicle_cockpit_slits_init" })

return {
  canChangeCockpitView = canChangeCockpitView
} 