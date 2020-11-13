require ecs
require HumanPhys
require EnlistedHuman

[es (after=(human_phys_es, before_net_phys_sync), before=after_net_phys_sync)]
def human_restore_stamina_in_vehicle_es(info : UpdateStageInfoAct; var human_net_phys : HumanActor; updatable : bool; isInVehicle : bool)
  if !isInVehicle || updatable
    return
  human_phys_restore_stamina(human_net_phys.phys, info.dt, 1f)