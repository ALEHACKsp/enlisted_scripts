require ecs
require ecs.common
require net
require vehicle
require math
require math.base
require dm
require Dacoll

[es (tag=server)]
def vehicle_underwater_es(info: UpdateStageInfoAct;
                          transform: float3x4;
                          eid: EntityId;
                          drowningHeight: float;
                          var damage_model: DamageModel&;
                          dm_phys_parts_dot_enginePartIds: IntList;
                          underWaterMaxTime: float;
                          var underWaterStartTime: float&;
                          last_driver_leave_time: float)
  var isUnderWater: bool = true
  var hasAliveEngines: bool = true
  let pos: float3 = transform[3] + normalize(transform[1]) * drowningHeight
  let distToLand: float = 5.
  var dp: float3
  if !is_valid_water_height(traceht_water_at_time(pos, distToLand, info.curTime, isUnderWater, dp))
    return
  for partId in dm_phys_parts_dot_enginePartIds
    if int(get_rel_hp_fixed(damage_model.dmData, partId)) == 0
      hasAliveEngines = false
      break
  let lastDriverTime: float = get_vehicle_driver(eid) != INVALID_ENTITY_ID ? info.curTime : last_driver_leave_time
  if lastDriverTime + underWaterMaxTime * 2.f < info.curTime || !isUnderWater || !hasAliveEngines
    underWaterStartTime = -1.f
    return
  if underWaterStartTime < 0.f
    underWaterStartTime = info.curTime
    return
  if info.curTime - underWaterStartTime > underWaterMaxTime
    for partId in dm_phys_parts_dot_enginePartIds
      if int(get_rel_hp_fixed(damage_model.dmData, partId)) != 0
        let hitData: HitData
        let dmgMask = int(DamageEffectsMask DM_EFFECTS_MASK_ALL) & ~(1 << int(DamageEffectType DM_EFFECT_FIRE))
        deal_damage_to_part(damage_model, eid, partId, 0, dmgMask, get_max_hp(damage_model.dmData, partId), hitData)
        underWaterStartTime = 0.0
