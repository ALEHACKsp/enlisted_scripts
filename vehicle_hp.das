require ecs
require game.es.vehicle.vehicle_events
require game.es.events
require net
require dm
require vehicle
require player

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_hp_init_es(evt: Event;
                       damage_model: DamageModel;
                       vehicle_dot_hpMetaPart: das_string;
                       var vehicle_dot_hpMetaPartId: int&;
                       var vehicle_dot_hp: float&;
                       var vehicle_dot_maxHp: float&)

  vehicle_dot_hpMetaPartId = damage_model |> find_meta_part_id_by_name(vehicle_dot_hpMetaPart)
  if vehicle_dot_hpMetaPartId >= 0
    vehicle_dot_maxHp = damage_model |> get_meta_part_max_hp(vehicle_dot_hpMetaPartId)
    vehicle_dot_hp = vehicle_dot_maxHp

def process_damage_effects(offender: ecs::EntityId;
                           vehicle: ecs::EntityId;
                           effects: int;
                           vehicle_seats_owners: VehicleSeatsOwners)

  let player = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID
  sendEvent(offender, [[EventOnVehicleDamageEffects offender=player, vehicle=vehicle, effects=effects]])

  let owners & = vehicle_seats_owners.data
  for owner in owners
    let victim = owner.eid
    if victim != offender && owner.isPlayer && victim != INVALID_ENTITY_ID
      sendEvent(victim, [[CmdShowVehicleDamageEffectsHint offender=offender, vehicle=vehicle, effects=effects]])

[es (tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_kill_effect_es(evtData: EventOnPartKillEffects;
                                      eid: ecs::EntityId;
                                      vehicle_seats_owners: VehicleSeatsOwners)

  let effects = evtData.effects
  if effects != 0
    let vehicle = eid
    process_damage_effects(evtData.offender, vehicle, effects, vehicle_seats_owners)

[es (tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_damage_effect_es(evtData: EventOnPartDamageEffects;
                                        eid: ecs::EntityId;
                                        vehicle_seats_owners: VehicleSeatsOwners)

  let effects = evtData.effects
  if effects != 0
    let vehicle = eid
    process_damage_effects(evtData.offender, vehicle, effects, vehicle_seats_owners)

[es (tag=server, REQUIRE = damage_model)]
def vehicle_hp_on_meta_part_damage_es(evtData: EventOnMetaPartDamage;
                                      eid: ecs::EntityId;
                                      vehicle_dot_hp: float;
                                      vehicle_dot_sendMsgDamageThreshold: float)

  if evtData.damage >= vehicle_dot_sendMsgDamageThreshold && vehicle_dot_hp > 0.0
    let offender = evtData.offender
    let offenderPlayer = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID
    sendEvent(offender, [[EventOnVehicleDamaged offender=offenderPlayer, vehicle=eid, damage=evtData.damage, hp=evtData.hp, maxHp=evtData.maxHp]])

[es (tag=server, no_order)]
def vehicle_hp_es(info: ecs::UpdateStageInfoAct;
                  damage_model: DamageModel;
                  meta_parts_state: MetaPartsState;
                  vehicle_dot_hpMetaPartId: int;
                  var vehicle_dot_hp: float&)

  if vehicle_dot_hpMetaPartId < 0
    return

  let relHp = meta_parts_state |> get_meta_part_rel_hp(vehicle_dot_hpMetaPartId)
  let maxHp = damage_model |> get_meta_part_max_hp(vehicle_dot_hpMetaPartId)

  vehicle_dot_hp = relHp * maxHp

[es (tag=server, track=isExploded)]
def vehicle_on_explosion_es(evt: Event;
                            eid: ecs::EntityId;
                            vehicle_dot_hp: float;
                            vehicle_dot_maxHp: float;
                            isExploded: bool;
                            lastOffender: EntityId)
  if isExploded && lastOffender != INVALID_ENTITY_ID
    let player = get_Eid(lastOffender, "possessedByPlr") ?? INVALID_ENTITY_ID
    sendEvent(lastOffender, [[EventOnVehicleDamaged offender=player, vehicle=eid, damage=vehicle_dot_maxHp, hp=vehicle_dot_hp, maxHp=vehicle_dot_maxHp]])
