require game.es.events
require game.es.vehicle.vehicle_events
require dm
require vehicle
require ecs

[es (tag=server, REQUIRE=damage_model)]
def vehicle_fatal_fire_kill_es(evtData: EventFireFatal;
                               vehicle_seats_owners: VehicleSeatsOwners)
  let owners & = vehicle_seats_owners.data
  for owner in owners
    sendEvent(owner.eid, [[CmdKill offender=evtData.offender, damageType=uint16(int(DamageType DM_FIRE))]])

[es (tag=server)]
def vehicle_crew_dead_es(evtData: EventEntityDied; eid : EntityId; human_anim_dot_vehicleSelected: EntityId)
  var crewOwner = eid
  ecs::query(human_anim_dot_vehicleSelected) <| $ [es](eid : EntityId;
                                                       vehicle_seats_owners : VehicleSeatsOwners;
                                                       var isAlive : bool&;
                                                       var lastOffender : EntityId&;
                                                       fire_damage_dot_isFatal : bool= false)
    if fire_damage_dot_isFatal
      return
    var hasCrew = false
    let owners & = vehicle_seats_owners.data
    for owner in owners
      if owner.eid != crewOwner && owner.eid != ecs::INVALID_ENTITY_ID && (get_bool(owner.eid, "isAlive") ?? false)
        hasCrew = true
    if !hasCrew
      let isSuicide = evtData.victim == evtData.offender
      let hasLastOffender = !!lastOffender
      lastOffender = isSuicide && hasLastOffender ? lastOffender : evtData.offender
      if has(eid, "destroyIfNoCrewLeft")
        sendEvent(eid, [[EventExplosionFatal offender=lastOffender]])
      if has(eid, "deadIfNoCrewLeft")
        isAlive = false

[es (tag=server, track=vehicle_seats_owners)]
def vehicle_seats_dm_parts_es(evt:Event;
                         vehicle_seats_owners: VehicleSeatsOwners;
                         vehicle_seats_receive_damage_from_dm_part : ecs::IntList;
                         var damage_model: DamageModel)
  let owners & = vehicle_seats_owners.data
  for seatNo in iter_range(vehicle_seats_receive_damage_from_dm_part)
    let owner : auto const& = owners[seatNo]
    if vehicle_seats_receive_damage_from_dm_part[seatNo] >= 0
      let enabled = (owner.eid != ecs::INVALID_ENTITY_ID) || (get_bool(owner.eid, "isAlive") ?? false)
      damage_model.dmData |> enable_dm_part(vehicle_seats_receive_damage_from_dm_part[seatNo], enabled)