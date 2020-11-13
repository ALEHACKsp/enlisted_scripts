require ecs
require Dacoll

[es (REQUIRE=destroyUnderwater, tag=server, no_order)]
def destroy_underwater(info: UpdateStageInfoAct;
                       eid: EntityId;
                       transform: float3x4;
                       var destroy_underwater_dot_nextCheckTime: float&;
                       destroy_underwater_dot_checkPeriod: float = 1.f)
  if info.curTime < destroy_underwater_dot_nextCheckTime
    return
  destroy_underwater_dot_nextCheckTime = info.curTime + destroy_underwater_dot_checkPeriod
  var isUnderwater = false
  traceht_water_at_time(transform[3], 5.0, info.curTime, isUnderwater)
  if isUnderwater
    destroyEntity(eid);
