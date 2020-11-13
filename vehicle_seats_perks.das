require ecs
require ecs.common
require vehicle
require game.es.turrets_common

struct TurretLoaderPerks
  reloadMult : float = 1.0
  canChangeShellInReload : bool = false

def push_affected_turrets(var vehicle_seats_dot_applyLoaderModsToTurrets : Array;
                          turret_control_dot_turretInfo : Array;
                          turret_names : Array const? const&)
  new_ecs_array() <| $(var arr : Array)
    if turret_names != null
      for turretNameObj in *turret_names
        let turretName = get_string(turretNameObj, "")
        let turretInd = find_turret_index_by_name(turret_control_dot_turretInfo, turretName)
        if turretInd >= 0
          push_back(arr, turretInd)
    push_back(vehicle_seats_dot_applyLoaderModsToTurrets, arr)

def set_default_perk_values(turret_control_dot_gunEids : EidList)
  let defaultPerks = TurretLoaderPerks()
  for gunEid in turret_control_dot_gunEids
    query(gunEid) <| $[es] (var gun_dot_timeBetweenShotMult : float&;
                            var turret_dot_canChangeShellDuringReload : bool&)
      gun_dot_timeBetweenShotMult = defaultPerks.reloadMult
      turret_dot_canChangeShellDuringReload = defaultPerks.canChangeShellInReload

def apply_loader_perks(turret_eid : EntityId; perks : TurretLoaderPerks)
  query(turret_eid) <| $[es] (var gun_dot_timeBetweenShotMult : float&;
                              var turret_dot_canChangeShellDuringReload : bool&)
    gun_dot_timeBetweenShotMult = min(gun_dot_timeBetweenShotMult, perks.reloadMult)
    turret_dot_canChangeShellDuringReload ||= perks.canChangeShellInReload

def get_loader_perks(sitter_eid : EntityId) : TurretLoaderPerks
  var perks = TurretLoaderPerks()
  query(sitter_eid) <| $[es] (entity_mods_dot_vehicleReloadMult : float = 1.0;
                              entity_mods_dot_canChangeShellDuringVehicleGunReload : bool = false)
    perks.reloadMult = entity_mods_dot_vehicleReloadMult
    perks.canChangeShellInReload = entity_mods_dot_canChangeShellDuringVehicleGunReload
  return perks

def apply_sitter_loader_perks(sitter_eid : EntityId;
                              affected_turret_ids : Array const? const;
                              turret_control_dot_gunEids : EidList)
  if affected_turret_ids == null
    return
  for turretIndObj in *affected_turret_ids
    let turretInd = get_int(turretIndObj) ?? -1
    if turretInd >= 0
      apply_loader_perks(turret_control_dot_gunEids[turretInd], get_loader_perks(sitter_eid))

def apply_vehicle_reload_perks(vehicle_seats_owners : VehicleSeatsOwners;
                               vehicle_seats_dot_applyLoaderModsToTurrets : Array;
                               turret_control_dot_gunEids : EidList)
  set_default_perk_values(turret_control_dot_gunEids)
  let owners & = vehicle_seats_owners.data
  for owner, turretIds in owners, vehicle_seats_dot_applyLoaderModsToTurrets
    if owner.eid != ecs::INVALID_ENTITY_ID && (get_bool(owner.eid, "isAlive") ?? true)
      apply_sitter_loader_perks(owner.eid, get_ecs_array(turretIds), turret_control_dot_gunEids)


[es (tag=server, on_event=(EventEntityCreated,EventComponentsAppear))]
def init_turret_loaders(evt : Event;
        [[shared_comp]] turret_control_dot_turretInfo: Array;
        [[shared_comp]] vehicle_seats_dot_seats : Array;
                    var vehicle_seats_dot_applyLoaderModsToTurrets : Array)
  for seatObj in vehicle_seats_dot_seats
    let seat = get_ecs_object(seatObj)
    let turretNames = get_ecs_array(seat, "loaderTurretNames")
    push_affected_turrets(vehicle_seats_dot_applyLoaderModsToTurrets, turret_control_dot_turretInfo, turretNames)

[es (tag=server, track=vehicle_seats_owners)]
def vehicle_apply_sitter_reload_perks(evt : Event;
                                      vehicle_seats_owners : VehicleSeatsOwners;
                                      vehicle_seats_dot_applyLoaderModsToTurrets : Array;
                                      turret_control_dot_gunEids : EidList)
  apply_vehicle_reload_perks(vehicle_seats_owners, vehicle_seats_dot_applyLoaderModsToTurrets, turret_control_dot_gunEids)

[es (tag=server, on_event=EventEntityDied)]
def vehicle_recalculate_perks_on_sitter_death(evt : Event; human_anim_dot_vehicleSelected : EntityId)
  query(human_anim_dot_vehicleSelected) <| $[es] (vehicle_seats_owners : VehicleSeatsOwners;
                                                  vehicle_seats_dot_applyLoaderModsToTurrets : Array;
                                                  turret_control_dot_gunEids : EidList)
    apply_vehicle_reload_perks(vehicle_seats_owners, vehicle_seats_dot_applyLoaderModsToTurrets, turret_control_dot_gunEids)
