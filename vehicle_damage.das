require game.es.events
require game.es.vehicle.vehicle_events
require dm
require vehicle
require ecs

def is_in_array(value: int; arr: ecs::IntList): bool
  for item in arr
    if item == value
      return true
  return false

def process_damage_to_part(partId: int;
                           hpFixed: int;
                           prevHpFixed: int;
                           turret_dm_part_dot_barrelDm: ecs::IntList;
                           turret_dm_part_dot_breechDm: ecs::IntList;
                           turret_drive_dm_part_dot_horDriveDm: ecs::IntList;
                           turret_drive_dm_part_dot_verDriveDm: ecs::IntList;
                           dm_phys_parts_dot_enginePartIds: ecs::IntList;
                           dm_phys_parts_dot_transmissionPartIds: ecs::IntList;
                           dm_phys_parts_dot_tracksPartIds: ecs::IntList;
                           vehicle_seats_owners: VehicleSeatsOwners)
  if partId == -1
    return
  let isDestroyed = hpFixed == 0
  if ((isDestroyed && prevHpFixed == 0) || (hpFixed > MAX_REL_HP_FIXED / 2) ||
      (!isDestroyed && prevHpFixed < MAX_REL_HP_FIXED / 2))
    return

  var msgLocId = ""
  if is_in_array(partId, turret_dm_part_dot_barrelDm) || is_in_array(partId, turret_dm_part_dot_breechDm)
    msgLocId = "turretDamage"
  elif is_in_array(partId, turret_drive_dm_part_dot_horDriveDm)
    msgLocId = "turretHorDriveDamage"
  elif is_in_array(partId, turret_drive_dm_part_dot_verDriveDm)
    msgLocId = "turretVerDriveDamage"
  elif is_in_array(partId, dm_phys_parts_dot_enginePartIds)
    msgLocId = "engineDamage"
  elif is_in_array(partId, dm_phys_parts_dot_transmissionPartIds)
    msgLocId = "transmissionDamage"
  elif is_in_array(partId, dm_phys_parts_dot_tracksPartIds)
    msgLocId = "tracksDamage"

  if msgLocId == ""
    return

  if isDestroyed
    msgLocId = "{msgLocId}Destroyed"
  let owners & = vehicle_seats_owners.data
  for owner in owners
    if owner.isPlayer
      sendEvent(owner.eid, [[CmdHeroLogEvent event="vehicle_part_damaged", text="vehicle/{msgLocId}", ttl=5]])

[es (tag=server, REQUIRE=damage_model)]
def vehicle_volumetric_damage_es(evt: EventOnVolumetricDamage;
                                 turret_dm_part_dot_barrelDm: ecs::IntList;
                                 turret_dm_part_dot_breechDm: ecs::IntList;
                                 turret_drive_dm_part_dot_horDriveDm: ecs::IntList;
                                 turret_drive_dm_part_dot_verDriveDm: ecs::IntList;
                                 dm_phys_parts_dot_enginePartIds: ecs::IntList;
                                 dm_phys_parts_dot_transmissionPartIds: ecs::IntList;
                                 dm_phys_parts_dot_tracksPartIds: ecs::IntList;
                                 vehicle_seats_owners: VehicleSeatsOwners;
                                 fire_damage_dot_isBurn : bool)
  if fire_damage_dot_isBurn
    return
  for partIt in evt.damagedParts
    let part = get_ecs_object(partIt)
    let partId = get_int(part, "partId") ?? -1
    let hpFixed = get_int(part, "hpFixed") ?? 0
    let prevHpFixed = get_int(part, "prevHpFixed") ?? 0
    process_damage_to_part(
      partId, hpFixed, prevHpFixed,
      turret_dm_part_dot_barrelDm,
      turret_dm_part_dot_breechDm,
      turret_drive_dm_part_dot_horDriveDm,
      turret_drive_dm_part_dot_verDriveDm,
      dm_phys_parts_dot_enginePartIds,
      dm_phys_parts_dot_transmissionPartIds,
      dm_phys_parts_dot_tracksPartIds,
      vehicle_seats_owners)

[es (tag=server, REQUIRE=damage_model)]
def vehicle_damage_part_events_es(evt: EventOnPartDamaged;
                                  turret_dm_part_dot_barrelDm: ecs::IntList;
                                  turret_dm_part_dot_breechDm: ecs::IntList;
                                  turret_drive_dm_part_dot_horDriveDm: ecs::IntList;
                                  turret_drive_dm_part_dot_verDriveDm: ecs::IntList;
                                  dm_phys_parts_dot_enginePartIds: ecs::IntList;
                                  dm_phys_parts_dot_transmissionPartIds: ecs::IntList;
                                  dm_phys_parts_dot_tracksPartIds: ecs::IntList;
                                  vehicle_seats_owners: VehicleSeatsOwners;
                                  fire_damage_dot_isBurn: bool)
  if fire_damage_dot_isBurn
    return
  process_damage_to_part(
    evt.partId, int(evt.hpFixed), int(evt.prevHpFixed),
    turret_dm_part_dot_barrelDm,
    turret_dm_part_dot_breechDm,
    turret_drive_dm_part_dot_horDriveDm,
    turret_drive_dm_part_dot_verDriveDm,
    dm_phys_parts_dot_enginePartIds,
    dm_phys_parts_dot_transmissionPartIds,
    dm_phys_parts_dot_tracksPartIds,
    vehicle_seats_owners)
