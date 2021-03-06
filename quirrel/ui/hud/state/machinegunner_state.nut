local isMachinegunner = persist("isMachinegunner",@() Watched(false))

::ecs.register_es("machinegunner_track_es",
  {
    [["onInit","onChange","onDestroy"]] = @(evt,eid,comp) isMachinegunner(comp["human_attached_gun.isAttached"])
  },
  {comps_track=[["human_attached_gun.isAttached", ::ecs.TYPE_BOOL]]
   comps_rq = ["hero"]})

return isMachinegunner
 