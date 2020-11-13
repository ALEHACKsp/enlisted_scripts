require ecs
require ecs.common
require dm
require math.base
require game.es.events
require game.es.vehicle.vehicle_events

def find_repair_kit(itemContainer)
  for itemEid in itemContainer
    if has(itemEid, "item.isRepairTool")
      return itemEid
  return INVALID_ENTITY_ID

[private]
def set_repairable_state(inProgress; operatorEid; targetEid; repairTimeMult: float  =1.f; recoveryRatioAdd: float = 0.f)
  query(targetEid) <| $ [es] (var maintainable_dot_operator: EntityId&;
                              var repairable_dot_repairTime: float&;
                              var repairable_dot_repairTotalTime: float&;
                              var repairable_dot_inProgress: bool&;
                              var repairable_dot_recoveryRatio: float&;
                              repairable_dot_baseRepairTotalTime: float;
                              repairable_dot_baseRecoveryRatio: float)
    maintainable_dot_operator = operatorEid
    repairable_dot_inProgress = inProgress
    repairable_dot_recoveryRatio = repairable_dot_baseRecoveryRatio + recoveryRatioAdd
    if repairable_dot_repairTime < 0.f && inProgress
      repairable_dot_repairTotalTime = repairable_dot_baseRepairTotalTime * repairTimeMult
      repairable_dot_repairTime = repairable_dot_repairTotalTime

[private]
def stop_repair(maintenance_dot_target)
  set_repairable_state(false, INVALID_ENTITY_ID, maintenance_dot_target)
  return false

[private]
def use_repair_kit(maintainable_dot_operator)
  ecs::query(maintainable_dot_operator) <| $ [es] (var repair_dot_active: bool&;
                                                   var repair_dot_repairKit: EntityId&;
                                                   var repair_dot_hasRepairKit: bool&;
                                                   var itemContainer: EidList&;
                                                   entity_mods_dot_vehicleRepairUsagesPerKit = -1;
                                                   possessedByPlr = INVALID_ENTITY_ID)
    repair_dot_active = false
    let idx = find_index(itemContainer, repair_dot_repairKit)
    if idx == -1
      return
    var isFullyUsed = false
    ecs::query(repair_dot_repairKit) <| $ [es] (var repair_kit_dot_useCounter: int&)
      isFullyUsed = entity_mods_dot_vehicleRepairUsagesPerKit <= ++repair_kit_dot_useCounter
    sendEvent(maintainable_dot_operator, [[EventOnLootUse itemEid=repair_dot_repairKit]])
    sendEvent(possessedByPlr, [[EventPlayerOnLootUse entityToUse=repair_dot_repairKit]])
    if !isFullyUsed
      return
    destroyEntity(repair_dot_repairKit)
    erase(itemContainer, idx)
    repair_dot_repairKit = find_repair_kit(itemContainer)
    repair_dot_hasRepairKit = !!repair_dot_repairKit

[es]
def repair_kit_owner_init_es(evt: EventEntityCreated;
                             itemContainer: EidList;
                             var repair_dot_hasRepairKit: bool&;
                             var repair_dot_repairKit: EntityId&)
  repair_dot_repairKit = find_repair_kit(itemContainer)
  repair_dot_hasRepairKit = !!repair_dot_repairKit

[es]
def pickup_repair_kit_on_drop_es(evt: EventOnLootDrop;
                                 itemContainer: EidList;
                                 var repair_dot_hasRepairKit: bool&;
                                 var repair_dot_repairKit: ecs::EntityId&)
  if evt.itemEid == repair_dot_repairKit
    repair_dot_repairKit = find_repair_kit(itemContainer)
    repair_dot_hasRepairKit = !!repair_dot_repairKit

[es]
def pickup_repair_kit_on_pickup_es(evt: EventOnLootPickup;
                                   var repair_dot_hasRepairKit: bool&;
                                   var repair_dot_repairKit: ecs::EntityId&)
  if !repair_dot_hasRepairKit && has(evt.itemEid, "item.isRepairTool")
    repair_dot_hasRepairKit = true
    repair_dot_repairKit = evt.itemEid

[es (on_event=(EventEntityCreated, EventComponentChanged), track=item_dot_ownerEid, REQUIRE=item_dot_isRepairTool, tag=server)]
def repair_kit_init_es(evt: Event; eid: EntityId; item_dot_ownerEid: EntityId)
  ecs::query(item_dot_ownerEid) <| $ [es] (var repair_dot_hasRepairKit: bool&; var repair_dot_repairKit: EntityId&)
    repair_dot_hasRepairKit = true
    repair_dot_repairKit = eid

[es (tag=server)]
def need_repair_check_on_part_damaged_es(evt: EventOnPartDamaged; var repairable_dot_repairRequired: bool&)
  if int(evt.hpFixed) == 0
    repairable_dot_repairRequired = true

[es (tag=server)]
def need_repair_check_on_volumetric_damaged_es(evt: EventOnVolumetricDamage; var repairable_dot_repairRequired: bool&)
  for part in evt.damagedParts
    if get_int(get_ecs_object(part), "hpFixed") ?? -1 == 0
      repairable_dot_repairRequired = true
      break

[es (tag=server)]
def need_repair_check_on_meta_part_damage_es(evt: EventOnMetaPartDamage; var repairable_dot_repairRequired: bool&)
  if evt.damage > 0.f
    repairable_dot_repairRequired = true

[es (tag=server)]
def repair_es(evt: CmdStartRepair;
               eid: EntityId;
               var repair_dot_active: bool&;
               entity_mods_dot_vehicleRepairTimeMult: float = 1.f;
               entity_mods_dot_vehicleRepairRecoveryRatioAdd: float = 0.f)
  repair_dot_active = true
  set_repairable_state(true, eid, evt.target, entity_mods_dot_vehicleRepairTimeMult, entity_mods_dot_vehicleRepairRecoveryRatioAdd)

[es]
def repair_stop_es(evt: CmdStopRepair; var repair_dot_active: bool&; maintenance_dot_target: EntityId)
  repair_dot_active = stop_repair(maintenance_dot_target)

[es (tag=server)]
def check_repairing_distance_es(info: UpdateStageInfoAct;
                                maintenance_dot_target: EntityId;
                                var repair_dot_active: bool&;
                                transform: float3x4;
                                repair_dot_effectiveDistance: float)
  if !repair_dot_active
    return
  var targetPosition: float3
  ecs::query(maintenance_dot_target) <| $ [es] (transform: float3x4)
    targetPosition = transform[3]
  if length_sq(targetPosition - transform[3]) > square(repair_dot_effectiveDistance)
    repair_dot_active = stop_repair(maintenance_dot_target)

[es]
def stop_repairing_on_enter_vehicle_es(evt: EventEnterVehicle;
                                       maintenance_dot_target: EntityId;
                                       var maintenance_dot_hasTarget: bool&;
                                       var repair_dot_active: bool&;
                                       isInVehicle = false)
  if !isInVehicle || !repair_dot_active
    return
  repair_dot_active = stop_repair(maintenance_dot_target)
  maintenance_dot_hasTarget = false

[es (tag=server, no_order)]
def repair_external_es(info: UpdateStageInfoAct;
                        eid: EntityId;
                        var damage_model: DamageModel&;
                        var meta_parts_state: MetaPartsState&;
                        var fire_protection: FireProtection&;
                        repairable_dot_recoveryRatio: float;
                        maintainable_dot_operator: EntityId;
                        var repairable_dot_repairTime: float&;
                        var repairable_dot_inProgress: bool&;
                        var repairable_dot_repairRequired: bool&)
  if !maintainable_dot_operator || repairable_dot_repairTime < 0.f
    return
  repairable_dot_repairTime = repairable_dot_repairTime - info.dt
  if repairable_dot_repairTime > 0.f
    return
  repairable_dot_inProgress = false
  repairable_dot_repairRequired = false
  for part in damage_model.dmData.parts
    let partId = get_damage_part_id(part)
    var fire_protection_part& = fire_protection[partId]
    var hp = uint16(0)
    part.relHpFixed = rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(part.relHpFixed) + float(repairable_dot_recoveryRatio))
    part.state = (DamagePartState DP_STATE_DAMAGED)
    if int(part.relHpFixed) > HP_DAMAGED_STATE_TRESHOLD_FIXED
      part.state = (DamagePartState DP_STATE_NORMAL)
    if fire_protection_part.maxHp > 0.f
      hp = rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(fire_protection_part.hpFixed) + float(repairable_dot_recoveryRatio))
    fire_protection_part.hpFixed = hp
    repairable_dot_repairRequired = int(part.relHpFixed) < MAX_REL_HP_FIXED
  for i in range(0, int(get_meta_part_size(meta_parts_state)))
    repair_meta_part(meta_parts_state, i, repairable_dot_recoveryRatio)
    repairable_dot_repairRequired = int(get_meta_part_rel_hp(meta_parts_state, i)) < MAX_REL_HP_FIXED
  use_repair_kit(maintainable_dot_operator)
  sendEvent(maintainable_dot_operator, [[CmdStopRepair target=eid]])
