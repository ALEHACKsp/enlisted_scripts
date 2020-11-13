require ecs
require game.es.events
require ecs.common
require vehicle
require player
require math
require math.base
require dm
require level

[es (tag=server)]
def add_userstats_es(evt:CmdAddUserstats; var userstats : Object)
  set(userstats, evt.name, (get_int(userstats, evt.name) ?? 0) + evt.change)

[es (tag=server)]
def add_regionstats_es(evt:CmdAddRegionstats; var regionstats : Object)
  if !has(regionstats, evt.region)
    push_object_to_object(regionstats, evt.region)  <| $ (var obj : ecs::Object)
      set(obj, evt.name, evt.change)
  else
    var region = getRW_ecs_object(regionstats, evt.region)
    set(*region, evt.name, get_int(*region , evt.name) ?? 0 + 1)


[es (tag=server)]
def track_pickup_stats(evt : EventOnLootPickup; possessedByPlr : ecs::EntityId)
  if possessedByPlr != INVALID_ENTITY_ID
    query(evt.itemEid) <| $ [es] (item_dot_userstarts_dot_pickupName : string)
      sendEvent(possessedByPlr, [[CmdAddUserstats name = item_dot_userstarts_dot_pickupName, change = 1]])

[es (tag=server, no_order)]
def track_vehicle_travel_es(info : ecs::UpdateStageInfoAct;
                            vehicle_seats_owners: VehicleSeatsOwners;
                            transform : float3x4;
                            var lastStatPos : float3&;
                            vehicleType, vehicleName : string;
                            vehicleThresholdDist : float = 10.f)
  let distSq = length_sq(transform[3] - lastStatPos);
  if (distSq < square(vehicleThresholdDist))
    return;
  let dist = int(sqrt(distSq))
  lastStatPos = transform[3]

  let typeTraveledStat = "traveled_in_{vehicleType}"
  let carTraveledStat = "traveled_in_{vehicleName}"

  let owners & = vehicle_seats_owners.data
  for owner in owners
    if owner.eid != INVALID_ENTITY_ID
      let playerEid = get_Eid(owner.eid, "possessedByPlr") ?? INVALID_ENTITY_ID
      sendEvent(playerEid, [[CmdAddUserstats name = typeTraveledStat, change = dist]])
      sendEvent(playerEid, [[CmdAddUserstats name = carTraveledStat, change = dist]])
      sendEvent(playerEid, [[CmdAddUserstats name = "traveled_in_vehicle", change = dist]])


[es (tag=server, REQUIRE=userstats, REQUIRE=regionstats)]
def track_player_hits_es(evt: EventOnEntityHit; eid, possessed : ecs::EntityId)
  if (evt.offender != possessed) || (evt.damageDesc.damageType != DamageType DM_PROJECTILE)
    return
  if(get_Eid(evt.victim, "possessedByPlr") ?? INVALID_ENTITY_ID == INVALID_ENTITY_ID)
    return

  sendEvent(eid, [[CmdAddUserstats name = "hits", change = 1]])
  let statName = get_gun_stat_type_by_props_id(int (evt.damageDesc.gunPropsId))
  if statName == ""
    return
  sendEvent(eid, [[CmdAddUserstats name = "{statName}_hits", change = 1]])

  let hit = evt.damageDesc.hitPos
  let hitXZ = float2(hit.x, hit.z)
  let region = get_region_name_by_pos(hitXZ)
  if region != ""
    sendEvent(eid, [[CmdAddRegionstats region = region, name = "hits", change = 1]])
    sendEvent(eid, [[CmdAddRegionstats region = region, name = "{statName}_hits", change = 1]])

